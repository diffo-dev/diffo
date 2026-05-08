# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party.Extension.Persisters.PersistInstances do
  @moduledoc "Persists instance role declarations and bakes instances/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    declarations = Transformer.get_entities(dsl_state, [:instances])
    escaped = Macro.escape(declarations)
    dsl_state = Transformer.persist(dsl_state, :instances, declarations)

    {:ok,
     Transformer.eval(
       dsl_state,
       [],
       quote do
         @doc false
         def instances, do: unquote(escaped)
       end
     )}
  end
end
