# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Info do
  @moduledoc "Public introspection API for resources extending Diffo.Provider.BaseInstance"

  alias Spark.Dsl.Extension

  @doc "Returns the normalised specification keyword list for the resource"
  @spec specification(Ash.Resource.t()) :: keyword() | nil
  def specification(resource) do
    Extension.get_persisted(resource, :specification)
  end

  @doc "Returns the list of characteristic declarations for the resource"
  @spec characteristics(Ash.Resource.t()) :: list() | []
  def characteristics(resource) do
    Extension.get_persisted(resource, :characteristics, [])
  end

  @doc "Returns the list of feature declarations for the resource"
  @spec features(Ash.Resource.t()) :: list() | []
  def features(resource) do
    Extension.get_persisted(resource, :features, [])
  end

  @doc "Returns the list of party role declarations for the resource"
  @spec parties(Ash.Resource.t()) :: list() | []
  def parties(resource) do
    Extension.get_persisted(resource, :parties, [])
  end

  @doc "Returns the named characteristic declaration, or nil"
  @spec characteristic(Ash.Resource.t(), atom()) :: struct() | nil
  def characteristic(resource, name) do
    Enum.find(characteristics(resource), &(&1.name == name))
  end

  @doc "Returns the named feature declaration, or nil"
  @spec feature(Ash.Resource.t(), atom()) :: struct() | nil
  def feature(resource, name) do
    Enum.find(features(resource), &(&1.name == name))
  end

  @doc "Returns the named characteristic within a feature, or nil"
  @spec feature_characteristic(Ash.Resource.t(), atom(), atom()) :: struct() | nil
  def feature_characteristic(resource, feature_name, char_name) do
    case feature(resource, feature_name) do
      nil -> nil
      f -> Enum.find(f.characteristics, &(&1.name == char_name))
    end
  end

  @doc "Returns the party declaration for the given role, or nil"
  @spec party(Ash.Resource.t(), atom()) :: struct() | nil
  def party(resource, role) do
    Enum.find(parties(resource), &(&1.role == role))
  end

  @doc "Returns the list of place role declarations for the resource"
  @spec places(Ash.Resource.t()) :: list() | []
  def places(resource) do
    Extension.get_persisted(resource, :places, [])
  end

  @doc "Returns the place declaration for the given role, or nil"
  @spec place(Ash.Resource.t(), atom()) :: struct() | nil
  def place(resource, role) do
    Enum.find(places(resource), &(&1.role == role))
  end
end
