# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Diffo.Install.Docs do
  @moduledoc false

  def short_doc, do: "Installs Diffo"
  def example, do: "mix igniter.install diffo"

  def long_doc do
    """
    #{short_doc()}

    ## Example

    ```bash
    #{example()}
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.Diffo.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"
    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :ash,
        installs: [{:ash_neo4j, "~> 0.5"}],
        example: __MODULE__.Docs.example()
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> Igniter.Project.Formatter.import_dep(:diffo)
      |> Spark.Igniter.prepend_to_section_order(
        :"Ash.Resource",
        [:specification, :features, :characteristics]
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :ash,
        [:custom_expressions],
        [Diffo.Unwrap.AshCustomExpression],
        updater: fn zipper ->
          Igniter.Code.List.prepend_new_to_list(
            zipper,
            quote(do: Diffo.Unwrap.AshCustomExpression)
          )
        end
      )
    end
  end
else
  defmodule Mix.Tasks.Diffo.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"
    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'diffo.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
