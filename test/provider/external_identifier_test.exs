defmodule Diffo.Provider.ExternalIdentifierTest do
  @moduledoc false
  use ExUnit.Case

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Diffo.Provider read ExternalIdentifiers" do
    test "list external identifiers - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      t3_party =
        Diffo.Provider.create_party!(%{
          id: "T3_CONNECTIVITY",
          name: :entityId,
          href: "entity/internal/T3_CONNECTIVITY",
          referredType: :Entity
        })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance.id,
        type: :orderId,
        external_id: "ORD00000123456",
        owner_id: t4_party.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance.id,
        type: :connectionId,
        external_id: "EVC010000873982",
        owner_id: t3_party.id
      })

      external_identifiers = Diffo.Provider.list_external_identifiers!()
      assert length(external_identifiers) == 2
      # should be sorted by most recent first
      assert List.first(external_identifiers).owner_id == "T3_CONNECTIVITY"
      assert List.last(external_identifiers).owner_id == "T4_ACCESS"
    end

    test "find external identifiers by external id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      t3_party =
        Diffo.Provider.create_party!(%{
          id: "T3_CONNECTIVITY",
          name: :entityId,
          href: "entity/internal/T3_CONNECTIVITY",
          referredType: :Entity
        })

      t3_party2 =
        Diffo.Provider.create_party!(%{
          id: "T3_ADAPTIVE_NETWORKS",
          name: :entityId,
          href: "entity/internal/T3_ADAPTIVE_NETWORKS",
          referredType: :Entity
        })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance1.id,
        type: :orderId,
        external_id: "ORD00000123456",
        owner_id: t4_party.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance1.id,
        type: :connectionId,
        external_id: "EVC010000873982",
        owner_id: t3_party.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance1.id,
        type: :siteId,
        external_id: "ANS020000023234",
        owner_id: t3_party2.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance2.id,
        type: :orderId,
        external_id: "ORD00000543543",
        owner_id: t4_party.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance2.id,
        type: :connectionId,
        external_id: "EVC010000343853",
        owner_id: t3_party.id
      })

      external_identifiers = Diffo.Provider.find_external_identifiers_by_external_id!("EVC")
      assert length(external_identifiers) == 2
      # should be sorted by most recent first
      assert List.first(external_identifiers).external_id == "EVC010000343853"
      assert List.last(external_identifiers).external_id == "EVC010000873982"
    end

    test "list external identifiers by related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      t3_party =
        Diffo.Provider.create_party!(%{
          id: "T3_CONNECTIVITY",
          name: :entityId,
          href: "entity/internal/T3_CONNECTIVITY",
          referredType: :Entity
        })

      t3_party2 =
        Diffo.Provider.create_party!(%{
          id: "T3_ADAPTIVE_NETWORKS",
          name: :entityId,
          href: "entity/internal/T3_ADAPTIVE_NETWORKS",
          referredType: :Entity
        })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance1.id,
        type: :orderId,
        external_id: "ORD00000123456",
        owner_id: t4_party.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance1.id,
        type: :connectionId,
        external_id: "EVC010000873982",
        owner_id: t3_party.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance1.id,
        type: :siteId,
        external_id: "ANS020000023234",
        owner_id: t3_party2.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance2.id,
        type: :orderId,
        external_id: "ORD00000543543",
        owner_id: t4_party.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance2.id,
        type: :connectionId,
        external_id: "EVC010000343853",
        owner_id: t3_party.id
      })

      external_identifiers =
        Diffo.Provider.list_external_identifiers_by_instance_id!(instance1.id)

      assert length(external_identifiers) == 3
      # should be sorted
      assert List.first(external_identifiers).owner_id == "T3_ADAPTIVE_NETWORKS"
      assert List.last(external_identifiers).owner_id == "T4_ACCESS"
    end

    test "list external identifiers by related owner id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      t3_party =
        Diffo.Provider.create_party!(%{
          id: "T3_CONNECTIVITY",
          name: :entityId,
          href: "entity/internal/T3_CONNECTIVITY",
          referredType: :Entity
        })

      t3_party2 =
        Diffo.Provider.create_party!(%{
          id: "T3_ADAPTIVE_NETWORKS",
          name: :entityId,
          href: "entity/internal/T3_ADAPTIVE_NETWORKS",
          referredType: :Entity
        })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance1.id,
        type: :orderId,
        external_id: "ORD00000123456",
        owner_id: t4_party.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance1.id,
        type: :connectionId,
        external_id: "EVC010000873982",
        owner_id: t3_party.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance1.id,
        type: :siteId,
        external_id: "ANS020000023234",
        owner_id: t3_party2.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance2.id,
        type: :orderId,
        external_id: "ORD00000543543",
        owner_id: t4_party.id
      })

      Diffo.Provider.create_external_identifier!(%{
        instance_id: instance2.id,
        type: :connectionId,
        external_id: "EVC010000343853",
        owner_id: t3_party.id
      })

      external_identifiers = Diffo.Provider.list_external_identifiers_by_owner_id!(t4_party.id)
      assert length(external_identifiers) == 2
      # should be sorted
      assert List.first(external_identifiers).external_id == "ORD00000543543"
      assert List.last(external_identifiers).external_id == "ORD00000123456"
    end
  end

  describe "Diffo.Provider create ExternalIdentifiers" do
    test "create an external identifier with no external id or owner  - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{instance_id: instance1.id, type: "123"})

      assert external_identifier.type == "123"
    end

    test "create an external identifier with external id and owner  - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance1.id,
          type: :orderId,
          external_id: "ORD00000123465",
          owner_id: t4_party.id
        })

      assert external_identifier.external_id == "ORD00000123465"
    end

    test "create - failure - must have one of type, external id, owner_id" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      {:error, _error} = Diffo.Provider.create_external_identifier(%{instance_id: instance1.id})
    end

    test "create - failure - must have an instance" do
      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      {:error, _error} =
        Diffo.Provider.create_external_identifier(%{
          type: :orderId,
          external_id: "ORD00000123465",
          owner_id: t4_party.id
        })
    end
  end

  describe "Diffo.Provider update ExternalIdentifiers" do
    test "update external_id to nil - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance1.id,
          type: :orderId,
          external_id: "ORD00000123465",
          owner_id: t4_party.id
        })

      updated_external_identifier =
        external_identifier |> Diffo.Provider.update_external_identifier!(%{external_id: nil})

      assert updated_external_identifier.external_id == nil
    end

    test "update external_id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance1.id,
          type: :orderId,
          external_id: "ORD00000123465",
          owner_id: t4_party.id
        })

      updated_external_identifier =
        external_identifier
        |> Diffo.Provider.update_external_identifier!(%{external_id: "ORD00000123456"})

      assert updated_external_identifier.external_id == "ORD00000123456"
    end

    test "update owner_id to nil - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance1.id,
          type: :orderId,
          external_id: "ORD00000123465",
          owner_id: t4_party.id
        })

      updated_external_identifier =
        external_identifier |> Diffo.Provider.update_external_identifier!(%{owner_id: nil})

      assert updated_external_identifier.owner_id == nil
    end

    test "update owner_id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      t3_party =
        Diffo.Provider.create_party!(%{
          id: "T3_CONNECTIVITY",
          name: :entityId,
          href: "entity/internal/T3_CONNECTIVITY",
          referredType: :Entity
        })

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance1.id,
          type: :orderId,
          external_id: "ORD00000123465",
          owner_id: t4_party.id
        })

      updated_external_identifier =
        external_identifier
        |> Diffo.Provider.update_external_identifier!(%{owner_id: t3_party.id})

      assert updated_external_identifier.owner_id == "T3_CONNECTIVITY"
    end

    test "update owner_id - failure - owner doesn't exist" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance1.id,
          type: :orderId,
          external_id: "ORD00000123456",
          owner_id: t4_party.id
        })

      {:error, _error} =
        external_identifier
        |> Diffo.Provider.update_external_identifier(%{owner_id: "T4_VIRTUAL"})
    end

    test "update instance_id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance1.id,
          type: :orderId,
          external_id: "ORD00000123465",
          owner_id: t4_party.id
        })

      updated_external_identifier =
        external_identifier
        |> Diffo.Provider.update_external_identifier!(%{instance_id: instance2.id})

      assert updated_external_identifier.instance_id == instance2.id
    end

    test "update instance_id - failure - instance doesn't exist" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance1.id,
          type: :orderId,
          external_id: "ORD00000123456",
          owner_id: t4_party.id
        })

      {:error, _error} =
        external_identifier
        |> Diffo.Provider.update_external_identifier(%{
          instance_id: "cae0467e-4801-431c-a303-c3c7d5d44a40"
        })
    end

    test "update - failure - must have one of type, external id, owner_id" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance.id,
          type: :orderId,
          external_id: "ORD00000123456"
        })

      {:error, _error} =
        external_identifier
        |> Diffo.Provider.update_external_identifier(%{type: nil, external_id: nil})
    end
  end

  describe "Diffo.Provider encode ExternalIdentifiers" do
    test "encode json with owner - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      t4_party =
        Diffo.Provider.create_party!(%{
          id: "T4_ACCESS",
          name: :entityId,
          href: "entity/internal/T4_ACCESS",
          referredType: :Entity
        })

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance.id,
          type: :orderId,
          external_id: "ORD00000123456",
          owner_id: t4_party.id
        })

      encoding = Jason.encode!(external_identifier)

      assert encoding ==
               "{\"externalIdentifierType\":\"orderId\",\"id\":\"ORD00000123456\",\"owner\":\"T4_ACCESS\"}"
    end

    test "encode json no owner - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance.id,
          type: :orderId,
          external_id: "ORD00000123456"
        })

      encoding = Jason.encode!(external_identifier)
      assert encoding == "{\"externalIdentifierType\":\"orderId\",\"id\":\"ORD00000123456\"}"
    end
  end

  describe "Diffo.Provider outstanding ExternalIdentifiers" do
    use Outstand
    @type_only %Diffo.Provider.ExternalIdentifier{type: "orderId"}
    @external_id_only %Diffo.Provider.ExternalIdentifier{external_id: "ORD000000123456"}
    @owner_id_only %Diffo.Provider.ExternalIdentifier{owner_id: "T4_ACCESS"}
    @specific_external_identifier %Diffo.Provider.ExternalIdentifier{
      type: "orderId",
      external_id: "ORD000000123456",
      owner_id: "T4_ACCESS"
    }
    @generic_external_identifier %Diffo.Provider.ExternalIdentifier{
      type: "orderId",
      external_id: &Diffo.Provider.ExternalIdentifierTest.generic_external_identifier/1,
      owner_id: nil
    }
    @actual_external_identifier %Diffo.Provider.ExternalIdentifier{
      type: "orderId",
      external_id: "ORD000000123456",
      owner_id: "T4_ACCESS"
    }

    gen_nothing_outstanding_test(
      "specific nothing outstanding",
      @specific_external_identifier,
      @actual_external_identifier
    )

    gen_result_outstanding_test(
      "specific external_identifier result",
      @specific_external_identifier,
      nil,
      @specific_external_identifier
    )

    gen_result_outstanding_test(
      "specific type result",
      @specific_external_identifier,
      Map.delete(@actual_external_identifier, :type),
      @type_only
    )

    gen_result_outstanding_test(
      "specific external_id result",
      @specific_external_identifier,
      Map.delete(@actual_external_identifier, :external_id),
      @external_id_only
    )

    gen_result_outstanding_test(
      "specific owner_id result",
      @specific_external_identifier,
      Map.delete(@actual_external_identifier, :owner_id),
      @owner_id_only
    )

    gen_nothing_outstanding_test(
      "generic nothing outstanding",
      @generic_external_identifier,
      @actual_external_identifier
    )
  end

  describe "Diffo.Provider delete ExternalIdentifiers" do
    test "delete external_identifier with related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      external_identifier =
        Diffo.Provider.create_external_identifier!(%{
          instance_id: instance.id,
          type: :orderId,
          external_id: "ORD00000123456"
        })

      :ok = Diffo.Provider.delete_external_identifier(external_identifier)
      {:error, _error} = Diffo.Provider.get_entity_ref_by_id(external_identifier.id)
    end
  end

  def generic_external_identifier(actual) do
    cond do
      actual == nil ->
        :generic_external_identifier

      Regex.match(~r/ORD\d{12}/, String.Chars.to_string(actual)) ->
        nil

      true ->
        :generic_external_identifier
    end
  end
end
