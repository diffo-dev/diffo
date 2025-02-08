defmodule Diffo.Provider.Instance do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Instance - Ash Resource for a TMF Service or Resource Instance
  """
  use Ash.Resource, otp_app: :diffo, domain: Diffo.Provider, data_layer: AshPostgres.DataLayer, extensions: [AshJason.Resource, AshStateMachine]

  postgres do
    table "instances"
    repo Diffo.Repo
  end

  state_machine do
    initial_states [:initial]
    default_initial_state :initial
    state_attribute :service_state

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
    pick [:id, :href, :category, :description, :name, :specification, :forward_relationships, :feature, :characteristic, :place, :party, :type]
    customize fn result, record ->
      opts = [lazy?: true]
      loaded_record =
        record
        |> Ash.load!([:href, :characteristic, :feature, :forward_relationships, :place, :party], opts)
        |> Ash.load!([specification: [:href, :version]], opts)
        |> Ash.load!([feature: [:featureCharacteristic]], opts)
        |> Ash.load!([forward_relationships: [:target_type, :target_href, :characteristic]], opts)

      type = Map.get(loaded_record, :type)
      specification = loaded_record.specification
      start_name = Diffo.Provider.Instance.derive_start_name(type)
      end_name = Diffo.Provider.Instance.derive_end_name(type)
      relationships = loaded_record.forward_relationships
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
      features = Map.get(loaded_record, :feature)
      features_name = Diffo.Provider.Instance.derive_feature_collection_name(type)
      characteristics = loaded_record.characteristic
      characteristics_name = Diffo.Provider.Instance.derive_characteristic_collection_name(type)
      result =
        result
        |> Map.put(:href, loaded_record.href)
        |> Diffo.Util.ensure_not_nil(:category, specification.category)
        |> Diffo.Util.ensure_not_nil(:description, specification.description)
        |> Map.put(specification.type, specification)
        |> Diffo.Provider.Instance.dates(loaded_record)
        |> Diffo.Provider.Instance.states(loaded_record)
        |> Map.drop([:forward_relationships, :reverse_relationships])
        |> Diffo.Util.put_not_empty(:serviceRelationship, service_relationships)
        |> Diffo.Util.put_not_empty(:resourceRelationship, resource_relationships)
        |> Diffo.Util.put_not_empty(:supportingService, supporting_services)
        |> Diffo.Util.put_not_empty(:supportingResource, supporting_resources)
        |> Map.drop([:feature, :place])
        |> Diffo.Util.put_not_empty(features_name, features)
        |> Diffo.Util.put_not_empty(characteristics_name, characteristics)
        |> Diffo.Util.put_not_empty(:relatedParty, loaded_record.party)
        |> Diffo.Util.put_not_empty(:place, loaded_record.place)
    end
    order [:id, :href, :category, :description, :name,
      :serviceDate, :startDate, :startOperatingDate, :endDate, :endOperatingDate,
      :state, :operatingStatus, :administrativeState, :operationalState, :resourceStatus, :usageState,
      :serviceSpecification, :resourceSpecification,
      :serviceRelationship, :resourceRelationship,
      :supportingService, :supportingResource,
      :feature, :activationFeature,
      :serviceCharacteristic, :resourceCharacteristic,
      :place, :relatedParty
    ]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "creates a new instance of a service or resource according by specification id"
      accept [:specification_id, :name, :type]
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
    uuid_primary_key :id do
      description "a uuid4, unique to this instance, generated by default"
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
    belongs_to :specification, Diffo.Provider.Specification do
      allow_nil? false
    end

    has_many :forward_relationships, Diffo.Provider.Relationship do
      destination_attribute :source_id
    end

    has_many :reverse_relationships, Diffo.Provider.Relationship do
      destination_attribute :target_id
    end

    has_many :characteristic, Diffo.Provider.Characteristic do
      public? true
    end

    has_many :feature, Diffo.Provider.Feature do
      public? true
    end

    has_many :party, Diffo.Provider.PartyRef do
      public? true
    end

    has_many :place, Diffo.Provider.PlaceRef do
      public? true
    end
  end

  validations do
    # TODO this isn't working as specified_instance_type is not loaded
    #validate confirm(:type, :specified_instance_type), on: [:create, :update]
  end

  calculations do
    calculate :category, :string, expr(specification.category) do
      description "indicates the category of the instance"
    end

    calculate :description, :string, expr(specification.description) do
      description "describes the service or resource specification"
    end

    calculate :tmf_version, :string, expr(specification.tmf_version) do
      description "indicates the TMF version of the service or resource"
    end

    calculate :specification_name, :string, expr(specification.name) do
      description "names the service or resource specification"
    end

    calculate :href, :string, expr(type <> "InventoryManagement/v" <> tmf_version <> "/" <> type <> "/" <> specification_name <> "/" <> id) do
      description "the inventory href of the service or resource instance"
    end
  end

  identities do
    identity :unique_name_per_specification_id, [:name, :specification_id]
  end

  preparations do
    prepare build(sort: [href: :asc])
  end

  def dates(result, record) do
    result
    |> Diffo.Util.ensure_not_nil(Diffo.Provider.Instance.derive_create_name(record.type), Diffo.Util.to_iso8601(record.inserted_at))
    |> Diffo.Util.ensure_not_nil(Diffo.Provider.Instance.derive_start_name(record.type), Diffo.Util.to_iso8601(record.started_at))
    |> Diffo.Util.ensure_not_nil(Diffo.Provider.Instance.derive_end_name(record.type), Diffo.Util.to_iso8601(record.stopped_at))
  end

  def states(result, record) do
    case record.type do
      :service ->
        result
        |> Diffo.Util.ensure_not_nil(:state, record.service_state)
        |> Diffo.Util.ensure_not_nil(:operatingStatus, record.service_operating_status)
      :resource ->
        result
        #|> Diffo.Util.ensure_not_nil(:administrativeState, record.resource_administrative_state)
        #|> Diffo.Util.ensure_not_nil(:operationalState, record.resource_operational_state)
        #|> Diffo.Util.ensure_not_nil(:resourceStatus, record.resource_status)
        #|> Diffo.Util.ensure_not_nil(:usageState, record.resource_usage_state)
    end
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
  Derives the instance feature collection name from the instance type
  ## Examples
    iex> Diffo.Provider.Instance.derive_feature_collection_name(:service)
    :feature

    iex> Diffo.Provider.Instance.derive_feature_collection_name(:resource)
    :activationFeature

  """
  def derive_feature_collection_name(type) do
    case type do
      :service -> :feature
      :resource -> :activationFeature
    end
  end

  @doc """
  Derives the instance characteristic collection name from the instance type
  ## Examples
    iex> Diffo.Provider.Instance.derive_characteristic_collection_name(:service)
    :serviceCharacteristic

    iex> Diffo.Provider.Instance.derive_characteristic_collection_name(:resource)
    :resourceCharacteristic

  """
  def derive_characteristic_collection_name(type) do
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
end
