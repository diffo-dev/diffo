defmodule Mix.Tasks.Diagram do
  @moduledoc "The diagram mix task: `mix help diagram`"
  use Mix.Task

  @shortdoc "Regenerates various diagrams"
  def run(_) do
    Mix.Tasks.AshStateMachine.GenerateFlowCharts.run(type: :flow_chart)
  end
end
