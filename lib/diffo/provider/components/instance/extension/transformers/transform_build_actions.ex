# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Transformers.TransformBuildActions do
  @moduledoc "Generates __diffo_build_before__/1 and __diffo_build_after__/2 from baked structural data"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl_state) do
    {:ok, Transformer.eval(dsl_state, [], quote do
      @doc false
      def __diffo_build_before__(changeset) do
        changeset
        |> Diffo.Provider.Instance.Specification.set_specified_by_argument(__diffo_specification__())
        |> Diffo.Provider.Instance.Feature.set_features_argument(__diffo_features__())
        |> Diffo.Provider.Instance.Characteristic.set_characteristics_argument(__diffo_characteristics__())
        |> Diffo.Provider.Instance.Party.validate_parties(__diffo_party_declarations__())
      end

      @doc false
      def __diffo_build_after__(changeset, result) do
        Diffo.Provider.Instance.ActionHelper.build_after(changeset, result)
      end
    end)}
  end

  @impl true
  def after?(Diffo.Provider.Instance.Extension.Transformers.TransformSpecification), do: true
  def after?(Diffo.Provider.Instance.Extension.Transformers.TransformCharacteristics), do: true
  def after?(Diffo.Provider.Instance.Extension.Transformers.TransformFeatures), do: true
  def after?(Diffo.Provider.Instance.Extension.Transformers.TransformParties), do: true
  def after?(_), do: false
end
