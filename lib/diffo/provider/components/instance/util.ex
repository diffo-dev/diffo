# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Util do
  @moduledoc false
  alias Diffo.Provider.Extension.Info
  alias Diffo.Provider.Extension.InheritedPlaceDeclaration
  alias Diffo.Provider.Extension.InheritedPartyDeclaration
  alias Diffo.Provider.Extension.InheritedCharacteristicDeclaration
  alias Diffo.Provider.Extension.ReverseInheritedCharacteristicDeclaration

  # Each of the three functions below is injected as its own `jason.customize`
  # step by `Diffo.Provider.Extension.Transformers.TransformInheritedJason`, but
  # only for the inherited kinds a resource actually declares — one focused step
  # per TMF array. They run after `BaseInstance`'s own customize, so the array
  # keys are already in TMF form (`:place`, `:relatedParty`,
  # `:serviceCharacteristic` / `:resourceCharacteristic`).
  #
  # Each reads the matching calc(s) off the record. A `%Ash.NotLoaded{}` (the
  # consumer didn't load it) or `nil` contributes nothing; `%Diffo.Unknown{}`
  # sentinels are dropped — X-state is the Diffo diagnostic surface, not the TMF
  # wire.
  #
  # Places and parties surface as `PlaceRef` / `PartyRef`-shaped entries: the
  # inheritance has no backing ref node, but the ref carries "what this place /
  # party means to me" (the declared role), which is an essential part of the
  # TMF shape. We simulate it by wrapping the inherited target in an ephemeral
  # (non-persisted) `PlaceRef` / `PartyRef` stamped with the declaration role and
  # letting the ref's own `Jason.Encoder` produce the exact wire shape. Typed
  # characteristics carry their own `name`, so they surface as-is.
  #
  # Ordering follows the convention: locals stay first (already in `result`),
  # then inherited values; within characteristics, inherited before
  # reverse-inherited.

  @doc "Surfaces `inherited_place` calc results into the `place` array as simulated `PlaceRef`s."
  def surface_inherited_places(result, record) do
    refs =
      record.__struct__
      |> inherited_place_roles()
      |> Enum.flat_map(fn role ->
        record
        |> loaded_values(role)
        |> Enum.map(&%Diffo.Provider.PlaceRef{role: role, place: &1})
      end)

    append_values(result, :place, refs)
  end

  @doc "Surfaces `inherited_party` calc results into the `relatedParty` array as simulated `PartyRef`s."
  def surface_inherited_parties(result, record) do
    refs =
      record.__struct__
      |> inherited_party_roles()
      |> Enum.flat_map(fn role ->
        record
        |> loaded_values(role)
        |> Enum.map(&%Diffo.Provider.PartyRef{role: role, party: &1})
      end)

    append_values(result, :relatedParty, refs)
  end

  @doc """
  Surfaces `inherited_characteristic` then `reverse_inherited_characteristic`
  calc results into the `serviceCharacteristic` / `resourceCharacteristic` array.
  """
  def surface_inherited_characteristics(result, record) do
    characteristics =
      record.__struct__
      |> inherited_characteristic_names()
      |> Enum.flat_map(&loaded_values(record, &1))

    append_values(result, derive_characteristic_list_name(record.type), characteristics)
  end

  defp inherited_place_roles(resource) do
    resource
    |> Info.provider_places()
    |> Enum.filter(&is_struct(&1, InheritedPlaceDeclaration))
    |> Enum.map(& &1.role)
  end

  defp inherited_party_roles(resource) do
    resource
    |> Info.provider_parties()
    |> Enum.filter(&is_struct(&1, InheritedPartyDeclaration))
    |> Enum.map(& &1.role)
  end

  defp inherited_characteristic_names(resource) do
    characteristics = Info.provider_characteristics(resource)

    inherited =
      characteristics
      |> Enum.filter(&is_struct(&1, InheritedCharacteristicDeclaration))
      |> Enum.map(& &1.role)

    reverse =
      characteristics
      |> Enum.filter(&is_struct(&1, ReverseInheritedCharacteristicDeclaration))
      |> Enum.map(& &1.name)

    inherited ++ reverse
  end

  # Appends the surfaced values to the named array, preserving any locals already
  # present.
  defp append_values(result, nil, _values), do: result
  defp append_values(result, _key, []), do: result

  defp append_values(result, key, values) do
    Diffo.Util.set(result, key, (Diffo.Util.get(result, key) || []) ++ values)
  end

  # The concrete values for an inherited calc: a `%Ash.NotLoaded{}` (consumer
  # didn't load it) or `nil` yields none, and `%Diffo.Unknown{}` sentinels are
  # dropped — X-state is the Diffo diagnostic surface, not the TMF wire. Rejecting
  # Unknowns here (before any ref wrapping) keeps them off the wire entirely.
  defp loaded_values(record, name) do
    case Map.get(record, name) do
      %Ash.NotLoaded{} -> []
      nil -> []
      list when is_list(list) -> Enum.reject(list, &is_struct(&1, Diffo.Unknown))
      value -> if is_struct(value, Diffo.Unknown), do: [], else: [value]
    end
  end

  @doc false
  def category(result, record) do
    specification = Map.get(record, :specification)

    if is_struct(specification, Diffo.Provider.Specification) do
      category = Map.get(specification, :category)

      if category != nil do
        result |> Diffo.Util.set(:category, category)
      else
        result
      end
    else
      result
    end
  end

  @doc false
  def description(result, record) do
    specification = Map.get(record, :specification)

    if is_struct(specification, Diffo.Provider.Specification) do
      description = Map.get(specification, :description)

      if description != nil do
        result |> Diffo.Util.set(:description, description)
      else
        result
      end
    else
      result
    end
  end

  @doc false
  def service_dates(result, record) do
    result
    |> Diffo.Util.set(:serviceDate, Diffo.Util.to_iso8601(record.created_at))
    |> Diffo.Util.set(:startDate, Diffo.Util.to_iso8601(record.started_at))
    |> Diffo.Util.set(:endDate, Diffo.Util.to_iso8601(record.stopped_at))
  end

  @doc false
  def resource_dates(result, record) do
    result
    |> Diffo.Util.set(:startOperatingDate, Diffo.Util.to_iso8601(record.started_at))
    |> Diffo.Util.set(:endOperatingDate, Diffo.Util.to_iso8601(record.stopped_at))
  end

  @doc false
  def service_states(result, record) do
    result
    |> Diffo.Util.set(:state, record.state)
    |> Diffo.Util.set(:operatingStatus, record.operating_status)
  end

  @doc false
  def resource_states(result, record) do
    case record.resource_state do
      nil -> result
      state -> Diffo.Util.set(result, :lifecycleState, state)
    end
  end

  @doc false
  def relationships(result) do
    fwd = Diffo.Util.get(result, :forward_relationships)
    asgn = Diffo.Util.get(result, :assignments)

    if fwd != nil or asgn != nil do
      all_relationships = List.wrap(fwd) ++ List.wrap(asgn)

      service_relationships =
        Enum.filter(all_relationships, fn rel ->
          rel.target != nil && rel.target_type == :service
        end)

      resource_relationships =
        Enum.filter(all_relationships, fn rel ->
          rel.target != nil && rel.target_type == :resource
        end)

      supporting_services =
        service_relationships
        |> Enum.filter(fn rel -> Map.get(rel, :alias) != nil end)
        |> Enum.map(fn aliased ->
          %Diffo.Provider.Reference{id: aliased.alias, href: Map.get(aliased, :target_href)}
        end)

      supporting_resources =
        resource_relationships
        |> Enum.filter(fn rel -> Map.get(rel, :alias) != nil end)
        |> Enum.map(fn aliased ->
          %Diffo.Provider.Reference{id: aliased.alias, href: Map.get(aliased, :target_href)}
        end)

      result
      |> Diffo.Util.remove(:forward_relationships)
      |> Diffo.Util.remove(:reverse_relationships)
      |> Diffo.Util.remove(:assignments)
      |> Diffo.Util.set(:serviceRelationship, service_relationships)
      |> Diffo.Util.set(:resourceRelationship, resource_relationships)
      |> Diffo.Util.set(:supportingService, supporting_services)
      |> Diffo.Util.set(:supportingResource, supporting_resources)
    else
      result
      |> Diffo.Util.remove(:forward_relationships)
      |> Diffo.Util.remove(:reverse_relationships)
      |> Diffo.Util.remove(:assignments)
    end
  end

  @doc false
  def merge_typed_and_pool_characteristics(result, record) do
    typed = Map.get(record, :typed_characteristics) || []
    pool = Map.get(record, :pool_characteristics) || []
    extras = typed ++ pool

    case extras do
      [] ->
        result

      _ ->
        existing = Diffo.Util.get(result, :characteristics) || []
        Diffo.Util.set(result, :characteristics, existing ++ extras)
    end
  end

  @doc false
  def derive_type(specification_type) do
    case specification_type do
      :serviceSpecification -> :service
      :resourceSpecification -> :resource
      _ -> nil
    end
  end

  @doc false
  def derive_feature_list_name(type) do
    case type do
      :service -> :feature
      :resource -> :activationFeature
      _ -> nil
    end
  end

  @doc false
  def derive_characteristic_list_name(type) do
    case type do
      :service -> :serviceCharacteristic
      :resource -> :resourceCharacteristic
      _ -> nil
    end
  end

  @doc false
  def derive_create_date_name(type) do
    case type do
      :service -> :serviceDate
      _ -> nil
    end
  end

  @doc false
  def derive_start_date_name(type) do
    case type do
      :service -> :startDate
      :resource -> :startOperatingDate
      _ -> nil
    end
  end

  @doc false
  def derive_end_date_name(type) do
    case type do
      :service -> :endDate
      :resource -> :endOperatingDate
      _ -> nil
    end
  end

  @doc false
  def other(which) do
    case which do
      :actual -> :expected
      :expected -> :actual
      _ -> nil
    end
  end
end
