defmodule Diffo.Provider.Instance.Util do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Util - Methods of general utility to an Instance
  """

  @doc """
  Assists in encoding instance category
  """
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

  @doc """
  Assists in encoding instance description
  """
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

  @doc """
  Assists in encoding instance dates
  """
  def dates(result, record) do
    result
    |> Diffo.Util.set(
      derive_create_date_name(record.type),
      Diffo.Util.to_iso8601(record.inserted_at)
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
        # |> Diffo.Util.ensure_not_nil(:administrativeState, record.resource_administrative_state)
        # |> Diffo.Util.ensure_not_nil(:operationalState, record.resource_operational_state)
        # |> Diffo.Util.ensure_not_nil(:resourceStatus, record.resource_status)
        # |> Diffo.Util.ensure_not_nil(:usageState, record.resource_usage_state)
    end
  end

  @doc """
  Assists in encoding instance-instance relationships
  """
  def relationships(result) do
    if relationships = Diffo.Util.get(result, :forward_relationships) do
      # sorting here as want to sort on the related instance hrefs, not the relationship
      sorted_relationships = Enum.sort_by(relationships, & &1.target.href, :asc)

      service_relationships =
        sorted_relationships
        |> Enum.filter(fn relationship ->
          relationship.target != nil && relationship.target.type == :service
        end)

      resource_relationships =
        sorted_relationships
        |> Enum.filter(fn relationship ->
          relationship.target != nil && relationship.target.type == :resource
        end)

      supporting_services =
        service_relationships
        |> Enum.filter(fn relationship ->
          relationship.alias != nil && relationship.target != nil
        end)
        |> Enum.into([], fn aliased ->
          Diffo.Provider.Reference.reference(aliased.target, :href)
        end)

      supporting_resources =
        resource_relationships
        |> Enum.filter(fn relationship ->
          relationship.alias != nil && relationship.target != nil
        end)
        |> Enum.into([], fn aliased ->
          Diffo.Provider.Reference.reference(aliased.target, :href)
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
      _ -> nil
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
      _ -> nil
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
      _ -> nil
    end
  end

  @doc """
  Derives the instance create date name from the instance type
  ## Examples
    iex> Diffo.Provider.Instance.derive_create_date_name(:service)
    :serviceDate

    iex> Diffo.Provider.Instance.derive_create_date_name(:resource)
    nil

  """

  def derive_create_date_name(type) do
    case type do
      :service -> :serviceDate
      _ -> nil
    end
  end

  @doc """
  Derives the instance start date name from the instance type
  ## Examples
    iex> Diffo.Provider.Instance.derive_start_date_name(:service)
    :startDate

    iex> Diffo.Provider.Instance.derive_start_date_name(:resource)
    :startOperatingDate

  """

  def derive_start_date_name(type) do
    case type do
      :service -> :startDate
      :resource -> :startOperatingDate
      _ -> nil
    end
  end

  @doc """
  Derives the instance end date name from the instance type
  ## Examples
    iex> Diffo.Provider.Instance.derive_end_date_name(:service)
    :endDate

    iex> Diffo.Provider.Instance.derive_end_date_name(:resource)
    :endOperatingDate

  """

  def derive_end_date_name(type) do
    case type do
      :service -> :endDate
      :resource -> :endOperatingDate
      _ -> nil
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
      _ -> nil
    end
  end

  @doc """
  Compares two instances, by ascending href
  ## Examples
    iex> compare(%{href: "a"}, %{href: "a"})
    :eq
    iex> compare(%{href: "b"}, %{href: "a"})
    :gt
    iex> compare(%{href: "a"}, %{href: "b"})
    :lt

  """
  def compare(%{href: href0}, %{href: href1}), do: Diffo.Util.compare(href0, href1)
end
