defmodule Diffo.Access.Card do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Card - Card Resource Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Specification
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Feature
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias Diffo.Access
  alias Diffo.Provider.Assigner
  alias Diffo.Provider.Assignment

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a Card"
    plural_name :Cards
  end

  specification do
    id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
    name "card"
    type :resourceSpecification
    description "A Card Resource Instance"
    category "Network Resource"
  end

  characteristics do
    characteristic :card, Diffo.Access.CardValue
    characteristic :ports, Diffo.Provider.AssignableValue
  end

  actions do
    create :build do
      description "creates a new Card resource instance for build"
      accept [:id, :name, :type, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context ->
               changeset
               |> Specification.set_specified_by_argument()
               |> Feature.set_features_argument()
               |> Characteristic.set_characteristics_argument()
             end)

      change after_action(fn changeset, result, _context ->
               with {:ok, with_specification} <- Specification.relate_instance(result, changeset),
                    {:ok, with_relationships} <-
                      Relationship.relate_instance(with_specification, changeset),
                    {:ok, with_features} <-
                      Feature.relate_instance(with_relationships, changeset),
                    {:ok, with_characteristics} <-
                      Characteristic.relate_instance(with_features, changeset),
                    {:ok, with_places} <- Place.relate_instance(with_characteristics, changeset),
                    {:ok, _with_parties} <- Party.relate_instance(with_places, changeset),
                    {:ok, card} <- Access.get_card_by_id(result.id),
                    do: {:ok, card}
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the card"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, _result} <- Characteristic.update_values(result, changeset),
                    {:ok, card} <- Access.get_card_by_id(result.id),
                    do: {:ok, card}
             end)
    end

    update :relate do
      description "relates the card with other instances"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, _card} <- Relationship.relate_instance(result, changeset),
                    {:ok, card} <- Access.get_card_by_id(result.id),
                    do: {:ok, card}
             end)
    end

    update :assign_port do
      description "relates the card with an instance by assigning a port"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change after_action(fn changeset, result, _context ->
               with {:ok, _card} <- Assigner.assign(result, changeset, :ports, :port),
                    {:ok, card} <- Access.get_card_by_id(result.id),
                    do: {:ok, card}
             end)
    end
  end
end
