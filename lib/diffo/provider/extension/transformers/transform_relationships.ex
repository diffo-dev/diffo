# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Transformers.TransformRelationships do
  @moduledoc "Resolves the relationships pipeline and bakes permitted_source_roles/0 and permitted_target_roles/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    steps = Transformer.get_entities(dsl_state, [:provider, :relationships])
    source_roles = resolve_roles(steps, :source)
    target_roles = resolve_roles(steps, :target)

    escaped_steps = Macro.escape(steps)
    escaped_source = Macro.escape(source_roles)
    escaped_target = Macro.escape(target_roles)

    {:ok,
     Transformer.eval(
       dsl_state,
       [],
       quote do
         @doc false
         def relationships, do: unquote(escaped_steps)

         @doc false
         def permitted_source_roles, do: unquote(escaped_source)

         @doc false
         def permitted_target_roles, do: unquote(escaped_target)
       end
     )}
  end

  defp resolve_roles(steps, direction) do
    steps
    |> Enum.filter(&(&1.direction == direction))
    |> case do
      [] -> :none
      filtered -> List.last(filtered).roles
    end
  end

  @impl true
  def after?(_), do: false
end
