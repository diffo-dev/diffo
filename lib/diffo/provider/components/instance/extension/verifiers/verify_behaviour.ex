# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Verifiers.VerifyBehaviour do
  @moduledoc "Verifies that actions declared in behaviour do exist as Ash actions of the correct type"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError
  alias Diffo.Provider.Instance.Extension.ActionCreate
  alias Diffo.Provider.Instance.Extension.ActionUpdate

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    behaviour_actions = Verifier.get_entities(dsl_state, [:behaviour, :actions])
    ash_actions = Verifier.get_entities(dsl_state, [:actions])

    create_names = ash_actions |> Enum.filter(&is_struct(&1, Ash.Resource.Actions.Create)) |> MapSet.new(& &1.name)
    update_names = ash_actions |> Enum.filter(&is_struct(&1, Ash.Resource.Actions.Update)) |> MapSet.new(& &1.name)

    errors =
      Enum.flat_map(behaviour_actions, fn
        %ActionCreate{name: name} ->
          if MapSet.member?(create_names, name) do
            []
          else
            [DslError.exception(
              module: resource,
              path: [:behaviour, :actions],
              message: "behaviour: create #{inspect(name)} does not exist as a create action on this resource"
            )]
          end

        %ActionUpdate{name: name} ->
          if MapSet.member?(update_names, name) do
            []
          else
            [DslError.exception(
              module: resource,
              path: [:behaviour, :actions],
              message: "behaviour: update #{inspect(name)} does not exist as an update action on this resource"
            )]
          end
      end)

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end
end
