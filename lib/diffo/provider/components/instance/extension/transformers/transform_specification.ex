# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Transformers.TransformSpecification do
  @moduledoc "Bakes specification DSL options into __diffo_specification__/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    spec = [
      id: Transformer.get_option(dsl_state, [:specification], :id),
      name: Transformer.get_option(dsl_state, [:specification], :name),
      type: Transformer.get_option(dsl_state, [:specification], :type),
      major_version: Transformer.get_option(dsl_state, [:specification], :major_version),
      description: Transformer.get_option(dsl_state, [:specification], :description),
      category: Transformer.get_option(dsl_state, [:specification], :category)
    ]

    escaped = Macro.escape(spec)

    {:ok, Transformer.eval(dsl_state, [], quote do
      @doc false
      def __diffo_specification__, do: unquote(escaped)
    end)}
  end
end
