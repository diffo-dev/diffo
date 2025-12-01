# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.InstanceEventTest do
  @moduledoc false
  use ExUnit.Case

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      :ok #AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Diffo.Provider Instance Events" do
    test "create service raises a serviceCreateEvent - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})
      assert instance.event
      assert instance.event.type == :serviceCreateEvent
    end

    @tag debug: true
    test "cancel service raises a serviceStateChangeEvent - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      cancelled_service = Diffo.Provider.cancel_service!(instance) |> IO.inspect(label: :cancelled_service)
      assert cancelled_service.event
      assert cancelled_service.event.type == :serviceStateChangeEvent
    end
  end
end
