defmodule Diffo.Provider.EntityRefTest do
  @moduledoc false
  use ExUnit.Case
  use Outstand
  alias Diffo.Provider.Entity
  alias Diffo.Provider.EntityRef

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Diffo.Provider read EntityRefs" do
    test "list entity refs - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity1 =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
          referredType: :serviceProblem
        })

      entity2 =
        Diffo.Provider.create_entity!(%{
          id: "22b85e20-06a9-4e51-baa3-41c2a72958c5",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/22b85e20-06a9-4e51-baa3-41c2a72958c5",
          referredType: :serviceProblem
        })

      entity3 =
        Diffo.Provider.create_entity!(%{
          id: "33db60a1-62bf-4c11-abf3-265287a729c1",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/33db60a1-62bf-4c11-abf3-265287a729c1",
          referredType: :serviceProblem
        })

      Diffo.Provider.create_entity_ref!(%{
        instance_id: instance.id,
        role: :reportedOn,
        entity_id: entity1.id
      })

      Diffo.Provider.create_entity_ref!(%{
        instance_id: instance.id,
        role: :reportedOn,
        entity_id: entity2.id
      })

      Diffo.Provider.create_entity_ref!(%{
        instance_id: instance.id,
        role: :reportedOn,
        entity_id: entity3.id
      })

      entity_refs = Diffo.Provider.list_entity_refs!()
      assert length(entity_refs) == 3
      # should be sorted newest to oldest and enriched
      check_entity_ref(hd(entity_refs), entity3)
      check_entity_ref(hd(tl(entity_refs)), entity2)
      check_entity_ref(List.last(entity_refs), entity1)
    end

    test "list entity refs by related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity1 =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
          referredType: :serviceProblem
        })

      entity2 =
        Diffo.Provider.create_entity!(%{
          id: "22b85e20-06a9-4e51-baa3-41c2a72958c5",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/22b85e20-06a9-4e51-baa3-41c2a72958c5",
          referredType: :serviceProblem
        })

      entity3 =
        Diffo.Provider.create_entity!(%{
          id: "33db60a1-62bf-4c11-abf3-265287a729c1",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/33db60a1-62bf-4c11-abf3-265287a729c1",
          referredType: :serviceProblem
        })

      Diffo.Provider.create_entity_ref!(%{
        instance_id: instance1.id,
        role: :reportedOn,
        entity_id: entity1.id
      })

      Diffo.Provider.create_entity_ref!(%{
        instance_id: instance2.id,
        role: :reportedOn,
        entity_id: entity2.id
      })

      Diffo.Provider.create_entity_ref!(%{
        instance_id: instance1.id,
        role: :reportedOn,
        entity_id: entity3.id
      })

      entity_refs = Diffo.Provider.list_entity_refs_by_instance_id!(instance1.id)
      assert length(entity_refs) == 2
      # should be sorted newest entity ref to oldest
      Enum.each(entity_refs, fn entity_ref -> assert entity_ref.instance_id == instance1.id end)
    end

    test "list entity refs by related entity id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity1 =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
          referredType: :serviceProblem
        })

      entity2 =
        Diffo.Provider.create_entity!(%{
          id: "22b85e20-06a9-4e51-baa3-41c2a72958c5",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/22b85e20-06a9-4e51-baa3-41c2a72958c5",
          referredType: :serviceProblem
        })

      entity3 =
        Diffo.Provider.create_entity!(%{
          id: "33db60a1-62bf-4c11-abf3-265287a729c1",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/33db60a1-62bf-4c11-abf3-265287a729c1",
          referredType: :serviceProblem
        })

      Diffo.Provider.create_entity_ref!(%{
        instance_id: instance1.id,
        role: :reportedOn,
        entity_id: entity1.id
      })

      Diffo.Provider.create_entity_ref!(%{
        instance_id: instance2.id,
        role: :reportedOn,
        entity_id: entity2.id
      })

      Diffo.Provider.create_entity_ref!(%{
        instance_id: instance1.id,
        role: :reportedOn,
        entity_id: entity3.id
      })

      entity_refs =
        Diffo.Provider.list_entity_refs_by_entity_id!(entity2.id)

      assert length(entity_refs) == 1

      check_entity_ref(hd(entity_refs), entity2)
    end
  end

  describe "Diffo.Provider create EntityRefs" do
    test "create a reportedOn role entity ref  - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
          referredType: :serviceProblem
        })

      entity_ref =
        Diffo.Provider.create_entity_ref!(%{
          instance_id: instance.id,
          role: :reportedOn,
          entity_id: entity.id
        })

      assert entity_ref.role == :reportedOn
      check_entity_ref(entity_ref, entity)

      # re-read
      EntityRef
      |> Ash.read_one!()
      |> check_entity_ref(entity)

      # reload
      entity_ref
      |> Ash.reload!()
      |> check_entity_ref(entity)
    end
  end

  defp check_entity_ref(entity_ref, entity) do
    # check inputs
    assert is_struct(entity_ref, EntityRef)
    assert is_struct(entity, Entity)

    # check EntityRef enrichment of Entity
    assert entity_ref.entity_id == entity.id
    assert is_struct(entity_ref.entity, Entity)
    assert entity_ref.entity.id == entity.id
  end

  describe "Diffo.Provider update EntityRefs" do
    test "update role to nil - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
          referredType: :serviceProblem
        })

      entity_ref =
        Diffo.Provider.create_entity_ref!(%{
          instance_id: instance.id,
          role: :reportedOn,
          entity_id: entity.id
        })

      updated_entity_ref = entity_ref |> Diffo.Provider.update_entity_ref!(%{role: nil})
      assert updated_entity_ref.role == nil
    end

    test "update role - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
          referredType: :serviceProblem
        })

      entity_ref =
        Diffo.Provider.create_entity_ref!(%{
          instance_id: instance.id,
          role: :reportedOn,
          entity_id: entity.id
        })

      updated_entity_ref = entity_ref |> Diffo.Provider.update_entity_ref!(%{role: :historic})
      assert updated_entity_ref.role == :historic
    end

    test "update id - failure - not updatable" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referredType: :cost,
          name: "2025-01"
        })

      entity_ref =
        Diffo.Provider.create_entity_ref!(%{
          instance_id: instance.id,
          role: :expected,
          entity_id: entity.id
        })

      {:error, _error} = entity_ref |> Diffo.Provider.update_entity_ref(%{id: "CON000000123456"})
    end

    test "update instance_id - failure - not updatable" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      other_instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referredType: :cost,
          name: "2025-01"
        })

      entity_ref =
        Diffo.Provider.create_entity_ref!(%{
          instance_id: instance.id,
          role: :expected,
          entity_id: entity.id
        })

      {:error, _error} =
        entity_ref |> Diffo.Provider.update_entity_ref(%{instance_id: other_instance.id})
    end

    test "update entity_id - failure - not updatable" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referredType: :cost,
          name: "2025-01"
        })

      entity_ref =
        Diffo.Provider.create_entity_ref!(%{
          instance_id: instance.id,
          role: :expected,
          entity_id: entity.id
        })

      other_entity = Diffo.Provider.create_entity!(%{id: "COR000000767342", referredType: :cost})

      {:error, _error} =
        entity_ref |> Diffo.Provider.update_entity_ref(%{entity_id: other_entity.id})
    end
  end

  describe "Diffo.Provider encode EntityRefs" do
    test "encode json entity ref type - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity =
        Diffo.Provider.create_entity!(%{
          id: "11b6ba17-2865-41c5-b469-2939249631e8",
          href:
            "serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8",
          type: :serviceProblem
        })

      entity_ref =
        Diffo.Provider.create_entity_ref!(%{
          instance_id: instance.id,
          role: :reportedOn,
          entity_id: entity.id
        })

      refreshed_entity_ref = Diffo.Provider.get_entity_ref_by_id!(entity_ref.id)
      encoding = Jason.encode!(refreshed_entity_ref)

      assert encoding ==
               "{\"id\":\"11b6ba17-2865-41c5-b469-2939249631e8\",\"href\":\"serviceProblemManagement/v4/serviceProblem/nbnAccess/11b6ba17-2865-41c5-b469-2939249631e8\",\"role\":\"reportedOn\",\"@type\":\"serviceProblem\"}"
    end

    test "encode json entity ref referredType - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referredType: :cost,
          name: "2025-01"
        })

      entity_ref =
        Diffo.Provider.create_entity_ref!(%{
          instance_id: instance.id,
          role: :expected,
          entity_id: entity.id
        })

      refreshed_entity_ref = Diffo.Provider.get_entity_ref_by_id!(entity_ref.id)
      encoding = Jason.encode!(refreshed_entity_ref)

      assert encoding ==
               "{\"id\":\"COR000000123456\",\"name\":\"2025-01\",\"role\":\"expected\",\"@referredType\":\"cost\",\"@type\":\"EntityRef\"}"
    end
  end

  describe "Diffo.Provider outstanding EntityRefs" do
    use Outstand
    @role_only %EntityRef{role: :expected}
    @entity_only %EntityRef{
      entity: %Entity{
        id: "COR000000123456",
        href: "costManagement/v2/cost/COR000000123456",
        name: "2025-01",
        referredType: :cost,
        type: :EntityRef
      }
    }
    @id_only %EntityRef{entity: %Entity{id: "COR000000123456"}}
    @href_only %EntityRef{entity: %Entity{href: "costManagement/v2/cost/COR000000123456"}}
    @name_only %EntityRef{entity: %Entity{name: "2025-01"}}
    @referredType_only %EntityRef{entity: %Entity{referredType: :cost}}
    @type_only %EntityRef{entity: %Entity{type: :EntityRef}}
    @specific_cost %EntityRef{
      role: :expected,
      entity: %Entity{
        id: "COR000000123456",
        href: "costManagement/v2/cost/COR000000123456",
        name: "2025-01",
        referredType: :cost,
        type: :EntityRef
      }
    }
    @generic_cost %EntityRef{
      role: {&Outstand.any_of/2, [:expected, :actual]},
      entity: %Entity{
        id: &__MODULE__.generic_cost_id/1,
        href: nil,
        name: &Outstand.any_bitstring/1,
        referredType: :cost,
        type: :EntityRef
      }
    }
    @actual_cost %EntityRef{
      role: :expected,
      entity: %Entity{
        id: "COR000000123456",
        href: "costManagement/v2/cost/COR000000123456",
        name: "2025-01",
        referredType: :cost,
        type: :EntityRef
      }
    }

    gen_nothing_outstanding_test("specific nothing outstanding", @specific_cost, @actual_cost)

    gen_result_outstanding_test(
      "specific cost result",
      @specific_cost,
      nil,
      Ash.Test.strip_metadata(@specific_cost)
    )

    gen_result_outstanding_test(
      "specific role result",
      @specific_cost,
      Map.delete(@actual_cost, :role),
      Ash.Test.strip_metadata(@role_only)
    )

    gen_result_outstanding_test(
      "specific entity result",
      @specific_cost,
      Map.delete(@actual_cost, :entity),
      Ash.Test.strip_metadata(@entity_only)
    )

    gen_result_outstanding_test(
      "specific id result",
      @specific_cost,
      update_in(@actual_cost.entity.id, fn _ -> nil end),
      Ash.Test.strip_metadata(@id_only)
    )

    gen_result_outstanding_test(
      "specific href result",
      @specific_cost,
      update_in(@actual_cost.entity.href, fn _ -> nil end),
      Ash.Test.strip_metadata(@href_only)
    )

    gen_result_outstanding_test(
      "specific name result",
      @specific_cost,
      update_in(@actual_cost.entity.name, fn _ -> nil end),
      Ash.Test.strip_metadata(@name_only)
    )

    gen_result_outstanding_test(
      "specific referredType result",
      @specific_cost,
      update_in(@actual_cost.entity.referredType, fn _ -> nil end),
      Ash.Test.strip_metadata(@referredType_only)
    )

    gen_result_outstanding_test(
      "specific type result",
      @specific_cost,
      update_in(@actual_cost.entity.type, fn _ -> nil end),
      Ash.Test.strip_metadata(@type_only)
    )

    gen_nothing_outstanding_test("generic nothing outstanding", @generic_cost, @actual_cost)
  end

  describe "Diffo.Provider delete EntityRefs" do
    test "delete entity_ref with related instance and entity - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      entity =
        Diffo.Provider.create_entity!(%{
          id: "COR000000123456",
          referredType: :cost,
          name: "2025-01"
        })

      entity_ref =
        Diffo.Provider.create_entity_ref!(%{
          instance_id: instance.id,
          role: :expected,
          entity_id: entity.id
        })

      :ok = Diffo.Provider.delete_entity_ref(entity_ref)
      {:error, _error} = Diffo.Provider.get_entity_ref_by_id(entity_ref.id)
    end
  end

  def generic_cost_id(actual) do
    cond do
      actual == nil ->
        :generic_cost_id

      Regex.match?(~r/COR\d{12}/, String.Chars.to_string(actual)) ->
        nil

      true ->
        :generic_cost_id
    end
  end

  def update_map_value_in_map(map, map_key, value_key, value) do
    updated_value_map = Map.fetch!(map, map_key) |> Map.put(value_key, value)
    map |> Map.put(:map_key, updated_value_map)
  end
end
