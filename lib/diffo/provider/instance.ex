defmodule Diffo.Provider.Instance do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Instance - Ash Resource for a TMF Service or Resource Instance
  """
  use Ash.Resource, otp_app: :diffo, domain: Diffo.Provider, data_layer: AshPostgres.DataLayer, extensions: [AshOutstanding.Resource, AshJason.Resource, AshStateMachine]

  postgres do
    table "instances"
    repo Diffo.Repo
  end

  outstanding do
    expect [:specification, :type, :service_state, :service_operating_status]
    #expect [:type, :name, :external_identifiers, :specification, :service_state, :service_operating_status, :forward_relationships, :reverse_relationships, :features, :characteristics, :entities, :process_statuses, :places, :parties]
    customize fn outstanding, expected, actual ->
      if (actual == nil) do
        outstanding
      else
        outstanding_twin_id = Outstanding.outstanding(expected.twin_id, actual.id)
        case {outstanding, outstanding_twin_id} do
          {_, nil} ->
            outstanding
          {nil, _} ->
            struct(:instance, %{id: outstanding_twin_id})
          {_, _} ->
            outstanding
            |> Map.put(:id, outstanding_twin_id)
        end
      end
      |> Diffo.Provider.Outstanding.instance_list_by_key(expected, actual, :places, :role)
      |> Diffo.Provider.Outstanding.instance_list_by_key(expected, actual, :parties, :role)
    end
  end

  state_machine do
    initial_states [:initial]
    default_initial_state :initial
    state_attribute :service_state
    #deprecated_states [:designed]

    transitions do
      transition(action: :cancel, from: [:initial, :feasibilityChecked, :reserved], to: :cancelled)
      transition(action: :feasibilityCheck, from: :initial, to: :feasibilityChecked)
      transition(action: :reserve, from: [:initial, :feasibilityChecked], to: :reserved)
      transition(action: :deactivate, from: [:active, :reserved], to: [:inactive])
      transition(action: :activate, from: [:initial, :feasibilityChecked, :reserved, :inactive, :suspended, :terminated], to: :active)
      transition(action: :suspend, from: :active, to: :suspended)
      transition(action: :terminate, from: [:active, :inactive, :suspended], to: :terminated)
    end
  end

  jason do
    pick [:id, :href, :name, :external_identifiers, :specification, :process_statuses, :forward_relationships, :features, :characteristics, :entities, :places, :parties, :type]
    customize fn result, record ->
      result
      #|> IO.inspect(label: "start instance jason customize")
      |> Diffo.Util.set(:category, record.specification.category)
      |> Diffo.Util.set(:description, record.specification.description)
      |> Diffo.Util.suppress_rename(:external_identifiers, :externalIdentifier)
      |> Diffo.Provider.Instance.dates(record)
      |> Diffo.Provider.Instance.states(record)
      |> Diffo.Provider.Instance.relationships()
      |> Diffo.Util.rename(:specification, record.specification.type)
      |> Diffo.Util.suppress_rename(:process_statuses, :processStatus)
      |> Diffo.Util.suppress_rename(:features, Diffo.Provider.Instance.derive_feature_list_name(record.type))
      |> Diffo.Util.suppress_rename(:characteristics, Diffo.Provider.Instance.derive_characteristic_list_name(record.type))
      |> Diffo.Util.suppress_rename(:entities, :relatedEntity)
      |> Diffo.Util.suppress_rename(:places, :place)
      |> Diffo.Util.suppress_rename(:parties, :relatedParty)
    end

    order [:id, :href, :category, :description, :name, :externalIdentifier,
      :serviceSpecification, :resourceSpecification,
      :serviceDate, :startDate, :startOperatingDate, :endDate, :endOperatingDate,
      :state, :operatingStatus, :administrativeState, :operationalState, :resourceStatus, :usageState,
      :processStatus,
      :serviceRelationship, :resourceRelationship,
      :supportingService, :supportingResource,
      :feature, :activationFeature,
      :serviceCharacteristic, :resourceCharacteristic,
      :relatedEntity, :place, :relatedParty
    ]
  end

  code_interface do
    define :read
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "creates a new instance of a service or resource according by specification id"
      accept [:id, :specification_id, :name, :type, :which]
      manage_relationship(:specification, type: :append_and_remove)
      change load [:href, :external_identifiers, :specification]
    end

    read :list do
      description "lists all service and resource instances"
    end

    read :find_by_name do
      description "finds service and resource instances by name"
      get? false
      argument :query, :ci_string do
        description "Return only instances with names including the given value."
      end
      filter expr(contains(name, ^arg(:query)))
    end

    read :find_by_specification_id do
      description "list service or resource instances by specification id"
      get? false
      argument :query, :string do
        description "Return only instances specified by the given specification id."
      end
      prepare build(sort: [name: :asc])
      filter expr(specification_id == ^arg(:query))
    end

    update :twin do
      description "establishes a twin relationship"
      require_atomic? false
      accept [:twin_id]
      validate attribute_equals(:which, :expected)
      validate {Diffo.Validations.IsRelatedDifferent, attribute: :which, related_id: :twin_id}
    end

    update :name do
      description "updates the name"
      require_atomic? false
      accept [:name]
    end

    update :specify do
      description "specifies the instance by specification id"
      require_atomic? false
      accept [:specification_id]
      # todo validate that the new specification has same name (will have different major version)
    end

    update :cancel do
      description "cancels a service instance"
      require_atomic? false
      validate attribute_equals(:type, :service)
      change transition_state(:cancelled)
      change set_attribute :service_operating_status, :unknown
      change set_attribute :stopped_at, &DateTime.utc_now/0
    end

    update :feasibilityCheck do
      description "feasibilityChecks a service instance"
      require_atomic? false
      validate attribute_equals(:type, :service)
      change transition_state(:feasibilityCheck)
      change set_attribute :service_operating_status, :pending
    end

    update :reserve do
      description "reserves a service instance"
      require_atomic? false
      validate attribute_equals(:type, :service)
      change transition_state :reserved
      change set_attribute :service_operating_status, :pending
    end

    update :deactivate do
      description "deactivates a service instance"
      require_atomic? false
      validate attribute_equals(:type, :service)
      change transition_state(:inactive)
      change set_attribute :service_operating_status, :configured
    end

    update :activate do
      description "activates a service instance"
      require_atomic? false
      validate attribute_equals(:type, :service)
      change transition_state :active
      change set_attribute :service_operating_status, :starting
      change set_attribute :started_at, &DateTime.utc_now/0
    end

    update :suspend do
      description "suspends a service instance"
      require_atomic? false
      validate attribute_equals(:type, :service)
      change transition_state :suspended
      change set_attribute :service_operating_status, :limited
    end

    update :terminate do
      description "terminates a service instance"
      require_atomic? false
      validate attribute_equals(:type, :service)
      change transition_state(:terminated)
      change set_attribute :service_operating_status, :stopping
      change set_attribute :stopped_at, &DateTime.utc_now/0
    end

    update :status do
      description "updates the status of an instance"
      require_atomic? false
      validate attribute_equals(:type, :service)
      accept [:service_operating_status]
    end
  end

  attributes do
    attribute :id, :uuid do
      description "a uuid4, unique to this instance, generated by default"
      primary_key? true
      allow_nil? false
      public? true
      default &Diffo.Uuid.uuid4/0
    end

    attribute :which, :atom do
      description "which twin this instance is, either expected or actual"
      allow_nil? false
      default :actual
      public? true
      constraints one_of: [:expected, :actual]
    end

    attribute :expected_id_from_twin, :boolean do
      description "whether the id should come from the twin"
      default :false
      public? true
    end

    attribute :type, :atom do
      description "the type of the instance, either service or resource"
      allow_nil? false
      default :service
      public? true
      constraints one_of: [:service, :resource]
    end

    attribute :name, :string do
      description "the name of this service or resource instance"
      allow_nil? true
      public? true
      constraints match: ~r/^[a-zA-Z0-9\s._-]+$/
    end

    attribute :service_operating_status, :atom do
      description "the service operating status, if this instance is a service"
      allow_nil? true
      public? true
      default Diffo.Provider.Service.default_service_operating_status
      constraints one_of: Diffo.Provider.Service.service_operating_statuses
    end

    create_timestamp :inserted_at

    update_timestamp :updated_at

    attribute :started_at, :utc_datetime_usec do
      allow_nil? true
    end

    attribute :stopped_at, :utc_datetime_usec do
      allow_nil? true
    end
  end

  relationships do
    belongs_to :twin, Diffo.Provider.Instance do
      description "the instance's twin"
      destination_attribute :id
      public? true
    end

    has_many :external_identifiers, Diffo.Provider.ExternalIdentifier do
      description "the instance's list of external identifiers"
      public? true
    end

    belongs_to :specification, Diffo.Provider.Specification do
      description "the specification which specifies this instance"
      allow_nil? false
      public? true
      attribute_writable? true
    end

    has_many :process_statuses, Diffo.Provider.ProcessStatus do
      description "the instance's process status collection"
      public? true
    end

    has_many :forward_relationships, Diffo.Provider.Relationship do
      description "the instance's outgoing relationships to other instances"
      destination_attribute :source_id
    end

    has_many :reverse_relationships, Diffo.Provider.Relationship do
      description "the instance's incoming relationships from other instances"
      destination_attribute :target_id
    end

    has_many :features, Diffo.Provider.Feature do
      description "the instance's collection of features"
      public? true
    end

    has_many :characteristics, Diffo.Provider.Characteristic do
      description "the instance's collection of characteristics"
      public? true
    end

    has_many :entities, Diffo.Provider.EntityRef do
      description "the instance's collection of related entities"
      public? true
    end

    has_many :places, Diffo.Provider.PlaceRef do
      description "the instance's collection of related places"
      public? true
    end

    has_many :parties, Diffo.Provider.PartyRef do
      description "the instance's collection of related parties"
      public? true
    end
  end

  validations do
   #  do
   #   message "the instance's twin must have a different which"
   # end
  end

  calculations do
    calculate :href, :string, expr(type <> "InventoryManagement/v" <> specification.tmf_version <> "/" <> type <> "/" <> specification.name <> "/" <> id) do
      description "the inventory href of the service or resource instance"
    end
  end

  preparations do
    prepare build(load: [:twin, :external_identifiers, :specification, :href, :specification, :process_statuses, :forward_relationships, :features, :characteristics, :entities, :places, :parties], sort: [href: :asc])
  end

  @doc """
  Assists in encoding instance dates
  """
  def dates(result, record) do
    result
    |> Diffo.Util.set(Diffo.Provider.Instance.derive_create_name(record.type), Diffo.Util.to_iso8601(record.inserted_at))
    |> Diffo.Util.set(Diffo.Provider.Instance.derive_start_name(record.type), Diffo.Util.to_iso8601(record.started_at))
    |> Diffo.Util.set(Diffo.Provider.Instance.derive_end_name(record.type), Diffo.Util.to_iso8601(record.stopped_at))
  end

  @doc """
  Assists in encoding instance states
  """
  def states(result, record) do
    case record.type do
      :service ->
        result
        |> Diffo.Util.set(:state, record.service_state)
        |> Diffo.Util.set(:operatingStatus, record.service_operating_status)
      :resource ->
        result
        #|> Diffo.Util.ensure_not_nil(:administrativeState, record.resource_administrative_state)
        #|> Diffo.Util.ensure_not_nil(:operationalState, record.resource_operational_state)
        #|> Diffo.Util.ensure_not_nil(:resourceStatus, record.resource_status)
        #|> Diffo.Util.ensure_not_nil(:usageState, record.resource_usage_state)
    end
  end

  @doc """
  Assists in encoding instance-instance relationships
  """
  def relationships(result) do
    relationships = Diffo.Util.get(result, :forward_relationships)
    service_relationships = relationships |> Enum.filter(fn relationship -> relationship.target_type == :service end)
    resource_relationships = relationships |> Enum.filter(fn relationship -> relationship.target_type == :resource end)
    supporting_services =
      service_relationships
      |> Enum.filter(fn relationship -> relationship.alias != nil end)
      |> Enum.into([], fn aliased -> Diffo.Provider.Reference.reference(aliased, :target_href) end)
    supporting_resources =
      resource_relationships
      |> Enum.filter(fn relationship -> relationship.alias != nil end)
      |> Enum.into([], fn aliased -> Diffo.Provider.Reference.reference(aliased, :target_href) end)
    result
      |> Diffo.Util.remove(:forward_relationships)
      |> Diffo.Util.remove(:reverse_relationships)
      |> Diffo.Util.set(:serviceRelationship, service_relationships)
      |> Diffo.Util.set(:resourceRelationship, resource_relationships)
      |> Diffo.Util.set(:supportingService, supporting_services)
      |> Diffo.Util.set(:supportingResource, supporting_resources)
  end

  @doc """
  Derives the type prefix from the specification type
  ## Examples
    iex> Diffo.Provider.Instance.derive_type(:serviceSpecification)
    :service

    iex> Diffo.Provider.Instance.derive_type(:resourceSpecification)
    :resource

  """
  def derive_type(specification_type) do
    case specification_type do
      :serviceSpecification -> :service
      :resourceSpecification -> :resource
    end
  end

  @doc """
  Derives the instance feature list name from the instance type
  ## Examples
    iex> Diffo.Provider.Instance.derive_feature_list_name(:service)
    :feature

    iex> Diffo.Provider.Instance.derive_feature_list_name(:resource)
    :activationFeature

  """
  def derive_feature_list_name(type) do
    case type do
      :service -> :feature
      :resource -> :activationFeature
    end
  end

  @doc """
  Derives the instance characteristic list name from the instance type
  ## Examples
    iex> Diffo.Provider.Instance.derive_characteristic_list_name(:service)
    :serviceCharacteristic

    iex> Diffo.Provider.Instance.derive_characteristic_list_name(:resource)
    :resourceCharacteristic

  """
  def derive_characteristic_list_name(type) do
    case type do
      :service -> :serviceCharacteristic
      :resource -> :resourceCharacteristic
    end
  end

  @doc """
  Derives the instance create date from the instance type
  ## Examples
    iex> Diffo.Provider.Instance.derive_create_name(:service)
    :serviceDate

    iex> Diffo.Provider.Instance.derive_create_name(:resource)
    nil

  """

  def derive_create_name(type) do
    case type do
      :service -> :serviceDate
      :resource -> nil
    end
  end

  @doc """
  Derives the instance start date from the instance type
  ## Examples
    iex> Diffo.Provider.Instance.derive_start_name(:service)
    :startDate

    iex> Diffo.Provider.Instance.derive_start_name(:resource)
    :startOperatingDate

  """

  def derive_start_name(type) do
    case type do
      :service -> :startDate
      :resource -> :startOperatingDate
    end
  end

  @doc """
  Derives the instance end date from the instance type
  ## Examples
    iex> Diffo.Provider.Instance.derive_end_name(:service)
    :endDate

    iex> Diffo.Provider.Instance.derive_end_name(:resource)
    :endOperatingDate

  """

  def derive_end_name(type) do
    case type do
      :service -> :endDate
      :resource -> :endOperatingDate
    end
  end

  @doc """
  Given which returns the other which
  ## Examples
    iex> Diffo.Provider.Instance.other(:actual)
    :expected

    iex> Diffo.Provider.Instance.other(:expected)
    :actual

  """

  def other(which) do
    case which do
      :actual -> :expected
      :expected -> :actual
    end
  end
end
