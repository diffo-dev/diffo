# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Transformers.TransformParties do
  @moduledoc "Bakes party declarations into __diffo_party_declarations__/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    parties = Transformer.get_entities(dsl_state, [:parties])
    escaped = Macro.escape(parties)

    {:ok, Transformer.eval(dsl_state, [], quote do
      @doc false
      def __diffo_party_declarations__, do: unquote(escaped)
    end)}
  end
end
