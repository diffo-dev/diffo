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

    resource Diffo.Provider.Instance do
      define :create_instance, action: :create
      define :get_instance_by_id, action: :read, get_by: :id
      define :list_instances, action: :list
      define :find_instances_by_name, action: :find_by_name, args: [:query]

      define :find_instances_by_specification_id,
        action: :find_by_specification_id,
        args: [:query]

      define :name_instance, action: :name
      define :cancel_service, action: :cancel
      define :feasibilityCheck_service, action: :feasibilityCheck
      define :reserve_service, action: :reserve
      define :deactivate_service, action: :deactivate
      define :activate_service, action: :activate
      define :suspend_service, action: :suspend
      define :terminate_service, action: :terminate
      define :status_service, action: :status
      define :lifecycle_resource, action: :lifecycle
      define :respecify_instance, action: :specify
      define :relate_instance_features, action: :relate_features
      define :unrelate_instance_features, action: :unrelate_features
      define :relate_instance_characteristics, action: :relate_characteristics
      define :unrelate_instance_characteristics, action: :unrelate_characteristics
      define :annotate_instance, action: :annotate
      define :fire_instance_event, action: :fire_event
      define :delete_instance, action: :destroy
    end

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

    resource Diffo.Provider.Party do
      define :create_party, action: :create
      define :get_party_by_id, action: :read, get_by: :id
      define :list_parties, action: :list
      define :find_parties_by_id, action: :find_by_id, args: [:query]
      define :find_parties_by_name, action: :find_by_name, args: [:query]
      define :update_party, action: :update
      define :delete_party, action: :destroy
    end

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
  @spec create_place!(place_type(), map()) :: Ash.Resource.record()
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
          {:ok, Ash.Resource.record()} | {:error, term()}
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
  @spec update_place!(Ash.Resource.record(), map()) :: Ash.Resource.record()
  def update_place!(%Diffo.Provider.GeographicAddress{} = record, attrs),
    do: Ash.update!(record, attrs, action: :define, domain: __MODULE__)

  def update_place!(%Diffo.Provider.GeographicSite{} = record, attrs),
    do: Ash.update!(record, attrs, action: :define, domain: __MODULE__)

  def update_place!(%Diffo.Provider.GeographicLocation{} = record, attrs),
    do: Ash.update!(record, attrs, action: :define, domain: __MODULE__)

  def update_place!(%Diffo.Provider.Place{} = record, attrs),
    do: Ash.update!(record, attrs, action: :update, domain: __MODULE__)

  @doc "Same as `update_place!/2` but returns `{:ok, record}` or `{:error, error}`."
  @spec update_place(Ash.Resource.record(), map()) ::
          {:ok, Ash.Resource.record()} | {:error, term()}
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
  @spec delete_place!(Ash.Resource.record()) :: :ok
  def delete_place!(record) when is_struct(record) do
    Ash.destroy!(record, domain: __MODULE__)
    :ok
  end

  @doc """
  Same as `delete_place!/1` but returns `:ok` or `{:error, error}`.

  Accepts either a single record or a list of records (returns
  `%Ash.BulkResult{}` for lists).
  """
  @spec delete_place(Ash.Resource.record() | [Ash.Resource.record()]) ::
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
  @spec get_place_by_id!(String.t()) :: Ash.Resource.record()
  def get_place_by_id!(id) when is_binary(id) do
    Diffo.Provider.Place
    |> Ash.get!(id, domain: __MODULE__)
    |> project_place()
  end

  @doc "Same as `get_place_by_id!/1` but returns `{:ok, record}` or `{:error, error}`."
  @spec get_place_by_id(String.t()) :: {:ok, Ash.Resource.record()} | {:error, term()}
  def get_place_by_id(id) when is_binary(id) do
    case Ash.get(Diffo.Provider.Place, id, domain: __MODULE__) do
      {:ok, abstract} -> {:ok, project_place(abstract)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Lists all Places, each projected to its outermost concrete world.
  """
  @spec list_places!() :: [Ash.Resource.record()]
  def list_places! do
    Diffo.Provider.Place
    |> Ash.read!(action: :list, domain: __MODULE__)
    |> Enum.map(&project_place/1)
  end

  @doc "Same as `list_places!/0` but returns `{:ok, list}` or `{:error, error}`."
  @spec list_places() :: {:ok, [Ash.Resource.record()]} | {:error, term()}
  def list_places do
    case Ash.read(Diffo.Provider.Place, action: :list, domain: __MODULE__) do
      {:ok, places} -> {:ok, Enum.map(places, &project_place/1)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Finds Places whose id contains the query, each projected to its concrete world.
  """
  @spec find_places_by_id!(String.t()) :: [Ash.Resource.record()]
  def find_places_by_id!(query) do
    Diffo.Provider.Place
    |> Ash.Query.for_read(:find_by_id, %{query: query})
    |> Ash.read!(domain: __MODULE__)
    |> Enum.map(&project_place/1)
  end

  @doc """
  Finds Places whose name contains the query, each projected to its concrete world.
  """
  @spec find_places_by_name!(String.t()) :: [Ash.Resource.record()]
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
end
