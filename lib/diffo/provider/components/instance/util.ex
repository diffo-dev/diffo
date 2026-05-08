# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Util do
  @moduledoc false
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
  def dates(result, record) do
    result
    |> Diffo.Util.set(
      derive_create_date_name(record.type),
      Diffo.Util.to_iso8601(record.created_at)
    )
    |> Diffo.Util.set(
      derive_start_date_name(record.type),
      Diffo.Util.to_iso8601(record.started_at)
    )
    |> Diffo.Util.set(
      derive_end_date_name(record.type),
      Diffo.Util.to_iso8601(record.stopped_at)
    )
  end

  @doc false
  def states(result, record) do
    case record.type do
      :service ->
        result
        |> Diffo.Util.set(:state, record.service_state)
        |> Diffo.Util.set(:operatingStatus, record.service_operating_status)

      :resource ->
        result
        # |> Diffo.Util.ensure_not_nil(:administrativeState, record.resource_administrative_state)
        # |> Diffo.Util.ensure_not_nil(:operationalState, record.resource_operational_state)
        # |> Diffo.Util.ensure_not_nil(:resourceStatus, record.resource_status)
        # |> Diffo.Util.ensure_not_nil(:usageState, record.resource_usage_state)
    end
  end

  @doc false
  def relationships(result) do
    if relationships = Diffo.Util.get(result, :forward_relationships) do
      service_relationships =
        relationships
        |> Enum.filter(fn relationship ->
          relationship.target != nil && relationship.target_type == :service
        end)

      resource_relationships =
        relationships
        |> Enum.filter(fn relationship ->
          relationship.target != nil && relationship.target_type == :resource
        end)

      supporting_services =
        service_relationships
        |> Enum.filter(fn relationship ->
          relationship.alias != nil
        end)
        |> Enum.into([], fn aliased ->
          %Diffo.Provider.Reference{id: aliased.alias, href: Map.get(aliased, :target_href)}
        end)

      supporting_resources =
        resource_relationships
        |> Enum.filter(fn relationship ->
          relationship.alias != nil
        end)
        |> Enum.into([], fn aliased ->
          %Diffo.Provider.Reference{id: aliased.alias, href: Map.get(aliased, :target_href)}
        end)

      result
      |> Diffo.Util.remove(:forward_relationships)
      |> Diffo.Util.remove(:reverse_relationships)
      |> Diffo.Util.set(:serviceRelationship, service_relationships)
      |> Diffo.Util.set(:resourceRelationship, resource_relationships)
      |> Diffo.Util.set(:supportingService, supporting_services)
      |> Diffo.Util.set(:supportingResource, supporting_resources)
    else
      result
      |> Diffo.Util.remove(:forward_relationships)
      |> Diffo.Util.remove(:reverse_relationships)
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
