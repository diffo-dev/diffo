# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider do
  @moduledoc """
  Provider API endpoint
  """
  use Ash.Domain,
    otp_app: :diffo

  domain do
    description "Extensible Ash Resources and API related to Providing TMF Services and Resources"
  end

  @typedoc """
  A record produced by an Instance creator (`create_instance!/1`, `create_instance/1`) —
  the generic Service or Resource leaf the dispatcher constructs.
  """
  @type instance_record ::
          %Diffo.Provider.ServiceInstance{} | %Diffo.Provider.ResourceInstance{}

  @typedoc """
  A record produced by a Place creator (`create_place!/2`, `create_place/2`) — one of the
  blessed TMF place leaves the dispatcher constructs (`:PlaceRef` yields the abstract
  `Provider.Place`).
  """
  @type place_record ::
          %Diffo.Provider.Place{}
          | %Diffo.Provider.GeographicAddress{}
          | %Diffo.Provider.GeographicSite{}
          | %Diffo.Provider.GeographicLocation{}

  @typedoc """
  A record produced by a Party creator (`create_party!/2`, `create_party/2`) — one of the
  blessed TMF party leaves the dispatcher constructs (`:PartyRef`/`:Entity` yield the
  abstract `Provider.Party`).
  """
  @type party_record ::
          %Diffo.Provider.Party{}
          | %Diffo.Provider.Organization{}
          | %Diffo.Provider.Individual{}

  @typedoc """
  An open-world resource record. Reads project to the outermost concrete world via
  `AshNeo4j.worlds/1` — which may be a consumer-domain leaf unknown at compile time —
  and update/delete dispatch on whatever record they are handed. The set is therefore
  genuinely unbounded: a deliberate `struct()`, not a missing type.
  """
  @type projected_record :: struct()

  resources do
    resource Diffo.Provider.Specification do
      define :create_specification, action: :create
      define :get_specification_by_id, action: :read, get_by: :id
      define :get_latest_specification_by_name, action: :get_latest, args: [:query]
      define :list_specifications, action: :list
      define :find_specifications_by_name, action: :find_by_name, args: [:query]
      define :find_specifications_by_category, action: :find_by_category, args: [:query]
      define :describe_specification, action: :describe
      define :categorise_specification, action: :categorise
      define :next_minor_specification, action: :next_minor
      define :next_patch_specification, action: :next_patch
      define :delete_specification, action: :destroy
    end

    # `Diffo.Provider.Instance` is the abstract reader for the Service/Resource
    # cascade — registered bare. Instances are concrete Service/Resource leaves,
    # so reads project (`get_instance_by_id!`, etc.) and every record operation
    # (`activate_service!`, `respecify_instance!`, `delete_instance!`, …) is a
    # hand-written dispatcher function on `Diffo.Provider` that dispatches on the
    # record's own resource.
    resource Diffo.Provider.Instance
    # Concrete instance leaves, projected to from the abstract reader above.
    # `create_instance!/1` dispatches `:serviceSpecification` -> ServiceInstance and
    # `:resourceSpecification` -> ResourceInstance; reads go through the reader.
    resource Diffo.Provider.ServiceInstance
    resource Diffo.Provider.ResourceInstance

    resource Diffo.Provider.Relationship do
      define :create_relationship, action: :create

      define :get_relationship_by_id, action: :read, get_by: :id
      define :list_relationships, action: :list

      define :list_service_relationships_from,
        action: :list_service_relationships_from,
        args: [:instance_id]

      define :list_resource_relationships_from,
        action: :list_resource_relationships_from,
        args: [:instance_id]

      define :update_relationship, action: :update
      define :relate_relationship_characteristics, action: :relate_characteristics
      define :unrelate_relationship_characteristics, action: :unrelate_characteristics
      define :delete_relationship, action: :destroy
    end

    resource Diffo.Provider.DefinedSimpleRelationship do
      define :create_defined_simple_relationship, action: :create
      define :get_defined_simple_relationship_by_id, action: :read, get_by: :id
      define :delete_defined_simple_relationship, action: :destroy
    end

    resource Diffo.Provider.AssignmentRelationship do
      define :create_assignment_relationship, action: :create
      define :get_assignment_relationship_by_id, action: :read, get_by: :id
      define :delete_assignment_relationship, action: :destroy
    end

    resource Diffo.Provider.AssignableCharacteristic do
      define :create_assignable_characteristic, action: :create
      define :get_assignable_characteristic_by_id, action: :read, get_by: :id
      define :update_assignable_characteristic, action: :update
      define :delete_assignable_characteristic, action: :destroy
    end

    resource Diffo.Provider.Characteristic do
      define :create_characteristic, action: :create
      define :get_characteristic_by_id, action: :read, get_by: :id
      define :list_characteristics, action: :list
      define :update_characteristic, action: :update
      define :delete_characteristic, action: :destroy
    end

    resource Diffo.Provider.Feature do
      define :create_feature, action: :create
      define :get_feature_by_id, action: :read, get_by: :id
      define :list_features, action: :list
      define :update_feature, action: :update
      define :relate_feature_characteristics, action: :relate_characteristics
      define :unrelate_feature_characteristics, action: :unrelate_characteristics
      define :delete_feature, action: :destroy
    end

    resource Diffo.Provider.Place
    resource Diffo.Provider.GeographicAddress
    resource Diffo.Provider.GeographicSite
    resource Diffo.Provider.GeographicLocation
    resource Diffo.Provider.Organization
    resource Diffo.Provider.Individual

    resource Diffo.Provider.PlaceRef do
      define :create_place_ref, action: :create
      define :get_place_ref_by_id, action: :read, get_by: :id
      define :list_place_refs, action: :list
      define :list_place_refs_by_place_id, action: :list_place_refs_by_place_id, args: [:place_id]

      define :list_place_refs_by_instance_id,
        action: :list_place_refs_by_instance_id,
        args: [:instance_id]

      define :list_place_refs_by_party_id, action: :list_place_refs_by_party_id, args: [:party_id]

      define :list_place_refs_by_source_place_id,
        action: :list_place_refs_by_source_place_id,
        args: [:source_place_id]

      define :update_place_ref, action: :update
      define :delete_place_ref, action: :destroy
    end

    resource Diffo.Provider.Party

    resource Diffo.Provider.PartyRef do
      define :create_party_ref, action: :create
      define :get_party_ref_by_id, action: :read, get_by: :id
      define :list_party_refs, action: :list
      define :list_party_refs_by_party_id, action: :list_party_refs_by_party_id, args: [:party_id]

      define :list_party_refs_by_instance_id,
        action: :list_party_refs_by_instance_id,
        args: [:instance_id]

      define :list_party_refs_by_place_id, action: :list_party_refs_by_place_id, args: [:place_id]

      define :list_party_refs_by_source_party_id,
        action: :list_party_refs_by_source_party_id,
        args: [:source_party_id]

      define :update_party_ref, action: :update
      define :delete_party_ref, action: :destroy
    end

    resource Diffo.Provider.ExternalIdentifier do
      define :create_external_identifier, action: :create
      define :get_external_identifier_by_id, action: :read, get_by: :id
      define :list_external_identifiers, action: :list

      define :find_external_identifiers_by_external_id,
        action: :find_by_external_id,
        args: [:query]

      define :list_external_identifiers_by_instance_id,
        action: :list_external_identifiers_by_instance_id,
        args: [:instance_id]

      define :list_external_identifiers_by_owner_id,
        action: :list_external_identifiers_by_owner_id,
        args: [:owner_id]

      define :update_external_identifier, action: :update
      define :delete_external_identifier, action: :destroy
    end

    resource Diffo.Provider.ProcessStatus do
      define :create_process_status, action: :create
      define :get_process_status_by_id, action: :read, get_by: :id
      define :list_process_statuses, action: :list

      define :list_process_statuses_by_instance_id,
        action: :list_process_statuses_by_instance_id,
        args: [:instance_id]

      define :update_process_status, action: :update
      define :delete_process_status, action: :destroy
    end

    resource Diffo.Provider.Note do
      define :create_note, action: :create
      define :get_note_by_id, action: :read, get_by: :id
      define :list_notes, action: :list
      define :find_notes_by_note_id, action: :find_by_note_id, args: [:query]
      define :list_notes_by_instance_id, action: :list_notes_by_instance_id, args: [:instance_id]
      define :list_notes_by_author_id, action: :list_notes_by_author_id, args: [:author_id]
      define :update_note, action: :update
      define :delete_note, action: :destroy
    end

    resource Diffo.Provider.Entity do
      define :create_entity, action: :create
      define :get_entity_by_id, action: :read, get_by: :id
      define :list_entities, action: :list
      define :find_entities_by_id, action: :find_by_id, args: [:query]
      define :find_entities_by_name, action: :find_by_name, args: [:query]
      define :update_entity, action: :update
      define :delete_entity, action: :destroy
    end

    resource Diffo.Provider.EntityRef do
      define :create_entity_ref, action: :create
      define :get_entity_ref_by_id, action: :read, get_by: :id
      define :list_entity_refs, action: :list

      define :list_entity_refs_by_entity_id,
        action: :list_entity_refs_by_entity_id,
        args: [:entity_id]

      define :list_entity_refs_by_instance_id,
        action: :list_entity_refs_by_instance_id,
        args: [:instance_id]

      define :update_entity_ref, action: :update
      define :delete_entity_ref, action: :destroy
    end

    resource Diffo.Provider.Event do
      define :get_event_by_id, action: :read, get_by: :id
      define :list_events, action: :list

      define :list_events_by_instance_id,
        action: :list_events_by_instance_id,
        args: [:instance_id]

      define :delete_event, action: :destroy
    end
  end

  # ============================================================================
  # Instance dispatcher API
  #
  # `Diffo.Provider.Instance` is the abstract reader for the Service/Resource
  # cascade. Reads project each instance to its concrete leaf (a resource
  # composing `BaseInstance` + `Service`/`Resource`) via `AshNeo4j.worlds/1`, so
  # the leaf's TMF638/639 jason fires on encode. The service lifecycle dispatches
  # on the record's own resource — the lifecycle actions live on the `Service`
  # fragment, so any service leaf carries them.
  # ============================================================================

  @doc """
  Creates a generic Service or Resource instance, dispatching on the referenced
  specification's type.

  Reads the specification named by `:specified_by`: a `:serviceSpecification`
  creates a `Diffo.Provider.Instance` (the generic Service), a
  `:resourceSpecification` creates a `Diffo.Provider.ResourceInstance` (the generic
  Resource). This is the provider-only entry point — consumer instance kinds declare
  their own `:build` action and are created through their own domain, not here.

  Symmetric with `create_place!/2` and `create_party!/2`; dispatch is on the spec
  type rather than a passed atom, since the spec already names the kind.
  """
  @spec create_instance!(map()) :: instance_record()
  def create_instance!(attrs) when is_map(attrs) do
    {leaf, type} =
      attrs |> Map.fetch!(:specified_by) |> get_specification_by_id!() |> instance_leaf_for()

    Ash.create!(leaf, Map.put(attrs, :type, type), action: :create, domain: __MODULE__)
  end

  @doc "Same as `create_instance!/1` but returns `{:ok, record}` or `{:error, error}`."
  @spec create_instance(map()) :: {:ok, instance_record()} | {:error, term()}
  def create_instance(attrs) when is_map(attrs) do
    case get_specification_by_id(Map.get(attrs, :specified_by)) do
      {:ok, spec} ->
        {leaf, type} = instance_leaf_for(spec)
        Ash.create(leaf, Map.put(attrs, :type, type), action: :create, domain: __MODULE__)

      {:error, _} = error ->
        error
    end
  end

  defp instance_leaf_for(%{type: :serviceSpecification}),
    do: {Diffo.Provider.ServiceInstance, :service}

  defp instance_leaf_for(%{type: :resourceSpecification}),
    do: {Diffo.Provider.ResourceInstance, :resource}

  @doc """
  Loads an instance by id and projects it to its concrete Service/Resource leaf.

  Accepts a `:load` opt applied to the projected leaf (e.g. `load: [:event]`).
  """
  @spec get_instance_by_id!(String.t(), keyword()) :: projected_record()
  def get_instance_by_id!(id, opts \\ []) when is_binary(id) do
    Diffo.Provider.Instance
    |> Ash.get!(id, domain: __MODULE__)
    |> project_instance()
    |> load_projection(opts)
  end

  @doc "Same as `get_instance_by_id!/2` but returns `{:ok, record}` or `{:error, error}`."
  @spec get_instance_by_id(String.t(), keyword()) ::
          {:ok, projected_record()} | {:error, term()}
  def get_instance_by_id(id, opts \\ []) when is_binary(id) do
    case Ash.get(Diffo.Provider.Instance, id, domain: __MODULE__) do
      {:ok, abstract} -> {:ok, abstract |> project_instance() |> load_projection(opts)}
      {:error, _} = err -> err
    end
  end

  defp load_projection(record, opts) do
    case Keyword.get(opts, :load) do
      nil -> record
      load -> Ash.load!(record, load)
    end
  end

  @doc "Lists all instances, each projected to its concrete Service/Resource leaf."
  @spec list_instances!() :: [projected_record()]
  def list_instances! do
    Diffo.Provider.Instance
    |> Ash.read!(action: :list, domain: __MODULE__)
    |> Enum.map(&project_instance/1)
  end

  @doc "Finds instances whose name contains the query, each projected to its concrete leaf."
  @spec find_instances_by_name!(String.t()) :: [projected_record()]
  def find_instances_by_name!(query) do
    Diffo.Provider.Instance
    |> Ash.Query.for_read(:find_by_name, %{query: query})
    |> Ash.read!(domain: __MODULE__)
    |> Enum.map(&project_instance/1)
  end

  @doc "Finds instances by specification id, each projected to its concrete leaf."
  @spec find_instances_by_specification_id!(String.t()) :: [projected_record()]
  def find_instances_by_specification_id!(query) do
    Diffo.Provider.Instance
    |> Ash.Query.for_read(:find_by_specification_id, %{query: query})
    |> Ash.read!(domain: __MODULE__)
    |> Enum.map(&project_instance/1)
  end

  defp project_instance(%Diffo.Provider.Instance{id: id} = abstract) do
    case AshNeo4j.worlds(abstract) do
      [{domain, concrete} | _] when concrete != Diffo.Provider.Instance ->
        Ash.get!(concrete, id, domain: domain)

      _ ->
        abstract
    end
  end

  @doc "Feasibility-checks a service instance (dispatches on the record's resource)."
  def feasibilityCheck_service!(record, attrs \\ %{}),
    do: Ash.update!(record, attrs, action: :feasibilityCheck)

  @doc "Same as `feasibilityCheck_service!/2` but returns `{:ok, record}` or `{:error, error}`."
  def feasibilityCheck_service(record, attrs \\ %{}),
    do: Ash.update(record, attrs, action: :feasibilityCheck)

  @doc "Reserves a service instance."
  def reserve_service!(record), do: Ash.update!(record, %{}, action: :reserve)
  def reserve_service(record), do: Ash.update(record, %{}, action: :reserve)

  @doc "Deactivates a service instance."
  def deactivate_service!(record), do: Ash.update!(record, %{}, action: :deactivate)
  def deactivate_service(record), do: Ash.update(record, %{}, action: :deactivate)

  @doc "Activates a service instance."
  def activate_service!(record), do: Ash.update!(record, %{}, action: :activate)
  def activate_service(record), do: Ash.update(record, %{}, action: :activate)

  @doc "Suspends a service instance."
  def suspend_service!(record), do: Ash.update!(record, %{}, action: :suspend)
  def suspend_service(record), do: Ash.update(record, %{}, action: :suspend)

  @doc "Terminates a service instance."
  def terminate_service!(record), do: Ash.update!(record, %{}, action: :terminate)
  def terminate_service(record), do: Ash.update(record, %{}, action: :terminate)

  @doc "Cancels a service instance."
  def cancel_service!(record), do: Ash.update!(record, %{}, action: :cancel)
  def cancel_service(record), do: Ash.update(record, %{}, action: :cancel)

  @doc "Updates the operating status of a service instance."
  def status_service!(record, attrs \\ %{}), do: Ash.update!(record, attrs, action: :status)
  def status_service(record, attrs \\ %{}), do: Ash.update(record, attrs, action: :status)

  @doc "Sets the TMF lifecycleState of a resource instance."
  def lifecycle_resource!(record, attrs \\ %{}),
    do: Ash.update!(record, attrs, action: :lifecycle)

  @doc "Same as `lifecycle_resource!/2` but returns `{:ok, record}` or `{:error, error}`."
  def lifecycle_resource(record, attrs \\ %{}),
    do: Ash.update(record, attrs, action: :lifecycle)

  # Shared record operations — dispatch on the record's resource (the actions live
  # on `BaseInstance`, so every Service/Resource leaf carries them).

  @doc "Renames an instance."
  def name_instance!(record, attrs \\ %{}), do: Ash.update!(record, attrs, action: :name)
  def name_instance(record, attrs \\ %{}), do: Ash.update(record, attrs, action: :name)

  @doc "Respecifies an instance (changes its specification)."
  def respecify_instance!(record, attrs \\ %{}), do: Ash.update!(record, attrs, action: :specify)
  def respecify_instance(record, attrs \\ %{}), do: Ash.update(record, attrs, action: :specify)

  @doc "Relates features to an instance."
  def relate_instance_features!(record, attrs \\ %{}),
    do: Ash.update!(record, attrs, action: :relate_features)

  def relate_instance_features(record, attrs \\ %{}),
    do: Ash.update(record, attrs, action: :relate_features)

  @doc "Unrelates features from an instance."
  def unrelate_instance_features!(record, attrs \\ %{}),
    do: Ash.update!(record, attrs, action: :unrelate_features)

  def unrelate_instance_features(record, attrs \\ %{}),
    do: Ash.update(record, attrs, action: :unrelate_features)

  @doc "Relates characteristics to an instance."
  def relate_instance_characteristics!(record, attrs \\ %{}),
    do: Ash.update!(record, attrs, action: :relate_characteristics)

  def relate_instance_characteristics(record, attrs \\ %{}),
    do: Ash.update(record, attrs, action: :relate_characteristics)

  @doc "Unrelates characteristics from an instance."
  def unrelate_instance_characteristics!(record, attrs \\ %{}),
    do: Ash.update!(record, attrs, action: :unrelate_characteristics)

  def unrelate_instance_characteristics(record, attrs \\ %{}),
    do: Ash.update(record, attrs, action: :unrelate_characteristics)

  @doc "Annotates an instance with a note."
  def annotate_instance!(record, attrs \\ %{}), do: Ash.update!(record, attrs, action: :annotate)
  def annotate_instance(record, attrs \\ %{}), do: Ash.update(record, attrs, action: :annotate)

  @doc "Fires an event on an instance, maintaining the event chain."
  def fire_instance_event!(record, attrs \\ %{}),
    do: Ash.update!(record, attrs, action: :fire_event)

  def fire_instance_event(record, attrs \\ %{}),
    do: Ash.update(record, attrs, action: :fire_event)

  @doc "Deletes an instance (or a list of instances, returning an `%Ash.BulkResult{}`)."
  def delete_instance!(record), do: Ash.destroy!(record)

  def delete_instance(records) when is_list(records),
    do: Ash.bulk_destroy(records, :destroy, %{}, return_errors?: true)

  def delete_instance(record), do: Ash.destroy(record)

  # ============================================================================
  # Place dispatcher API
  #
  # Replaces per-subtype/per-codedef explosion with two dispatch patterns:
  #
  #   * Writes — dispatch by TMF type atom (create) or struct module (update,
  #     delete). One function per CRUD verb regardless of how many subtypes the
  #     cascade introduces.
  #
  #   * Reads — inline projection via `AshNeo4j.worlds/1`. Loads via
  #     `Provider.Place` (the abstract reader kept in core for this purpose),
  #     then projects each record to its outermost concrete world. Returns the
  #     concrete subtype struct (or the abstract Place if no concrete world
  #     resolves — e.g. a node created directly via `Provider.Place`).
  #
  # The dispatcher only knows TMF blessed types (`:GeographicAddress`,
  # `:GeographicSite`, `:GeographicLocation`). Consumer-specific shapes
  # (`MyApp.DataCentre`) create/update through their own domain APIs; reads
  # still surface them transparently via projection.
  # ============================================================================

  @place_type_to_resource %{
    GeographicAddress: Diffo.Provider.GeographicAddress,
    GeographicSite: Diffo.Provider.GeographicSite,
    GeographicLocation: Diffo.Provider.GeographicLocation
  }

  @typedoc """
  TMF blessed Place type atoms accepted by the dispatcher.

  `:PlaceRef` is the "placeholder Place" type — a record with `referred_type:`
  set, used as the target of a `PlaceRef` to an externally-managed Place.
  Dispatches to the abstract `Provider.Place`'s `:create` action (no
  subtype-specific attributes).
  """
  @type place_type ::
          :GeographicAddress | :GeographicSite | :GeographicLocation | :PlaceRef

  @doc """
  Creates a typed Place subtype by dispatching on the TMF type atom.

  Raises `ArgumentError` for unknown types — consumer-specific shapes go
  through consumer domains.
  """
  @spec create_place!(place_type(), map()) :: place_record()
  def create_place!(:PlaceRef, attrs) when is_map(attrs) do
    Ash.create!(Diffo.Provider.Place, attrs, action: :create, domain: __MODULE__)
  end

  def create_place!(type, attrs) when is_atom(type) and is_map(attrs) do
    case Map.fetch(@place_type_to_resource, type) do
      {:ok, resource} ->
        Ash.create!(resource, attrs, action: :build, domain: __MODULE__)

      :error ->
        raise ArgumentError,
              "unknown TMF Place type: #{inspect(type)}; expected one of " <>
                inspect([:PlaceRef | Map.keys(@place_type_to_resource)])
    end
  end

  @doc """
  Same as `create_place!/2` but returns `{:ok, record}` or `{:error, error}`.
  """
  @spec create_place(place_type(), map()) ::
          {:ok, place_record()} | {:error, term()}
  def create_place(:PlaceRef, attrs) when is_map(attrs) do
    Ash.create(Diffo.Provider.Place, attrs, action: :create, domain: __MODULE__)
  end

  def create_place(type, attrs) when is_atom(type) and is_map(attrs) do
    case Map.fetch(@place_type_to_resource, type) do
      {:ok, resource} ->
        Ash.create(resource, attrs, action: :build, domain: __MODULE__)

      :error ->
        {:error, ArgumentError.exception("unknown TMF Place type: #{inspect(type)}")}
    end
  end

  @doc """
  Updates a Place by dispatching on the record's struct module.

  Cascade leaves (`Provider.GeographicAddress`/`Site`/`Location`) update via
  their `:define` action; the abstract `Provider.Place` updates via its
  inherited `:update` action.
  """
  @spec update_place!(projected_record(), map()) :: projected_record()
  def update_place!(%Diffo.Provider.GeographicAddress{} = record, attrs),
    do: Ash.update!(record, attrs, action: :define, domain: __MODULE__)

  def update_place!(%Diffo.Provider.GeographicSite{} = record, attrs),
    do: Ash.update!(record, attrs, action: :define, domain: __MODULE__)

  def update_place!(%Diffo.Provider.GeographicLocation{} = record, attrs),
    do: Ash.update!(record, attrs, action: :define, domain: __MODULE__)

  def update_place!(%Diffo.Provider.Place{} = record, attrs),
    do: Ash.update!(record, attrs, action: :update, domain: __MODULE__)

  @doc "Same as `update_place!/2` but returns `{:ok, record}` or `{:error, error}`."
  @spec update_place(projected_record(), map()) ::
          {:ok, projected_record()} | {:error, term()}
  def update_place(%Diffo.Provider.GeographicAddress{} = record, attrs),
    do: Ash.update(record, attrs, action: :define, domain: __MODULE__)

  def update_place(%Diffo.Provider.GeographicSite{} = record, attrs),
    do: Ash.update(record, attrs, action: :define, domain: __MODULE__)

  def update_place(%Diffo.Provider.GeographicLocation{} = record, attrs),
    do: Ash.update(record, attrs, action: :define, domain: __MODULE__)

  def update_place(%Diffo.Provider.Place{} = record, attrs),
    do: Ash.update(record, attrs, action: :update, domain: __MODULE__)

  @doc """
  Deletes a Place record (any subtype, dispatched on its struct module).
  """
  @spec delete_place!(projected_record()) :: :ok
  def delete_place!(record) when is_struct(record) do
    Ash.destroy!(record, domain: __MODULE__)
    :ok
  end

  @doc """
  Same as `delete_place!/1` but returns `:ok` or `{:error, error}`.

  Accepts either a single record or a list of records (returns
  `%Ash.BulkResult{}` for lists).
  """
  @spec delete_place(projected_record() | [projected_record()]) ::
          :ok | {:error, term()} | Ash.BulkResult.t()
  def delete_place(record) when is_struct(record) do
    Ash.destroy(record, domain: __MODULE__)
  end

  def delete_place(records) when is_list(records) do
    Ash.bulk_destroy(records, :destroy, %{}, domain: __MODULE__, return_errors?: true)
  end

  @doc """
  Loads a Place by id and projects to the outermost concrete world.

  Returns the concrete subtype struct (`Provider.GeographicSite`,
  `MyApp.SydneyExchange`, etc.) or the abstract `Provider.Place` if no
  concrete world resolves.
  """
  @spec get_place_by_id!(String.t()) :: projected_record()
  def get_place_by_id!(id) when is_binary(id) do
    Diffo.Provider.Place
    |> Ash.get!(id, domain: __MODULE__)
    |> project_place()
  end

  @doc "Same as `get_place_by_id!/1` but returns `{:ok, record}` or `{:error, error}`."
  @spec get_place_by_id(String.t()) :: {:ok, projected_record()} | {:error, term()}
  def get_place_by_id(id) when is_binary(id) do
    case Ash.get(Diffo.Provider.Place, id, domain: __MODULE__) do
      {:ok, abstract} -> {:ok, project_place(abstract)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Lists all Places, each projected to its outermost concrete world.
  """
  @spec list_places!() :: [projected_record()]
  def list_places! do
    Diffo.Provider.Place
    |> Ash.read!(action: :list, domain: __MODULE__)
    |> Enum.map(&project_place/1)
  end

  @doc "Same as `list_places!/0` but returns `{:ok, list}` or `{:error, error}`."
  @spec list_places() :: {:ok, [projected_record()]} | {:error, term()}
  def list_places do
    case Ash.read(Diffo.Provider.Place, action: :list, domain: __MODULE__) do
      {:ok, places} -> {:ok, Enum.map(places, &project_place/1)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Finds Places whose id contains the query, each projected to its concrete world.
  """
  @spec find_places_by_id!(String.t()) :: [projected_record()]
  def find_places_by_id!(query) do
    Diffo.Provider.Place
    |> Ash.Query.for_read(:find_by_id, %{query: query})
    |> Ash.read!(domain: __MODULE__)
    |> Enum.map(&project_place/1)
  end

  @doc """
  Finds Places whose name contains the query, each projected to its concrete world.
  """
  @spec find_places_by_name!(String.t()) :: [projected_record()]
  def find_places_by_name!(query) do
    Diffo.Provider.Place
    |> Ash.Query.for_read(:find_by_name, %{query: query})
    |> Ash.read!(domain: __MODULE__)
    |> Enum.map(&project_place/1)
  end

  defp project_place(%Diffo.Provider.Place{id: id} = abstract) do
    case AshNeo4j.worlds(abstract) do
      [{domain, concrete} | _] when concrete != Diffo.Provider.Place ->
        Ash.get!(concrete, id, domain: domain)

      _ ->
        abstract
    end
  end

  # ============================================================================
  # Party dispatcher API
  #
  # Mirrors the Place dispatcher exactly. Type-atom create, struct-dispatched
  # update/delete, inline projection on reads via Provider.Party as the
  # abstract reader. The dispatcher only knows TMF blessed types
  # (`:Organization`, `:Individual`, `:PartyRef`); consumer-specific shapes
  # (`MyApp.Carrier`) create/update through their own domain APIs but reads
  # surface them transparently via projection.
  # ============================================================================

  @party_type_to_resource %{
    Organization: Diffo.Provider.Organization,
    Individual: Diffo.Provider.Individual
  }

  @typedoc """
  TMF blessed Party type atoms accepted by the dispatcher.

  `:PartyRef` and `:Entity` route to the abstract `Provider.Party`'s `:create`
  action (no subtype-specific attributes). `:PartyRef` is the "placeholder Party"
  type — a record with `referred_type:` set, used as the target of a `PartyRef`
  to an externally-managed Party. `:Entity` is diffo's extension to the TMF
  type enum for party-like aggregates that aren't strictly Organization or
  Individual.
  """
  @type party_type :: :Organization | :Individual | :PartyRef | :Entity

  @doc """
  Creates a typed Party subtype by dispatching on the TMF type atom.

  Raises `ArgumentError` for unknown types — consumer-specific shapes go
  through consumer domains.
  """
  @spec create_party!(party_type(), map()) :: party_record()
  def create_party!(:PartyRef, attrs) when is_map(attrs) do
    Ash.create!(Diffo.Provider.Party, attrs, action: :create, domain: __MODULE__)
  end

  def create_party!(:Entity, attrs) when is_map(attrs) do
    Ash.create!(
      Diffo.Provider.Party,
      Map.put(attrs, :type, :Entity),
      action: :create,
      domain: __MODULE__
    )
  end

  def create_party!(type, attrs) when is_atom(type) and is_map(attrs) do
    case Map.fetch(@party_type_to_resource, type) do
      {:ok, resource} ->
        Ash.create!(resource, attrs, action: :build, domain: __MODULE__)

      :error ->
        raise ArgumentError,
              "unknown TMF Party type: #{inspect(type)}; expected one of " <>
                inspect([:PartyRef, :Entity | Map.keys(@party_type_to_resource)])
    end
  end

  @doc "Same as `create_party!/2` but returns `{:ok, record}` or `{:error, error}`."
  @spec create_party(party_type(), map()) ::
          {:ok, party_record()} | {:error, term()}
  def create_party(:PartyRef, attrs) when is_map(attrs) do
    Ash.create(Diffo.Provider.Party, attrs, action: :create, domain: __MODULE__)
  end

  def create_party(:Entity, attrs) when is_map(attrs) do
    Ash.create(
      Diffo.Provider.Party,
      Map.put(attrs, :type, :Entity),
      action: :create,
      domain: __MODULE__
    )
  end

  def create_party(type, attrs) when is_atom(type) and is_map(attrs) do
    case Map.fetch(@party_type_to_resource, type) do
      {:ok, resource} ->
        Ash.create(resource, attrs, action: :build, domain: __MODULE__)

      :error ->
        {:error, ArgumentError.exception("unknown TMF Party type: #{inspect(type)}")}
    end
  end

  @doc """
  Updates a Party by dispatching on the record's struct module.

  Cascade leaves (`Provider.Organization`/`Individual`) update via their
  `:define` action; the abstract `Provider.Party` updates via its inherited
  `:update` action.
  """
  @spec update_party!(projected_record(), map()) :: projected_record()
  def update_party!(%Diffo.Provider.Organization{} = record, attrs),
    do: Ash.update!(record, attrs, action: :define, domain: __MODULE__)

  def update_party!(%Diffo.Provider.Individual{} = record, attrs),
    do: Ash.update!(record, attrs, action: :define, domain: __MODULE__)

  def update_party!(%Diffo.Provider.Party{} = record, attrs),
    do: Ash.update!(record, attrs, action: :update, domain: __MODULE__)

  @doc "Same as `update_party!/2` but returns `{:ok, record}` or `{:error, error}`."
  @spec update_party(projected_record(), map()) ::
          {:ok, projected_record()} | {:error, term()}
  def update_party(%Diffo.Provider.Organization{} = record, attrs),
    do: Ash.update(record, attrs, action: :define, domain: __MODULE__)

  def update_party(%Diffo.Provider.Individual{} = record, attrs),
    do: Ash.update(record, attrs, action: :define, domain: __MODULE__)

  def update_party(%Diffo.Provider.Party{} = record, attrs),
    do: Ash.update(record, attrs, action: :update, domain: __MODULE__)

  @doc "Deletes a Party record (any subtype, dispatched on its struct module)."
  @spec delete_party!(projected_record()) :: :ok
  def delete_party!(record) when is_struct(record) do
    Ash.destroy!(record, domain: __MODULE__)
    :ok
  end

  @doc """
  Same as `delete_party!/1` but returns `:ok` or `{:error, error}`.

  Accepts either a single record or a list of records (returns
  `%Ash.BulkResult{}` for lists).
  """
  @spec delete_party(projected_record() | [projected_record()]) ::
          :ok | {:error, term()} | Ash.BulkResult.t()
  def delete_party(record) when is_struct(record) do
    Ash.destroy(record, domain: __MODULE__)
  end

  def delete_party(records) when is_list(records) do
    Ash.bulk_destroy(records, :destroy, %{}, domain: __MODULE__, return_errors?: true)
  end

  @doc """
  Loads a Party by id and projects to the outermost concrete world.

  Returns the concrete subtype struct (`Provider.Organization`,
  `Provider.Individual`, `MyApp.Carrier`, etc.) or the abstract
  `Provider.Party` if no concrete world resolves.
  """
  @spec get_party_by_id!(String.t()) :: projected_record()
  def get_party_by_id!(id) when is_binary(id) do
    Diffo.Provider.Party
    |> Ash.get!(id, domain: __MODULE__)
    |> project_party()
  end

  @doc "Same as `get_party_by_id!/1` but returns `{:ok, record}` or `{:error, error}`."
  @spec get_party_by_id(String.t()) :: {:ok, projected_record()} | {:error, term()}
  def get_party_by_id(id) when is_binary(id) do
    case Ash.get(Diffo.Provider.Party, id, domain: __MODULE__) do
      {:ok, abstract} -> {:ok, project_party(abstract)}
      {:error, _} = err -> err
    end
  end

  @doc "Lists all Parties, each projected to its outermost concrete world."
  @spec list_parties!() :: [projected_record()]
  def list_parties! do
    Diffo.Provider.Party
    |> Ash.read!(action: :list, domain: __MODULE__)
    |> Enum.map(&project_party/1)
  end

  @doc "Same as `list_parties!/0` but returns `{:ok, list}` or `{:error, error}`."
  @spec list_parties() :: {:ok, [projected_record()]} | {:error, term()}
  def list_parties do
    case Ash.read(Diffo.Provider.Party, action: :list, domain: __MODULE__) do
      {:ok, parties} -> {:ok, Enum.map(parties, &project_party/1)}
      {:error, _} = err -> err
    end
  end

  @doc "Finds Parties whose id contains the query, each projected to its concrete world."
  @spec find_parties_by_id!(String.t()) :: [projected_record()]
  def find_parties_by_id!(query) do
    Diffo.Provider.Party
    |> Ash.Query.for_read(:find_by_id, %{query: query})
    |> Ash.read!(domain: __MODULE__)
    |> Enum.map(&project_party/1)
  end

  @doc "Finds Parties whose name contains the query, each projected to its concrete world."
  @spec find_parties_by_name!(String.t()) :: [projected_record()]
  def find_parties_by_name!(query) do
    Diffo.Provider.Party
    |> Ash.Query.for_read(:find_by_name, %{query: query})
    |> Ash.read!(domain: __MODULE__)
    |> Enum.map(&project_party/1)
  end

  defp project_party(%Diffo.Provider.Party{id: id} = abstract) do
    case AshNeo4j.worlds(abstract) do
      [{domain, concrete} | _] when concrete != Diffo.Provider.Party ->
        Ash.get!(concrete, id, domain: domain)

      _ ->
        abstract
    end
  end

  # ============================================================================
  # Polymorphic-source ref dispatcher API
  #
  # Collapses the noisy four-FK shape on PlaceRef/PartyRef into one tagged-tuple
  # `source:` field, with reads expressed as intent (`_from/_targeting`) rather
  # than per-FK (`_by_*_id`). The schema is unchanged — the four FK columns stay
  # in the underlying resource; the dispatcher just unpacks the source tag.
  #
  # The source can be a tagged tuple (`{:instance, id}` / `{:party, id}` /
  # `{:place, id}`) or a struct whose module is recognised below. Consumer
  # leaves outside diffo's known set should use tagged tuples.
  # ============================================================================

  @doc """
  Creates a PlaceRef from a tagged source to a target Place.

  ## Source forms

      source: {:instance, "INST-001"}
      source: {:party, "PARTY-001"}
      source: {:place, "PLACE-001"}
      source: some_instance_struct
      source: some_party_struct
      source: some_place_struct

  ## Target forms

      target: "LOC-001"
      target: some_place_struct
  """
  @spec create_place_ref!(map()) :: %Diffo.Provider.PlaceRef{}
  def create_place_ref!(%{role: _, source: source, target: target} = attrs) do
    attrs
    |> Map.delete(:source)
    |> Map.delete(:target)
    |> place_ref_put_source(source)
    |> Map.put(:place_id, normalize_target_id(target))
    |> then(&Ash.create!(Diffo.Provider.PlaceRef, &1, action: :create, domain: __MODULE__))
  end

  @doc "Same as `create_place_ref!/1` but returns `{:ok, record}` or `{:error, error}`."
  @spec create_place_ref(map()) :: {:ok, %Diffo.Provider.PlaceRef{}} | {:error, term()}
  def create_place_ref(%{role: _, source: source, target: target} = attrs) do
    attrs
    |> Map.delete(:source)
    |> Map.delete(:target)
    |> place_ref_put_source(source)
    |> Map.put(:place_id, normalize_target_id(target))
    |> then(&Ash.create(Diffo.Provider.PlaceRef, &1, action: :create, domain: __MODULE__))
  end

  @doc """
  Lists PlaceRefs whose source matches the given Instance/Party/Place.
  """
  @spec list_place_refs_from(tagged_source() | projected_record()) ::
          [%Diffo.Provider.PlaceRef{}]
  def list_place_refs_from({:instance, id}),
    do: list_place_refs_by_instance_id!(id)

  def list_place_refs_from({:party, id}),
    do: list_place_refs_by_party_id!(id)

  def list_place_refs_from({:place, id}),
    do: list_place_refs_by_source_place_id!(id)

  def list_place_refs_from(%mod{id: id}) do
    list_place_refs_from({source_kind_for(mod), id})
  end

  @doc """
  Lists PlaceRefs targeting the given Place.
  """
  @spec list_place_refs_targeting(String.t() | projected_record()) ::
          [%Diffo.Provider.PlaceRef{}]
  def list_place_refs_targeting(target) do
    list_place_refs_by_place_id!(normalize_target_id(target))
  end

  @doc """
  Creates a PartyRef from a tagged source to a target Party.

  ## Source forms

      source: {:instance, "INST-001"}
      source: {:place, "PLACE-001"}
      source: {:party, "PARTY-001"}
      source: some_instance_struct
      source: some_place_struct
      source: some_party_struct
  """
  @spec create_party_ref!(map()) :: %Diffo.Provider.PartyRef{}
  def create_party_ref!(%{role: _, source: source, target: target} = attrs) do
    attrs
    |> Map.delete(:source)
    |> Map.delete(:target)
    |> party_ref_put_source(source)
    |> Map.put(:party_id, normalize_target_id(target))
    |> then(&Ash.create!(Diffo.Provider.PartyRef, &1, action: :create, domain: __MODULE__))
  end

  @doc "Same as `create_party_ref!/1` but returns `{:ok, record}` or `{:error, error}`."
  @spec create_party_ref(map()) :: {:ok, %Diffo.Provider.PartyRef{}} | {:error, term()}
  def create_party_ref(%{role: _, source: source, target: target} = attrs) do
    attrs
    |> Map.delete(:source)
    |> Map.delete(:target)
    |> party_ref_put_source(source)
    |> Map.put(:party_id, normalize_target_id(target))
    |> then(&Ash.create(Diffo.Provider.PartyRef, &1, action: :create, domain: __MODULE__))
  end

  @doc "Lists PartyRefs whose source matches the given Instance/Place/Party."
  @spec list_party_refs_from(tagged_source() | projected_record()) ::
          [%Diffo.Provider.PartyRef{}]
  def list_party_refs_from({:instance, id}),
    do: list_party_refs_by_instance_id!(id)

  def list_party_refs_from({:place, id}),
    do: list_party_refs_by_place_id!(id)

  def list_party_refs_from({:party, id}),
    do: list_party_refs_by_source_party_id!(id)

  def list_party_refs_from(%mod{id: id}) do
    list_party_refs_from({source_kind_for(mod), id})
  end

  @doc "Lists PartyRefs targeting the given Party."
  @spec list_party_refs_targeting(String.t() | projected_record()) ::
          [%Diffo.Provider.PartyRef{}]
  def list_party_refs_targeting(target) do
    list_party_refs_by_party_id!(normalize_target_id(target))
  end

  @typedoc "Tagged source for ref dispatchers."
  @type tagged_source :: {:instance | :party | :place, String.t()}

  # Source put-fns: place the id in the right FK column based on the source tag.

  defp place_ref_put_source(attrs, {:instance, id}), do: Map.put(attrs, :instance_id, id)
  defp place_ref_put_source(attrs, {:party, id}), do: Map.put(attrs, :party_id, id)
  defp place_ref_put_source(attrs, {:place, id}), do: Map.put(attrs, :source_place_id, id)

  defp place_ref_put_source(attrs, %mod{id: id}),
    do: place_ref_put_source(attrs, {source_kind_for(mod), id})

  defp place_ref_put_source(_attrs, other) do
    raise ArgumentError,
          "unknown source kind for PlaceRef: #{inspect(other)}; " <>
            "use a tagged tuple ({:instance, id} / {:party, id} / {:place, id}) " <>
            "or a known Instance/Party/Place struct with an :id"
  end

  defp party_ref_put_source(attrs, {:instance, id}), do: Map.put(attrs, :instance_id, id)
  defp party_ref_put_source(attrs, {:place, id}), do: Map.put(attrs, :place_id, id)
  defp party_ref_put_source(attrs, {:party, id}), do: Map.put(attrs, :source_party_id, id)

  defp party_ref_put_source(attrs, %mod{id: id}),
    do: party_ref_put_source(attrs, {source_kind_for(mod), id})

  defp party_ref_put_source(_attrs, other) do
    raise ArgumentError,
          "unknown source kind for PartyRef: #{inspect(other)}; " <>
            "use a tagged tuple ({:instance, id} / {:place, id} / {:party, id}) " <>
            "or a known Instance/Place/Party struct with an :id"
  end

  defp normalize_target_id(%{id: id}), do: id
  defp normalize_target_id(id) when is_binary(id), do: id

  # Map known struct modules to their kind tag. Consumer leaves outside this
  # list should use tagged tuples explicitly — diffo doesn't have a registry
  # and can't enumerate consumer-domain Places/Parties/Instances at compile
  # time.
  defp source_kind_for(Diffo.Provider.Instance), do: :instance
  defp source_kind_for(Diffo.Provider.Party), do: :party
  defp source_kind_for(Diffo.Provider.Organization), do: :party
  defp source_kind_for(Diffo.Provider.Individual), do: :party
  defp source_kind_for(Diffo.Provider.Place), do: :place
  defp source_kind_for(Diffo.Provider.GeographicAddress), do: :place
  defp source_kind_for(Diffo.Provider.GeographicSite), do: :place
  defp source_kind_for(Diffo.Provider.GeographicLocation), do: :place

  defp source_kind_for(mod) do
    raise ArgumentError,
          "unknown source kind for #{inspect(mod)}; use a tagged tuple " <>
            "(`{:instance, id}` / `{:party, id}` / `{:place, id}`) for consumer-domain structs"
  end
end
