# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Instance.ShelfInstance do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Shelf - Shelf Resource Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Provider.Extension.Characteristic
  alias Diffo.Provider.Assigner
  alias Diffo.Provider.Assignment
  alias Diffo.Provider.AssignableValue
  alias Diffo.Test.Servo
  alias Diffo.Test.Characteristic.ShelfCharacteristic
  alias Diffo.Test.Characteristic.DeploymentClass
  alias Diffo.Test.Party.Organization
  alias Diffo.Test.Party.Person

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Servo

  resource do
    description "An Ash Resource representing a Shelf"
    plural_name :Shelves
  end

  provider do
    specification do
      id "ef016d85-9dbd-429c-84da-1df56cc7dda5"
      name "shelf"
      type :resourceSpecification
      major_version 1
      minor_version 2
      patch_version 3
      tmf_version 4
      description "A Shelf Resource Instance which contain cards"
      category "Network Resource"
    end

    features do
      feature :spectralManagement do
        is_enabled? true
        characteristic :deploymentClass, DeploymentClass
        characteristic :deploymentClasses, {:array, DeploymentClass}
      end
    end

    characteristics do
      characteristic :shelf, ShelfCharacteristic
      characteristic :slots, AssignableValue
      characteristic :shelves, {:array, ShelfCharacteristic}
    end

    parties do
      party :facilitator, Organization
      party :overseer, Person
      party_ref :provider, Organization
      party :manager, Organization, calculate: :manager_calc
      parties :installer, Person, constraints: [min: 1, max: 3]
    end

    places do
      place :installation_site, Diffo.Provider.Place
      place_ref :billing_address, Diffo.Provider.Place
    end

    behaviour do
      actions do
        create :build
      end
    end
  end

  actions do
    create :build do
      description "creates a new Shelf resource instance for build"
      accept [:id, :name, :type, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the shelf"
      argument :characteristic_value_updates, {:array, :term}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <-
                      Characteristic.update_all(result, changeset, characteristics()),
                    {:ok, result} <- Servo.get_shelf_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :relate do
      description "relates the shelf with cards"
      argument :relationships, {:array, :struct}

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Relationship.relate_instance(result, changeset),
                    {:ok, result} <- Servo.get_shelf_by_id(result.id),
                    do: {:ok, result}
             end)
    end

    update :assign_slot do
      description "relates the shelf with an instance by assigning a slot"
      argument :assignment, :struct, constraints: [instance_of: Assignment]

      change after_action(fn changeset, result, _context ->
               with {:ok, result} <- Assigner.assign(result, changeset, :slots, :slot),
                    {:ok, result} <- Servo.get_shelf_by_id(result.id),
                    do: {:ok, result}
             end)
    end
  end
end
