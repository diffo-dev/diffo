defmodule Diffo.Access.DslAccess.Instance do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  DslAccess.Instance - DSL Access Service Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Specification
  alias Diffo.Provider.Instance.Feature
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Party
  alias Diffo.Provider.Instance.Place
  alias Diffo.Access

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a DSL Access Service"
    plural_name :DslAccesses
  end

  specification do
    id "da9b207a-26c3-451d-8abd-0640c6349979"
    name "dslAccess"
    description "A DSL Access Network Service connecting a subscriber premises to an NNI"
    category "Network Service"
  end

  features do
    feature :dynamic_line_management do
      is_enabled? true
      characteristic :constraints, Diffo.Access.Constraints
    end
  end

  characteristics do
    characteristic :dslam, Diffo.Access.Dslam
    characteristic :aggregate_interface, Diffo.Access.AggregateInterface
    characteristic :circuit, Diffo.Access.Circuit
    characteristic :line, Diffo.Access.Line
  end

  state_machine do
    transitions do
      transition action: :qualify_result, from: :initial, to: :feasibilityChecked
      transition action: :design_result, from: [:initial, :feasibilityChecked], to: :reserved
    end
  end

  actions do
    create :qualify do
      description "creates a new DSL Access service instance for qualification"
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
                    {:ok, dsl_access} <- Access.get_dsl_by_id(result.id),
                    do: {:ok, dsl_access}
             end)

      change load [:href]
      upsert? false
    end

    update :qualify_result do
      description "updates the DSL Access service with qualification result"
      accept [:service_operating_status]
      argument :places, {:array, :struct}
      require_atomic? false

      change transition_state(:feasibilityChecked)

      validate argument_in(:service_operating_status, [
                 nil,
                 :initial,
                 :pending,
                 :unknown,
                 :feasible,
                 :not_feasible
               ])

      change after_action(fn changeset, result, _context ->
               with {:ok, _with_place} <- Place.relate_instance(result, changeset),
                    {:ok, dsl_access} <- Access.get_dsl_by_id(result.id),
                    do: {:ok, dsl_access}
             end)
    end

    update :design_result do
      description "updates the DSL Access service with the design"
      argument :characteristic_value_updates, :term

      change transition_state(:reserved)

      change after_action(fn changeset, result, _context ->
               with {:ok, _dslam} <- Characteristic.update_values(result, changeset),
                    {:ok, dsl_access} <- Access.get_dsl_by_id(result.id),
                    do: {:ok, dsl_access}
             end)
    end
  end
end
