# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.EntityTest do
  @moduledoc false
  use ExUnit.Case
  use Outstand

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "Diffo.Provider read Entities" do
    test "list entities - success" do
      Diffo.Provider.create_entity!(%{
        id: "11b6ba17-2865-41c5-b469-2939249631e8",
        href:
          "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
        referred_type: :serviceProblem
      })

      Diffo.Provider.create_entity!(%{
        id: "22b85e20-06a9-4e51-baa3-41c2a72958c5",
        href:
          "serviceProblemManagement/v4/serviceProblem/nbnAccess/22b85e20-06a9-4e51-baa3-41c2a72958c5",
        referred_type: :serviceProblem
      })

      Diffo.Provider.create_entity!(%{
        id: "33db60a1-62bf-4c11-abf3-265287a729c1",
        href:
          "serviceProblemManagement/v4/serviceProblem/nbnAccess/33db60a1-62bf-4c11-abf3-265287a729c1",
        referred_type: :serviceProblem
      })

      entities = Diffo.Provider.list_entities!()
      assert length(entities) == 3
      # should be sorted
      assert List.first(entities).id == "11b6ba17-2865-41c5-b469-2939249631e8"
      assert List.last(entities).id == "33db60a1-62bf-4c11-abf3-265287a729c1"
    end

    test "find entities by id - success" do
      Diffo.Provider.create_entity!(%{
        id: "COR000000123456",
        referred_type: :cost,
        name: "2025-01"
      })

      Diffo.Provider.create_entity!(%{
        id: "22b85e20-06a9-4e51-baa3-41c2a72958c5",
        href:
          "serviceProblemManagement/v4/serviceProblem/nbnAccess/22b85e20-06a9-4e51-baa3-41c2a72958c5",
        referred_type: :serviceProblem
      })

      Diffo.Provider.create_entity!(%{
        id: "COR000000767342",
        referred_type: :cost,
        name: "2025-01"
      })

      entities = Diffo.Provider.find_entities_by_id!("COR")
      assert length(entities) == 2
      # should be sorted
      assert List.first(entities).id == "COR000000123456"
      assert List.last(entities).id == "COR000000767342"
    end

    test "find entities by name - success" do
      Diffo.Provider.create_entity!(%{
        id: "COR000000123456",
        referred_type: :cost,
        name: "2025-01"
      })

      Diffo.Provider.create_entity!(%{
        id: "22b85e20-06a9-4e51-baa3-41c2a72958c5",
        href:
          "serviceProblemManagement/v4/serviceProblem/nbnAccess/22b85e20-06a9-4e51-baa3-41c2a72958c5",
        referred_type: :serviceProblem
      })

      Diffo.Provider.create_entity!(%{
        id: "COR000000767342",
        referred_type: :cost,
        name: "2025-01"
      })

      entities = Diffo.Provider.find_entities_by_name!("2025-01")
      assert length(entities) == 2
      # should be sorted
      assert List.first(entities).id == "COR000000123456"
      assert List.last(entities).id == "COR000000767342"
    end
  end

  describe "Diffo.Provider create Entities" do
    test "create a service problem referred_type entity  - success" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
          referred_type: :serviceProblem
        })

      assert entity.type == :EntityRef
    end

    test "create a cost referred_type entity - success" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referred_type: :cost,
          name: "2025-01"
        })

      assert entity.type == :EntityRef
    end

    test "create a service problem type entity  - success" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
          type: :serviceProblem
        })

      assert entity.referred_type == nil
    end

    test "create a cost type entity - success" do
      entity =
        Diffo.Provider.create_entity!(%{id: "COR000000123456", type: :cost, name: "2025-01"})

      assert entity.referred_type == nil
    end

    test "create an Entity that already exists, preserving attributes - success" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
          type: :serviceProblem
        })

      Diffo.Provider.create_entity!(%{
        id: "11b6ba17-2865-41c5-b469-2939249631e8",
        type: :serviceProblem
      })

      refreshed_entity = Diffo.Provider.get_entity_by_id!(entity.id)

      assert refreshed_entity.href ==
               "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8"
    end

    test "create an Entity that already exists, adding attributes - success" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          type: :serviceProblem
        })

      Diffo.Provider.create_entity!(%{
        id: "11b6ba17-2865-41c5-b469-2939249631e8",
        href:
          "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
        type: :serviceProblem
      })

      refreshed_entity = Diffo.Provider.get_entity_by_id!(entity.id)

      assert refreshed_entity.href ==
               "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8"
    end
  end

  describe "Diffo.Provider update Entities" do
    test "update href - success" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          referred_type: :serviceProblem
        })

      updated_entity =
        entity
        |> Diffo.Provider.update_entity!(%{
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8"
        })

      assert updated_entity.href ==
               "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8"
    end

    test "update entity name - success" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referred_type: :cost,
          name: "2025-01"
        })

      updated_entity = entity |> Diffo.Provider.update_entity!(%{name: "2025-02"})
      assert updated_entity.name == "2025-02"
    end

    test "update entity type - success" do
      entity =
        Diffo.Provider.create_entity!(%{id: "COR000000123456", type: :cost, name: "2025-01"})

      updated_entity = entity |> Diffo.Provider.update_entity!(%{type: :sla})
      assert updated_entity.type == :sla
    end

    test "update entity referred_type - success" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referred_type: :cost,
          name: "2025-01"
        })

      updated_entity = entity |> Diffo.Provider.update_entity!(%{referred_type: :sla})
      assert updated_entity.referred_type == :sla
    end

    test "update entity type to referred_type - success" do
      entity =
        Diffo.Provider.create_entity!(%{id: "COR000000123456", type: :cost, name: "2025-01"})

      updated_entity =
        entity |> Diffo.Provider.update_entity!(%{type: :EntityRef, referred_type: :cost})

      assert updated_entity.type == :EntityRef
      assert updated_entity.referred_type == :cost
    end

    test "update entity referred_type to type - success" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referred_type: :cost,
          name: "2025-01"
        })

      updated_entity = entity |> Diffo.Provider.update_entity!(%{type: :cost, referred_type: nil})
      assert updated_entity.type == :cost
      assert updated_entity.referred_type == nil
    end

    test "update id - failure - href does not end with id" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000897353",
          referred_type: :cost,
          name: "2025-01"
        })

      {:error, _error} =
        entity |> Diffo.Provider.update_entity(%{href: "entity/nbnco/COR000000897354"})
    end

    test "update referred_type - failure - type Party cannot have referred_type" do
      entity =
        Diffo.Provider.create_entity!(%{id: "COR000000897353", type: :cost, name: "2025-01"})

      {:error, _error} = entity |> Diffo.Provider.update_entity(%{referred_type: :cost})
    end

    test "update referred_type - failure - EntityRef requires referred_type" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000897353",
          type: :EntityRef,
          referred_type: :cost,
          name: "2025-01"
        })

      {:error, _error} = entity |> Diffo.Provider.update_entity(%{referred_type: nil})
    end

    test "update id - failure - not updatable" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000897353", type: :cost})
      {:error, _error} = entity |> Diffo.Provider.update_entity(%{id: "COR0000008973534"})
    end
  end

  test "encode json entity type - success" do
    entity =
      Diffo.Provider.create_entity!(%{
        id: "11b6ba17-2865-41c5-b469-2939249631e8",
        href:
          "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
        type: :serviceProblem
      })

    refreshed_entity = Diffo.Provider.get_entity_by_id!(entity.id)
    encoding = Jason.encode!(refreshed_entity)

    assert encoding ==
             "{\"id\":\"11b6ba17-2865-41c5-b469-2939249631e8\",\"href\":\"serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8\",\"@type\":\"serviceProblem\"}"
  end

  test "encode json entity referred_type - success" do
    entity =
      Diffo.Provider.create_entity!(%{
        id: "COR000000123456",
        referred_type: :cost,
        name: "2025-01"
      })

    refreshed_entity = Diffo.Provider.get_entity_by_id!(entity.id)
    encoding = Jason.encode!(refreshed_entity)

    assert encoding ==
             "{\"id\":\"COR000000123456\",\"name\":\"2025-01\",\"@referredType\":\"cost\",\"@type\":\"EntityRef\"}"
  end

  describe "Diffo.Provider outstanding Entities" do
    test "resolve a general expected entity" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          name: "2025-01",
          href: "costManagement/v2/cost/COR000000123456",
          type: :EntityRef,
          referred_type: :cost
        })

      expected_entity = %Diffo.Provider.Entity{
        id: ~r/COR\d{12}/,
        name: ~r/\d{4}-\d{2}/,
        type: :EntityRef,
        referred_type: :cost
      }

      refute expected_entity >>> entity
    end
  end

  describe "Diffo.Provider delete Entities" do
    test "delete entity - success" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referred_type: :cost,
          name: "2025-01"
        })

      :ok = Diffo.Provider.delete_entity(entity)
      {:error, _error} = Diffo.Provider.get_entity_by_id(entity.id)
    end

    test "delete entity - failure, related entity_ref" do
      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referred_type: :cost,
          name: "2025-01"
        })

      specification = Diffo.Provider.create_specification!(%{name: "copperAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity_ref =
        Diffo.Provider.create_entity_ref!(%{
          instance_id: instance.id,
          role: :reportedOn,
          entity_id: entity.id
        })

      {:error, _error} =
        Diffo.Provider.delete_entity(entity)

      # now delete the entity_ref and we should be able to delete the entity
      Diffo.Provider.delete_entity_ref!(entity_ref)
      Diffo.Provider.delete_entity!(entity)
    end
  end
end
