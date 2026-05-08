# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Place.Extension.Persisters.PersistParties do
  @moduledoc "Persists party role declarations and bakes parties/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    declarations = Transformer.get_entities(dsl_state, [:parties])
    escaped = Macro.escape(declarations)
    dsl_state = Transformer.persist(dsl_state, :parties, declarations)

    {:ok,
     Transformer.eval(
       dsl_state,
       [],
       quote do
         @doc false
         def parties, do: unquote(escaped)
       end
     )}
  end
end
