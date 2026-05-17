# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Persisters.PersistFeatures do
  @moduledoc "Persists feature declarations and bakes features/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    declarations = Transformer.get_entities(dsl_state, [:provider, :features])
    escaped = Macro.escape(declarations)
    dsl_state = Transformer.persist(dsl_state, :features, declarations)

    {:ok,
     Transformer.eval(
       dsl_state,
       [],
       quote do
         @doc false
         def features, do: unquote(escaped)
       end
     )}
  end
end
