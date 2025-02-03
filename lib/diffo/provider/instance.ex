defmodule Diffo.Provider.Instance do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Instance - Ash Resource for a TMF Service or Resource Instance
  """
  use Ash.Resource, otp_app: :diffo, domain: Diffo.Provider, data_layer: AshPostgres.DataLayer, extensions: [AshJason.Resource]

  postgres do
    table "instances"
    repo Diffo.Repo
  end

  jason do
    pick [:id, :href, :category, :description, :name, :specification, :forward_relationships, :feature, :characteristic, :type]
    customize fn result, record ->
      opts = [lazy?: true]
      loaded_record =
        record
        |> Ash.load!([:href, :characteristic, :feature, :forward_relationships], opts)
        |> Ash.load!([specification: [:href, :version]], opts)
        |> Ash.load!([feature: [:featureCharacteristic]], opts)
        |> Ash.load!([forward_relationships: [:target_type, :target_href, :characteristic]], opts)
      type = Map.get(loaded_record, :type)
      specification = loaded_record.specification
      relationships = loaded_record.forward_relationships |> Enum.sort({:asc, Diffo.Provider.Relationship})
      service_relationships = relationships |> Enum.filter(fn relationship -> relationship.target_type == :service end)
      resource_relationships = relationships |> Enum.filter(fn relationship -> relationship.target_type == :resource end)
      supporting_services =
        service_relationships
        |> Enum.filter(fn relationship -> relationship.alias != nil end)
        |> Enum.into([], fn aliased -> Diffo.Provider.Reference.reference(aliased) end)
      supporting_resources =
        resource_relationships
        |> Enum.filter(fn relationship -> relationship.alias != nil end)
        |> Enum.into([], fn aliased -> Diffo.Provider.Reference.reference(aliased) end)
      features = Map.get(loaded_record, :feature) |> Enum.sort({:asc, Diffo.Provider.Feature})
      features_name = Diffo.Provider.Instance.derive_feature_collection_name(type)
      characteristics = loaded_record.characteristic |> Enum.sort({:asc, Diffo.Provider.Characteristic})
      characteristics_name = Diffo.Provider.Instance.derive_characteristic_collection_name(type)
      result =
        result
        |> Map.put(:href, loaded_record.href)
        |> Diffo.Util.ensure_not_nil(:category, specification.category)
        |> Diffo.Util.ensure_not_nil(:description, specification.description)
        |> Map.put(specification.type, specification)
        |> Map.drop([:forward_relationships, :reverse_relationships])
        |> Diffo.Util.put_not_empty(:serviceRelationship, service_relationships)
        |> Diffo.Util.put_not_empty(:resourceRelationship, resource_relationships)
        |> Diffo.Util.put_not_empty(:supportingService, supporting_services)
        |> Diffo.Util.put_not_empty(:supportingResources, supporting_resources)
        |> Map.delete(:feature)
        |> Diffo.Util.put_not_empty(features_name, features)
        |> Diffo.Util.put_not_empty(characteristics_name, characteristics)
    end
    order [:id, :href, :category, :description, :name, :serviceSpecification, :resourceSpecification, :serviceRelationship,
      :resourceRelationship, :feature, :activationFeature, :serviceCharacteristic, :resourceCharacteristic]
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
    end

    update :cancel do
      description "cancels a service instance"
      require_atomic? false
      change set_attribute :service_state, :cancelled
      change set_attribute :service_operating_status, :pending
    end

    update :activate do
      description "activates a service instance"
      require_atomic? false
      change set_attribute :service_state, :active
      change set_attribute :service_operating_status, :starting
    end

    update :terminate do
      description "terminates a service instance"
      require_atomic? false
      change set_attribute :service_state, :terminated
      change set_attribute :service_operating_status, :stopping
    end

    update :transition do
      require_atomic? false
      description "transition service state and/or operating status"
      accept [:service_state, :service_operating_status]
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

    attribute :service_state, :atom do
      description "the service state, if this instance is a service"
      allow_nil? true
      public? true
      default Diffo.Provider.Service.default_service_state
      constraints one_of: Diffo.Provider.Service.service_states
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
  end

  validations do
    validate {Diffo.Validations.IsTransitionValid, state: :service_state, transition_map: :specification_service_state_transitions} do
      on [:update]
      where present(:service_state)
    end
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

    calculate :specification_service_state_transitions, :map, expr(specification.service_state_transition_map) do
      description "the service state transitions specified by the specification"
    end
  end

  identities do
    identity :unique_name_per_specification_id, [:name, :specification_id]
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
end
