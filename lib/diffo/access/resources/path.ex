# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Access.Path do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Path - Path Resource Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Specification
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Feature
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party

  alias Diffo.Access

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a Path"
    plural_name :Paths
  end

  specification do
    id "1d507914-8f76-48cb-aa0e-3a8f92951ab0"
    name "path"
    type :resourceSpecification
    description "A Path Resource Instance"
    category "Network Resource"
  end

  characteristics do
    characteristic :path, Diffo.Access.PathValue
  end

  actions do
    create :build do
      description "creates a new Path resource instance for build"
      accept [:id, :name, :type, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context ->
               changeset
               |> Specification.set_specified_by_argument()
               |> Feature.set_features_argument()
               |> Characteristic.set_characteristics_argument()
             end)

      change after_action(fn changeset, result, _context ->
               with {:ok, with_specification} <- Specification.relate_instance(result, changeset),
                    {:ok, with_relationships} <-
                      Relationship.relate_instance(with_specification, changeset),
                    {:ok, with_features} <-
                      Feature.relate_instance(with_relationships, changeset),
                    {:ok, with_characteristics} <-
                      Characteristic.relate_instance(with_features, changeset),
                    {:ok, with_places} <- Place.relate_instance(with_characteristics, changeset),
                    {:ok, _with_parties} <- Party.relate_instance(with_places, changeset),
                    {:ok, path} <- Access.get_path_by_id(result.id),
                    do: {:ok, path}
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the path"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, _result} <- Characteristic.update_values(result, changeset),
                    {:ok, path} <- Access.get_path_by_id(result.id),
                    do: {:ok, path}
             end)
    end

    update :relate do
      description "relates the path with other instances"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, _path} <- Relationship.relate_instance(result, changeset),
                    {:ok, path} <- Access.get_path_by_id(result.id),
                    do: {:ok, path}
             end)
    end
  end
end
