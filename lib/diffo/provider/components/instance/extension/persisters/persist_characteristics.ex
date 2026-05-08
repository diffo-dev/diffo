# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Persisters.PersistCharacteristics do
  @moduledoc "Persists characteristic declarations and bakes characteristics/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    declarations = Transformer.get_entities(dsl_state, [:structure, :characteristics])
    escaped = Macro.escape(declarations)
    dsl_state = Transformer.persist(dsl_state, :characteristics, declarations)

    {:ok,
     Transformer.eval(
       dsl_state,
       [],
       quote do
         @doc false
         def characteristics, do: unquote(escaped)
       end
     )}
  end
end
