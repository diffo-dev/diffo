# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Persisters.PersistSpecification do
  @moduledoc "Normalises specification DSL options, persists them, and bakes specification/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    spec = [
      id: Transformer.get_option(dsl_state, [:structure, :specification], :id),
      name: Transformer.get_option(dsl_state, [:structure, :specification], :name),
      type: Transformer.get_option(dsl_state, [:structure, :specification], :type, :serviceSpecification),
      major_version: Transformer.get_option(dsl_state, [:structure, :specification], :major_version, 1),
      minor_version: Transformer.get_option(dsl_state, [:structure, :specification], :minor_version),
      patch_version: Transformer.get_option(dsl_state, [:structure, :specification], :patch_version),
      tmf_version: Transformer.get_option(dsl_state, [:structure, :specification], :tmf_version),
      description: Transformer.get_option(dsl_state, [:structure, :specification], :description),
      category: Transformer.get_option(dsl_state, [:structure, :specification], :category)
    ]

    escaped = Macro.escape(spec)
    dsl_state = Transformer.persist(dsl_state, :specification, spec)

    {:ok, Transformer.eval(dsl_state, [], quote do
      @doc false
      def specification, do: unquote(escaped)
    end)}
  end
end
