defmodule Diffo.Access.CharacteristicValueTest do
  @moduledoc false
  use ExUnit.Case
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
      :ok #AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  @dslam "QDONC0001"
  @model "ISAM7330"
  @svlan_id 3108
  @cvlan_id 82
  @circuit_id "#{@dslam} eth #{@svlan_id}:#{@cvlan_id}"
  @port 5
  @slot 3
  @profile "adsl2Plus24M1IntM"

  describe "Diffo.Access create Characteristics" do
    @tag debug: true
    test "create characteristics" do
      dslam_value =
        Dslam.new!(%{name: @dslam, model: @model})

      dslam =
        Diffo.Provider.create_characteristic!(%{
          name: :dslam,
          value: dslam_value,
          type: :instance
        })

      encoding = Jason.encode!(dslam)

      assert encoding ==
               ~s({\"name\":\"dslam\",\"value\":{\"name\":\"#{@dslam}\",\"family\":\"ISAM",\"model\":\"#{@model}\",\"technology\":\"eth\"}})


      aggregate_interface_value =
        AggregateInterface.new!(%{name: "F DONC BOXH 010J", physical_interface: "1000BASE-LX", svlan_id: @svlan_id})

      aggregate_interface =
        Diffo.Provider.create_characteristic!(%{
          name: :aggregate_interface,
          value: aggregate_interface_value,
          type: :instance
        })

      assert Jason.encode!(aggregate_interface) ==
               ~s({\"name\":\"aggregate_interface\",\"value\":{\"name\":\"F DONC BOXH 010J\",\"physical_interface\":\"1000BASE-LX\",\"physical_layer\":\"GbE\",\"link_layer\":\"QinQ\",\"svlan_id\":3108,\"vpi\":0}})

      bandwidth_profile = BandwidthProfile.new!(%{downstream: 24, upstream: 1})

      assert Jason.encode!(bandwidth_profile) ==
               ~s({\"downstream\":24,\"upstream\":1,\"units\":\"Mbps\"})

      {:ok, circuit_value} =
        Circuit.new(%{circuit_id: @circuit_id, cvlan_id: @cvlan_id, bandwidth_profile: bandwidth_profile})

      circuit =
        Diffo.Provider.create_characteristic!(%{
          name: :circuit,
          value: circuit_value,
          type: :instance
        })

      assert Jason.encode!(circuit) ==
               ~s({\"name\":\"circuit\",\"value\":{\"circuit_id\":\"#{@circuit_id}\",\"cvlan_id\":82,\"vci\":0,\"encapsulation\":\"IPoE\",\"bandwidth_profile\":{\"downstream\":24,\"upstream\":1,\"units\":\"Mbps\"}}})

      {:ok, line_value} =
        Line.new(%{port: @port, slot: @slot, standard: :ADSL2plus, profile: @profile})

      line =
        Diffo.Provider.create_characteristic!(%{
          name: :line,
          value: line_value,
          type: :instance
        })

      assert Jason.encode!(line) ==
               ~s({\"name\":\"line\",\"value\":{\"port\":5,\"slot\":3,\"standard\":"\ADSL2plus\",\"profile\":\"#{@profile}\"}})
      end
  end
end
