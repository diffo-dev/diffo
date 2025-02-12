defmodule Diffo.Provider.EntityTest do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true

  describe "Diffo.Provider read Entities" do
    test "list entities - success" do
      Diffo.Provider.create_entity!(%{id: "11b6ba17-2865-41c5-b469-2939249631e8", href: "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8", referredType: :serviceProblem})
      Diffo.Provider.create_entity!(%{id: "22b85e20-06a9-4e51-baa3-41c2a72958c5", href: "serviceProblemManagement/v4/serviceProblem/nbnAccess/22b85e20-06a9-4e51-baa3-41c2a72958c5", referredType: :serviceProblem})
      Diffo.Provider.create_entity!(%{id: "33db60a1-62bf-4c11-abf3-265287a729c1", href: "serviceProblemManagement/v4/serviceProblem/nbnAccess/33db60a1-62bf-4c11-abf3-265287a729c1", referredType: :serviceProblem})
      entities = Diffo.Provider.list_entities!()
      assert length(entities) == 3
      # should be sorted
      assert List.first(entities).id == "11b6ba17-2865-41c5-b469-2939249631e8"
      assert List.last(entities).id == "33db60a1-62bf-4c11-abf3-265287a729c1"
    end

    test "find entities by name - success" do
      Diffo.Provider.create_entity!(%{id: "COR000000123456", referredType: :cost, name: "2025-01"})
      Diffo.Provider.create_entity!(%{id: "22b85e20-06a9-4e51-baa3-41c2a72958c5", href: "serviceProblemManagement/v4/serviceProblem/nbnAccess/22b85e20-06a9-4e51-baa3-41c2a72958c5", referredType: :serviceProblem})
      Diffo.Provider.create_entity!(%{id: "COR000000767342", referredType: :cost, name: "2025-01"})
      entities = Diffo.Provider.find_entities_by_name!("2025-01")
      assert length(entities) == 2
      # should be sorted
      assert List.first(entities).id == "COR000000123456"
      assert List.last(entities).id == "COR000000767342"
    end
  end

  describe "Diffo.Provider create Entities" do
    test "create a service problem referredType entity  - success" do
      entity = Diffo.Provider.create_entity!(%{id: "11b6ba17-2865-41c5-b469-2939249631e8", href: "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8", referredType: :serviceProblem})
      assert entity.type == :EntityRef
    end

    test "create a cost referredType entity - success" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000123456", referredType: :cost, name: "2025-01"})
      assert entity.type == :EntityRef
    end

    test "create a service problem type entity  - success" do
      entity = Diffo.Provider.create_entity!(%{id: "11b6ba17-2865-41c5-b469-2939249631e8", href: "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8", type: :serviceProblem})
      assert entity.referredType == nil
    end

    test "create a cost type entity - success" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000123456", type: :cost, name: "2025-01"})
      assert entity.referredType == nil
    end
  end

  describe "Diffo.Provider update Entities" do

    test "update href - success" do
      entity = Diffo.Provider.create_entity!(%{id: "11b6ba17-2865-41c5-b469-2939249631e8", referredType: :serviceProblem})
      updated_entity = entity |> Diffo.Provider.update_entity!(%{href: "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8"})
      assert updated_entity.href == "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8"
    end

    test "update entity name - success" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000123456", referredType: :cost, name: "2025-01"})
      updated_entity = entity |> Diffo.Provider.update_entity!(%{name: "2025-02"})
      assert updated_entity.name == "2025-02"
    end

    test "update entity type - success" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000123456", type: :cost, name: "2025-01"})
      updated_entity = entity |> Diffo.Provider.update_entity!(%{type: :sla})
      assert updated_entity.type == :sla
    end

    test "update entity referredType - success" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000123456", referredType: :cost, name: "2025-01"})
      updated_entity = entity |> Diffo.Provider.update_entity!(%{referredType: :sla})
      assert updated_entity.referredType == :sla
    end

    test "update entity type to referredType - success" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000123456", type: :cost, name: "2025-01"})
      updated_entity = entity |> Diffo.Provider.update_entity!(%{type: :EntityRef, referredType: :cost})
      assert updated_entity.type == :EntityRef
      assert updated_entity.referredType == :cost
    end

    test "update entity referredType to type - success" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000123456", referredType: :cost, name: "2025-01"})
      updated_entity = entity |> Diffo.Provider.update_entity!(%{type: :cost, referredType: nil})
      assert updated_entity.type == :cost
      assert updated_entity.referredType == :nil
    end

    test "update id - failure - href does not end with id" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000897353", referredType: :cost, name: "2025-01"})
      {:error, _error} = entity |> Diffo.Provider.update_entity(%{href: "entity/nbnco/COR000000897354"})
    end

    test "update referredType - failure - type Party cannot have referredType" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000897353", type: :cost, name: "2025-01"})
      {:error, _error} = entity |> Diffo.Provider.update_entity(%{referredType: :cost})
    end

    test "update referredType - failure - EntityRef requires referredType" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000897353", type: :EntityRef, referredType: :cost, name: "2025-01"})
      {:error, _error} = entity |> Diffo.Provider.update_entity(%{referredType: :nil})
    end

    test "update id - failure - not updatable" do
      entity = Diffo.Provider.create_entity!(%{id: "COR000000897353", type: :cost})
      {:error, _error} = entity |> Diffo.Provider.update_entity(%{id: "COR0000008973534"})
    end
  end

  test "encode json entity type - success" do
    entity = Diffo.Provider.create_entity!(%{id: "11b6ba17-2865-41c5-b469-2939249631e8", href: "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8", type: :serviceProblem})
    refreshed_entity = Diffo.Provider.get_entity_by_id!(entity.id)
    encoding = Jason.encode!(refreshed_entity)
    assert encoding == "{\"id\":\"11b6ba17-2865-41c5-b469-2939249631e8\",\"href\":\"serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8\",\"@type\":\"serviceProblem\"}"
  end

  test "encode json entity referredType - success" do
    entity = Diffo.Provider.create_entity!(%{id: "COR000000123456", referredType: :cost, name: "2025-01"})
    refreshed_entity = Diffo.Provider.get_entity_by_id!(entity.id)
    encoding = Jason.encode!(refreshed_entity)
    assert encoding == "{\"id\":\"COR000000123456\",\"name\":\"2025-01\",\"@referredType\":\"cost\",\"@type\":\"EntityRef\"}"
  end

  describe "Diffo.Provider delete Entities" do
    test "bulk delete" do
      Diffo.Provider.delete_entity!(Diffo.Provider.list_entities!())
    end
  end
end
