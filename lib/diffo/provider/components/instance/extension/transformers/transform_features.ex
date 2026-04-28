# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Transformers.TransformFeatures do
  @moduledoc "Bakes feature declarations into __diffo_features__/0"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    features = Transformer.get_entities(dsl_state, [:features])
    escaped = Macro.escape(features)

    {:ok, Transformer.eval(dsl_state, [], quote do
      @doc false
      def __diffo_features__, do: unquote(escaped)
    end)}
  end
end
