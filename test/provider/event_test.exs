# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.EventTest do
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

  describe "Diffo.Provider.Event create" do
    test "create an event - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      event =
        Diffo.Provider.Event.create!(%{
          instance_id: instance.id,
          type: :serviceCreateEvent
        })

      assert event.type == :serviceCreateEvent
      assert event.instance_type == :service

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: instance.id},
               :Event,
               %{uuid: event.id},
               :FIRED,
               :outgoing
             )
    end

    test "create multiple events (no chaining) - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      event_1 =
        Diffo.Provider.Event.create!(%{
          instance_id: instance.id,
          type: :serviceCreateEvent
        })

      event_2 =
        Diffo.Provider.Event.create!(%{
          instance_id: instance.id,
          type: :serviceStateChangeEvent
        })

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: instance.id},
               :Event,
               %{uuid: event_1.id},
               :FIRED,
               :outgoing
             )

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: instance.id},
               :Event,
               %{uuid: event_2.id},
               :FIRED,
               :outgoing
             )
    end

    test "create event and chain it before previous event - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      event_1 =
        Diffo.Provider.Event.create!(%{
          instance_id: instance.id,
          type: :serviceCreateEvent
        })

      event_2 =
        Diffo.Provider.Event.create!(%{
          instance_id: instance.id,
          type: :serviceStateChangeEvent
        })

      event_1 =
        event_1
        |> Diffo.Provider.Event.chain!(%{
          instance_id: instance.id,
          head_id: event_2.id
        })

      refute AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: instance.id},
               :Event,
               %{uuid: event_1.id},
               :FIRED,
               :outgoing
             )

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: instance.id},
               :Event,
               %{uuid: event_2.id},
               :FIRED,
               :outgoing
             )

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Event,
               %{uuid: event_2.id},
               :Event,
               %{uuid: event_1.id},
               :AFTER,
               :outgoing
             )
    end
  end

  describe "Diffo.Provider.Event encode" do
    test "encode json with service instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      event =
        Diffo.Provider.Event.create!(%{
          instance_id: instance.id,
          type: :serviceCreateEvent
        })

      encoding = Jason.encode!(event) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"eventId\":\"#{event.id}\",\"eventTime\":\"now\",\"eventType\":\"serviceCreateEvent\",\"event\":{\"service\":{\"id\":\"#{instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/nbnAccess/#{instance.id}\",\"serviceSpecification\":{\"id\":\"#{specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{specification.id}\",\"name\":\"nbnAccess\",\"version\":\"v1.0.0\"},\"serviceDate\":\"now\",\"state\":\"initial\"}}})
    end
  end

  describe "Diffo.Provider outstanding Event" do
    use Outstand
    @now DateTime.utc_now()
    @type_only %Diffo.Provider.Event{type: :serviceCreateEvent}
    @time_only %Diffo.Provider.Event{created_at: @now}
    @uuid UUID.uuid4()
    @instance_id_only %Diffo.Provider.Event{instance_id: @uuid}
    @instance_only %Diffo.Provider.Event{
      instance: %Diffo.Provider.Instance{service_state: :active}
    }
    @specific_event %Diffo.Provider.Event{
      type: :serviceCreateEvent,
      created_at: @now,
      instance_id: @uuid,
      instance: %Diffo.Provider.Instance{service_state: :active}
    }

    @generic_event %Diffo.Provider.Event{
      type: &__MODULE__.service_event_type/1,
      created_at: nil,
      instance_id: nil,
      instance_type: :service,
      instance: nil
    }
    @actual_event %Diffo.Provider.Event{
      type: :serviceCreateEvent,
      created_at: @now,
      instance_id: @uuid,
      instance: %Diffo.Provider.Instance{id: @uuid, service_state: :active}
    }

    gen_nothing_outstanding_test(
      "specific nothing outstanding",
      @specific_event,
      @actual_event
    )

    gen_result_outstanding_test(
      "specific event result",
      @specific_event,
      nil,
      Ash.Test.strip_metadata(@specific_event)
    )

    gen_result_outstanding_test(
      "specific type result",
      @specific_event,
      Map.delete(@actual_event, :type),
      Ash.Test.strip_metadata(@type_only)
    )

    gen_result_outstanding_test(
      "specific time result",
      @specific_event,
      Map.delete(@actual_event, :created_at),
      Ash.Test.strip_metadata(@time_only)
    )

    gen_result_outstanding_test(
      "specific instance_id result",
      @specific_event,
      Map.put(@actual_event, :instance_id, nil),
      Ash.Test.strip_metadata(@instance_id_only)
    )

    gen_result_outstanding_test(
      "specific instance.service_state result",
      @specific_event,
      Kernel.update_in(@actual_event.instance.service_state, fn _ -> nil end),
      Ash.Test.strip_metadata(@instance_only)
    )

    gen_nothing_outstanding_test(
      "generic nothing outstanding",
      @generic_event,
      @actual_event
    )
  end

  describe "Diffo.Provider delete Event" do
    test "delete event with related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      event =
        Diffo.Provider.Event.create!(%{
          instance_id: instance.id,
          type: :serviceCreateEvent
        })

      :ok = Diffo.Provider.delete_event(event)
      {:error, _error} = Diffo.Provider.get_event_by_id(event.id)
    end
  end

  def service_event_type(actual) do
    cond do
      actual == nil ->
        :service_event_type

      Regex.match?(~r/service/, String.Chars.to_string(actual)) ->
        nil

      true ->
        :service_event_type
    end
  end
end
