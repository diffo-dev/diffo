# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.EventTest do
  @moduledoc false
  use ExUnit.Case

  setup_all do
    :ok #AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      :ok #AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Diffo.Provider.Event create" do
    test "create an event using Event code interface - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      snapshot = Jason.encode!(instance)

      event = Diffo.Provider.Event.create!(%{type: :serviceCreateEvent, firing_type: instance.type, firing_snapshot: snapshot, instance_id: instance.id})

      assert event.instance_id == instance.id
      assert event.type == :serviceCreateEvent
      assert event.firing_type == :service
      assert event.firing_snapshot

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: instance.id},
               :Event,
               %{uuid: event.id},
               :FIRED,
               :outgoing
             )
    end
  end

  describe "Diffo.Provider.Event encode" do
    test "encode json with service instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      snapshot = Jason.encode!(instance)
      event = Diffo.Provider.Event.create!(%{type: :serviceCreateEvent, firing_type: instance.type, firing_snapshot: snapshot, instance_id: instance.id})

      encoding = Jason.encode!(event) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"eventId\":\"#{event.id}\",\"eventTime\":\"now\",\"eventType\":\"serviceCreateEvent\",\"event\":{\"service\":{\"id\":\"#{instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/nbnAccess/#{instance.id}\",\"serviceSpecification\":{\"id\":\"#{specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{specification.id}\",\"name\":\"nbnAccess\",\"version\":\"v1.0.0\"},\"serviceDate\":\"now\",\"state\":\"initial\"}}})
    end
  end

  describe "Diffo.Provider.Event provider API" do
    test "fire an instance event - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      instance = Diffo.Provider.fire_instance_event!(instance, %{event: %{type: :serviceCreateEvent}})
      assert instance.event
      event = instance.event

      assert event.instance_id == instance.id
      assert event.type == :serviceCreateEvent
      assert event.firing_type == :service
      assert event.firing_snapshot

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: instance.id},
               :Event,
               %{uuid: event.id},
               :FIRED,
               :outgoing
             )
    end

    test "fired events are chained - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      instance = Diffo.Provider.fire_instance_event!(instance, %{event: %{type: :serviceCreateEvent}})
      event_1 = instance.event

      instance = Diffo.Provider.activate_service!(instance)

      instance = Diffo.Provider.fire_instance_event!(instance, %{event: %{type: :serviceStateChangeEvent}})
      event_2 = instance.event

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

  describe "Diffo.Provider outstanding Event" do
    use Outstand
    @now DateTime.utc_now()
    @instance_id UUID.uuid4()
    @instance %Diffo.Provider.Instance{service_state: :active}
    @firing_type :service
    @firing_snapshot Jason.encode(!@instance)

    @type_only %Diffo.Provider.Event{type: :serviceCreateEvent}
    @time_only %Diffo.Provider.Event{created_at: @now}
    @instance_id_only %Diffo.Provider.Event{instance_id: @instance_id}
    @firing_type_only %Diffo.Provider.Event{firing_type: @firing_type}
    @firing_snapshot_only %Diffo.Provider.Event{firing_snapshot: @firing_snapshot}
    @specific_event %Diffo.Provider.Event{
      type: :serviceCreateEvent,
      created_at: @now,
      instance_id: @instance_id,
      firing_type: @firing_type,
      firing_snapshot: @firing_snapshot
    }

    @generic_event %Diffo.Provider.Event{
      type: &__MODULE__.service_event_type/1,
      created_at: nil,
      instance_id: nil,
      firing_type: :service,
      firing_snapshot: nil
    }

    @actual_event %Diffo.Provider.Event{
      type: :serviceCreateEvent,
      created_at: @now,
      instance_id: @instance_id,
      firing_type: @firing_type,
      firing_snapshot: @firing_snapshot
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
      "specific firing_type result",
      @specific_event,
      Map.put(@actual_event, :firing_type, nil),
      Ash.Test.strip_metadata(@firing_type_only)
    )

    gen_result_outstanding_test(
      "specific firing_snapshot result",
      @specific_event,
      Map.put(@actual_event, :firing_snapshot, nil),
      Ash.Test.strip_metadata(@firing_snapshot_only)
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

      instance = Diffo.Provider.fire_instance_event!(instance, %{event: %{type: :serviceCreateEvent}})
      event = instance.event

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
