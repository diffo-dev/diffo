defmodule Diffo.Provider.EntityRefTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider.Entity
  alias Diffo.Provider.EntityRef
  alias Diffo.Provider.Instance

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
      check_entity_ref(hd(entity_refs), instance, entity3)
      check_entity_ref(hd(tl(entity_refs)), instance, entity2)
      check_entity_ref(List.last(entity_refs), instance, entity1)
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
      assert hd(entity_refs).entity_id == "33db60a1-62bf-4c11-abf3-265287a729c1"
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

      check_entity_ref(hd(entity_refs), instance2, entity2)
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
        |> IO.inspect(label: :created)
        |> check_entity_ref(instance, entity)

      assert entity_ref.role == :reportedOn

      # re-read
      EntityRef
      |> Ash.read_one!()
      |> check_entity_ref(instance, entity)

      # reload
      entity_ref
      |> Ash.reload!()
      |> check_entity_ref(instance, entity)
    end
  end

  defp check_entity_ref(entity_ref, instance, entity) do
    # check inputs
    assert is_struct(instance, Instance)
    assert is_struct(entity_ref, EntityRef)
    assert is_struct(entity, Entity)

    # check EntityRef enrichment
    assert entity_ref.instance_id == instance.id
    assert is_struct(entity_ref.instance, Instance)
    assert entity_ref.instance.id == instance.id
    assert entity_ref.entity_id == entity.id
    assert is_struct(entity_ref.entity, Entity)
    assert entity_ref.entity.id == entity.id

    # check EntityRef calculations
    assert entity_ref.href == entity.href
    assert entity_ref.name == entity.name
    assert entity_ref.referredType == entity.referredType
    assert entity_ref.type == entity.type

    entity_ref
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
    @entity_id_only %Diffo.Provider.EntityRef{entity_id: "COR000000123456"}
    @href_only %Diffo.Provider.EntityRef{href: "costManagement/v2/cost/COR000000123456"}
    @name_only %Diffo.Provider.EntityRef{name: "2025-01"}
    @role_only %Diffo.Provider.EntityRef{role: "expected"}
    @referredType_only %Diffo.Provider.EntityRef{referredType: "cost"}
    @type_only %Diffo.Provider.EntityRef{type: "EntityRef"}
    @specific_cost %Diffo.Provider.EntityRef{
      entity_id: "COR000000123456",
      href: "costManagement/v2/cost/COR000000123456",
      name: "2025-01",
      role: "expected",
      referredType: "cost",
      type: "EntityRef"
    }
    @generic_cost %Diffo.Provider.EntityRef{
      entity_id: &__MODULE__.generic_cost_id/1,
      href: nil,
      name: &Outstand.any_bitstring/1,
      role: {&Outstand.any_of/2, ["expected", "actual"]},
      referredType: "cost",
      type: nil
    }
    @actual_cost %Diffo.Provider.EntityRef{
      entity_id: "COR000000123456",
      href: "costManagement/v2/cost/COR000000123456",
      name: "2025-01",
      role: "expected",
      referredType: "cost",
      type: "EntityRef"
    }

    gen_nothing_outstanding_test("specific nothing outstanding", @specific_cost, @actual_cost)
    gen_result_outstanding_test("specific cost result", @specific_cost, nil, @specific_cost)

    gen_result_outstanding_test(
      "specific entity_id result",
      @specific_cost,
      Map.delete(@actual_cost, :entity_id),
      @entity_id_only
    )

    gen_result_outstanding_test(
      "specific href result",
      @specific_cost,
      Map.delete(@actual_cost, :href),
      @href_only
    )

    gen_result_outstanding_test(
      "specific name result",
      @specific_cost,
      Map.delete(@actual_cost, :name),
      @name_only
    )

    gen_result_outstanding_test(
      "specific role result",
      @specific_cost,
      Map.delete(@actual_cost, :role),
      @role_only
    )

    gen_result_outstanding_test(
      "specific referredType result",
      @specific_cost,
      Map.delete(@actual_cost, :referredType),
      @referredType_only
    )

    gen_result_outstanding_test(
      "specific type result",
      @specific_cost,
      Map.delete(@actual_cost, :type),
      @type_only
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
end
