# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Transformers.TransformInheritedRefs do
  @moduledoc "Injects Ash calculations for inherited_place and inherited_party declarations"
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  alias Diffo.Provider.Extension.InheritedPlaceDeclaration
  alias Diffo.Provider.Extension.InheritedPartyDeclaration

  @impl true
  def transform(dsl_state) do
    places = Transformer.get_entities(dsl_state, [:provider, :places])
    parties = Transformer.get_entities(dsl_state, [:provider, :parties])

    dsl_state =
      places
      |> Enum.filter(&is_struct(&1, InheritedPlaceDeclaration))
      |> Enum.reduce(dsl_state, &inject_place_calculation(&2, &1))

    dsl_state =
      parties
      |> Enum.filter(&is_struct(&1, InheritedPartyDeclaration))
      |> Enum.reduce(dsl_state, &inject_party_calculation(&2, &1))

    {:ok, dsl_state}
  end

  defp inject_place_calculation(dsl_state, %InheritedPlaceDeclaration{} = decl) do
    via = decl.via || [decl.role]

    calc = %Ash.Resource.Calculation{
      name: decl.role,
      type: {:array, :map},
      calculation:
        {Diffo.Provider.Calculations.InheritedPlace, [via: via, source_role: decl.source_role]},
      description: "Inherited place via assignment alias traversal",
      arguments: [],
      public?: true,
      allow_nil?: true,
      constraints: []
    }

    Transformer.add_entity(dsl_state, [:calculations], calc)
  end

  defp inject_party_calculation(dsl_state, %InheritedPartyDeclaration{} = decl) do
    via = decl.via || [decl.role]

    calc = %Ash.Resource.Calculation{
      name: decl.role,
      type: {:array, :map},
      calculation:
        {Diffo.Provider.Calculations.InheritedParty, [via: via, source_role: decl.source_role]},
      description: "Inherited party via assignment alias traversal",
      arguments: [],
      public?: true,
      allow_nil?: true,
      constraints: []
    }

    Transformer.add_entity(dsl_state, [:calculations], calc)
  end
end
