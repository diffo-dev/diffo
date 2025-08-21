defmodule Diffo.Access.DslAccessTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider
  alias Diffo.Provider.Specification
  alias Diffo.Access
  #alias Diffo.Access.AggregateInterface
  #alias Diffo.Access.Circuit
  #alias Diffo.Access.Dslam
  #alias Diffo.Access.Line
  #alias Diffo.Access.BandwidthProfile
  #alias Diffo.Access.DslAccess.Instance, as: DslAccess


  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      :ok #AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "service qualification" do
    @tag debug: true
    test "create an initial service for service qualification" do
      z_end = Provider.create_place!(%{id: "1657363", name: :addressId, href: "place/telstra/1657363", referredType: :GeographicAddress})
      places = [z_end]
      individual =
        Provider.create_party!(%{
          id: "IND000000897354",
          name: :individualId,
          referredType: :Individual
        })
      org =
        Provider.create_party!(%{
          id: "ORG000000123456",
          name: :organizationId,
          referredType: :Organization
        })
      parties = [individual, org]

      {:ok, dsl_access} = Access.qualify_dsl(%{parties: parties, places: places}) |> IO.inspect(label: :qualify_dsl)

      # check specification resource enrichment and node relationship
      refute is_nil(dsl_access.specification_id)
      assert is_struct(dsl_access.specification, Specification)
      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(:Instance, %{uuid: dsl_access.id}, :Specification, %{uuid: dsl_access.specification_id}, :SPECIFIES, :incoming)

      # todo check parties and places are related
    end
  end
end
