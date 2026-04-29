# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Transformers.TransformBehaviour do
  @moduledoc "Generates build_before/1 and build_after/2, and injects build arguments into declared create actions"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  alias Diffo.Provider.Instance.Extension.ActionCreate

  @build_args [
    specified_by: :uuid,
    features: {:array, :uuid},
    characteristics: {:array, :uuid}
  ]

  @impl true
  def transform(dsl_state) do
    spec = Transformer.get_persisted(dsl_state, :specification, [])

    dsl_state = inject_create_arguments(dsl_state)

    {build_before_body, build_after_body} =
      if spec[:id] do
        before_body = quote do
          changeset
          |> Diffo.Provider.Instance.Specification.set_specified_by_argument(specification())
          |> Diffo.Provider.Instance.Feature.set_features_argument(features())
          |> Diffo.Provider.Instance.Characteristic.set_characteristics_argument(characteristics())
          |> Diffo.Provider.Instance.Party.validate_parties(parties())
        end

        after_body = quote do
          Diffo.Provider.Instance.ActionHelper.build_after(changeset, result)
        end

        {before_body, after_body}
      else
        {quote(do: changeset), quote(do: {:ok, result})}
      end

    {:ok, Transformer.eval(dsl_state, [], quote do
      @doc false
      def build_before(changeset), do: unquote(build_before_body)

      @doc false
      def build_after(changeset, result), do: unquote(build_after_body)

      @doc false
      def characteristic(name), do: Enum.find(characteristics(), &(&1.name == name))

      @doc false
      def feature(name), do: Enum.find(features(), &(&1.name == name))

      @doc false
      def feature_characteristic(feature_name, char_name) do
        case feature(feature_name) do
          nil -> nil
          f -> Enum.find(f.characteristics, &(&1.name == char_name))
        end
      end

      @doc false
      def party(role), do: Enum.find(parties(), &(&1.role == role))

      @doc false
      def place(role), do: Enum.find(places(), &(&1.role == role))
    end)}
  end

  defp inject_create_arguments(dsl_state) do
    action_create_declarations =
      Transformer.get_entities(dsl_state, [:behaviour, :actions])
      |> Enum.filter(&is_struct(&1, ActionCreate))

    Enum.reduce(action_create_declarations, dsl_state, fn %ActionCreate{name: action_name}, dsl_state ->
      action =
        Transformer.get_entities(dsl_state, [:actions])
        |> Enum.find(&(is_struct(&1, Ash.Resource.Actions.Create) and &1.name == action_name))

      if action do
        existing = MapSet.new(action.arguments, & &1.name)

        new_args =
          @build_args
          |> Enum.reject(fn {name, _} -> MapSet.member?(existing, name) end)
          |> Enum.map(fn {name, type} ->
            %Ash.Resource.Actions.Argument{name: name, type: type, public?: false, allow_nil?: true}
          end)

        updated = %{action | arguments: action.arguments ++ new_args}
        Transformer.replace_entity(dsl_state, [:actions], updated, fn entity ->
          is_struct(entity, Ash.Resource.Actions.Create) and entity.name == action_name
        end)
      else
        dsl_state
      end
    end)
  end

  @impl true
  def after?(Diffo.Provider.Instance.Extension.Persisters.PersistSpecification), do: true
  def after?(Diffo.Provider.Instance.Extension.Persisters.PersistCharacteristics), do: true
  def after?(Diffo.Provider.Instance.Extension.Persisters.PersistFeatures), do: true
  def after?(Diffo.Provider.Instance.Extension.Persisters.PersistParties), do: true
  def after?(Diffo.Provider.Instance.Extension.Persisters.PersistPlaces), do: true
  def after?(_), do: false
end
