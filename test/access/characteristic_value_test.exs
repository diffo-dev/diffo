defmodule Diffo.Access.CharacteristicValueTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider.Characteristic
  alias Diffo.Access.AggregateInterface
  alias Diffo.Access.Circuit
  alias Diffo.Access.Dslam
  alias Diffo.Access.Line
  alias Diffo.Access.BandwidthProfile

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  @dslam "QDONC0001"
  @technology :eth
  @svlan_id 3108
  @cvlan_id 82
  @circuit_id "#{@dslam} #{@technology} #{@svlan_id}:#{@cvlan_id}"

  describe "Diffo.Access create Characteristics" do
    @tag debug: true
    test "create characteristics" do
      dslam_value = Dslam.new!(%{name: @dslam, family: :ISAM, model: "ISAM7330", technology: @technology})

      dslam = Diffo.Provider.create_characteristic!(%{
        name: :dslam,
        value: dslam_value,
        type: :instance
      })

      encoding = Jason.encode!(dslam)
      assert encoding ==
               ~s({\"name\":\"dslam\",\"value\":{\"name\":\"#{@dslam}\",\"family\":\"ISAM\",\"model\":\"ISAM7330\",\"technology\":\"eth\"}})

      bandwidth_profile = BandwidthProfile.new!(%{downstream: 24, upstream: 1}) |> IO.inspect()
      to_string(bandwidth_profile) |> IO.puts()
      encoding = Jason.encode!(bandwidth_profile)
      assert encoding ==
               ~s({\"downstream\":24,\"upstream\":1,\"units\":\"Mbps\"})
      IO.inspect(@circuit_id)
      {:ok, circuit_value} = Circuit.new(%{circuit_id: @circuit_id, cvlan_id: @cvlan_id}) |> IO.inspect()
      to_string(circuit_value) |> IO.puts()
      encoding = Jason.encode!(circuit_value) |> IO.puts()

      circuit = Diffo.Provider.create_characteristic!(%{
        name: :circuit,
        value: circuit_value,
        type: :instance
      })
      encoding = Jason.encode!(circuit)
      assert encoding ==
        ~s({\"name\":\"circuit\",\"value\":{\"circuit_id\":\"#{@circuit_id}\",\"cvlan_id\":82,\"vci\":0,\"encapsulation\":\"IPoE\"}})

    end
  end
end
