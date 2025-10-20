# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Access.Shelf do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Shelf - Shelf Resource Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Specification
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Instance.Feature
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias Diffo.Access
  alias Diffo.Access.Assigner
  alias Diffo.Access.Assignment

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Access

  resource do
    description "An Ash Resource representing a Shelf"
    plural_name :Shelves
  end

  specification do
    id "ef016d85-9dbd-429c-84da-1df56cc7dda5"
    name "shelf"
    type :resourceSpecification
    description "A Shelf Resource Instance which contain cards"
    category "Network Resource"
  end

  characteristics do
    characteristic :shelf, Diffo.Access.ShelfValue
    characteristic :slots, Diffo.Access.AssignableValue
  end

  actions do
    create :build do
      description "creates a new Shelf resource instance for build"
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
                    {:ok, shelf} <- Access.get_shelf_by_id(result.id),
                    do: {:ok, shelf}
             end)

      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the shelf"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, _result} <- Characteristic.update_values(result, changeset),
                    {:ok, card} <- Access.get_shelf_by_id(result.id),
                    do: {:ok, card}
             end)
    end

    update :relate do
      description "relates the shelf with cards"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, _shelf} <- Relationship.relate_instance(result, changeset),
                    {:ok, shelf} <- Access.get_shelf_by_id(result.id),
                    do: {:ok, shelf}
             end)
    end

    update :assign_slot do
      description "relates the shelf with an instance by assigning a slot"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change after_action(fn changeset, result, _context ->
               with {:ok, _card} <- Assigner.assign(result, changeset, :slots, :slot),
                    {:ok, card} <- Access.get_shelf_by_id(result.id),
                    do: {:ok, card}
             end)
    end
  end
end
