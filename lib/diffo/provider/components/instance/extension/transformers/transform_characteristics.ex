# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Transformers.TransformCharacteristics do
  @moduledoc "Bakes characteristic declarations into __diffo_characteristics__/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    characteristics = Transformer.get_entities(dsl_state, [:characteristics])
    escaped = Macro.escape(characteristics)

    {:ok, Transformer.eval(dsl_state, [], quote do
      @doc false
      def __diffo_characteristics__, do: unquote(escaped)
    end)}
  end
end
