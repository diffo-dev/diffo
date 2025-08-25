defmodule Diffo.Access.Card do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Card - Card Resource Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Specification
  alias Diffo.Provider.Instance.Feature
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Party
  alias Diffo.Provider.Instance.Place
  alias Diffo.Access
  alias Diffo.Access.Assignment
  alias Diffo.Access.PortsValue

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a Card"
    plural_name :Cards
  end

  specification do
    id "ca29956f-6c68-44cc-bf54-705eb8d2f754"
    name "card"
    type :resourceSpecification
    description "A Card Resource Instance"
    category "Network Resource"
  end

  characteristics do
    characteristic :card, Diffo.Access.CardValue
    characteristic :ports, Diffo.Access.PortsValue
  end

  actions do
    create :build do
      description "creates a new Card resource instance for build"
      accept [:id, :name, :type, :which]
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}
      argument :specified_by, :uuid, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :features, {:array, :uuid}, public?: false

      change before_action(fn changeset, _context ->
               changeset
               |> Specification.set_specified_by_argument()
               |> Feature.set_features_argument()
               |> Characteristic.set_characteristics_argument()
             end)

      change after_action(fn changeset, result, _context ->
               with {:ok, with_specification} <- Specification.relate_instance(result, changeset),
                    {:ok, with_features} <-
                      Feature.relate_instance(with_specification, changeset),
                    {:ok, with_characteristics} <-
                      Characteristic.relate_instance(with_features, changeset),
                    {:ok, with_parties} <- Party.relate_instance(with_characteristics, changeset),
                    {:ok, _with_places} <- Place.relate_instance(with_parties, changeset),
                    {:ok, card} <- Access.get_card_by_id(result.id),
                    do: {:ok, card}
             end)

      change load [:href]
      upsert? false
    end

    update :assign_port do
      description "relates the card with instances using ports"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change after_action(fn changeset, result, _context ->
               with {:ok, _card} <- assign_port(result, changeset),
                    {:ok, card} <- Access.get_card_by_id(result.id),
                    do: {:ok, card}
             end)
    end
  end

  defp assign_port(changeset, result) when is_struct(changeset) and is_struct(result) do
    assignment = Map.get(changeset.data, :assignment)
    target_id = Map.get(assignment, :instance_id)
    case Map.get(assignment, :operation, :auto_assign) do
      :auto_assign ->
        case PortsValue.next(result) do
          {:ok, assigned} ->
            relate_is_assigned(result, assigned, target_id)
          {:error, error} ->
            {:error, error}
        end
      :assign ->
        case PortsValue.assignable?(result, assignment.id) do
          true ->
            relate_is_assigned(result, assignment.id, target_id)
          false ->
            {:error, "port #{assignment.id} is not assignable" }
        end
      :unassign ->
        unrelate_is_assigned(result, assignment.id, target_id)
    end
  end

  defp relate_is_assigned(result, value, target_id) when is_struct(result) and is_integer(value) and is_bitstring(target_id) do
    case Diffo.Provider.create_characteristic(%{name: :port, value: value, type: :relationship}) do
      {:ok, characteristic} ->
        case Diffo.Provider.create_relationship(%{type: :assigned_to, source_id: result.id, target_id: target_id,
            characteristics: [characteristic.id]}) do
          {:ok, _relationship} ->
            # we haven't refreshed the result there will be a new forward_relationship
            {:ok, result}
          {:error, error} ->
            {:error, error}
        end
      {:error, error} ->
        {:error, error}
    end
  end

  defp unrelate_is_assigned(result, value, target_id) when is_struct(result) and is_integer(value) and is_bitstring(target_id) do
    # destroy characteristic
    # destroy relationship
    {:error, "not implemented"}
  end
end
