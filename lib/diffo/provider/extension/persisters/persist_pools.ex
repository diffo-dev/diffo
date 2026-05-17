# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Persisters.PersistPools do
  @moduledoc "Persists pool declarations and bakes pools/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    declarations = Transformer.get_entities(dsl_state, [:provider, :pools])
    escaped = Macro.escape(declarations)
    dsl_state = Transformer.persist(dsl_state, :pools, declarations)

    {:ok,
     Transformer.eval(
       dsl_state,
       [],
       quote do
         @doc false
         def pools, do: unquote(escaped)
       end
     )}
  end
end
