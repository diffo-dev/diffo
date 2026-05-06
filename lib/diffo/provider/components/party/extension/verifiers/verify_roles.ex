# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party.Extension.Verifiers.VerifyRoles do
  @moduledoc "Verifies role declarations across instances, parties, and places sections"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError
  alias Diffo.Provider.Instance.Extension.Info, as: InstanceInfo
  alias Diffo.Provider.Party.Extension.Info, as: PartyInfo
  alias Diffo.Provider.Place.Extension.Info, as: PlaceInfo

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)

    errors =
      check_section(dsl_state, [:instances], :party_type, &InstanceInfo.instance?/1,
        "instances", "instance_type", "BaseInstance", resource) ++
      check_section(dsl_state, [:parties], :party_type, &PartyInfo.party?/1,
        "parties", "party_type", "BaseParty", resource) ++
      check_section(dsl_state, [:places], :place_type, &PlaceInfo.place?/1,
        "places", "place_type", "BasePlace", resource)

    case errors do
      [] -> :ok
      _ -> {:error, errors}
    end
  end

  defp check_section(dsl_state, path, type_field, type_check?, section, field, base, resource) do
    entities = Verifier.get_entities(dsl_state, path)
    duplicate_errors(entities, section, resource) ++
      type_errors(entities, type_field, type_check?, section, field, base, resource)
  end

  defp duplicate_errors(entities, section, resource) do
    entities
    |> Enum.group_by(& &1.role)
    |> Enum.filter(fn {_role, list} -> length(list) > 1 end)
    |> Enum.map(fn {role, _} ->
      DslError.exception(
        module: resource,
        path: [String.to_atom(section)],
        message: "#{section}: role #{inspect(role)} is declared more than once"
      )
    end)
  end

  defp type_errors(entities, type_field, type_check?, section, field, base, resource) do
    Enum.reduce(entities, [], fn entity, acc ->
      mod = Map.get(entity, type_field)

      cond do
        is_nil(mod) ->
          acc

        !Code.ensure_loaded?(mod) ->
          [DslError.exception(
            module: resource,
            path: [String.to_atom(section)],
            message: "#{section}: #{field} #{inspect(mod)} does not exist"
          ) | acc]

        !type_check?.(mod) ->
          [DslError.exception(
            module: resource,
            path: [String.to_atom(section)],
            message: "#{section}: #{field} #{inspect(mod)} does not extend #{base}"
          ) | acc]

        true ->
          acc
      end
    end)
  end
end
