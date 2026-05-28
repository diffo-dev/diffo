# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Transformers.TransformInheritedRefs do
  @moduledoc """
  Injects Ash calculations for `inherited_place`, `inherited_party`,
  `inherited_characteristic`, and `reverse_inherited_characteristic` declarations.

  For the characteristic variants, the consumer's resource module (`__MODULE__` of
  the resource being compiled) is passed as the `:world` opt to the calc — used
  for stamping `%Diffo.Unknown{}` sentinels at compile time rather than runtime
  resource introspection. See `Diffo.Provider.Calculations.InheritedCharacteristic`
  and `ReverseInheritedCharacteristic` for the cross-world resolution semantics.
  """
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  alias Diffo.Provider.Extension.InheritedPlaceDeclaration
  alias Diffo.Provider.Extension.InheritedPartyDeclaration
  alias Diffo.Provider.Extension.InheritedCharacteristicDeclaration
  alias Diffo.Provider.Extension.ReverseInheritedCharacteristicDeclaration

  @impl true
  def transform(dsl_state) do
    places = Transformer.get_entities(dsl_state, [:provider, :places])
    parties = Transformer.get_entities(dsl_state, [:provider, :parties])
    characteristics = Transformer.get_entities(dsl_state, [:provider, :characteristics])
    resource = Transformer.get_persisted(dsl_state, :module)

    dsl_state =
      places
      |> Enum.filter(&is_struct(&1, InheritedPlaceDeclaration))
      |> Enum.reduce(dsl_state, &inject_place_calculation(&2, &1))

    dsl_state =
      parties
      |> Enum.filter(&is_struct(&1, InheritedPartyDeclaration))
      |> Enum.reduce(dsl_state, &inject_party_calculation(&2, &1))

    dsl_state =
      characteristics
      |> Enum.filter(&is_struct(&1, InheritedCharacteristicDeclaration))
      |> Enum.reduce(dsl_state, &inject_inherited_characteristic_calculation(&2, &1, resource))

    dsl_state =
      characteristics
      |> Enum.filter(&is_struct(&1, ReverseInheritedCharacteristicDeclaration))
      |> Enum.reduce(
        dsl_state,
        &inject_reverse_inherited_characteristic_calculation(&2, &1, resource)
      )

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

  defp inject_inherited_characteristic_calculation(
         dsl_state,
         %InheritedCharacteristicDeclaration{} = decl,
         resource
       ) do
    via = decl.via || [decl.role]

    calc = %Ash.Resource.Calculation{
      name: decl.role,
      type: {:array, :map},
      calculation:
        {Diffo.Provider.Calculations.InheritedCharacteristic,
         [via: via, role: decl.role, world: resource]},
      description: "Inherited typed characteristic via assignment alias traversal (inward)",
      arguments: [],
      public?: true,
      allow_nil?: true,
      constraints: []
    }

    Transformer.add_entity(dsl_state, [:calculations], calc)
  end

  defp inject_reverse_inherited_characteristic_calculation(
         dsl_state,
         %ReverseInheritedCharacteristicDeclaration{} = decl,
         resource
       ) do
    calc = %Ash.Resource.Calculation{
      name: decl.name,
      type: {:array, :map},
      calculation:
        {Diffo.Provider.Calculations.ReverseInheritedCharacteristic,
         [
           assignment_alias: decl.assignment_alias,
           characteristic: decl.characteristic,
           world: resource
         ]},
      description: "Inherited typed characteristic via assignment alias traversal (outward)",
      arguments: [],
      public?: true,
      allow_nil?: true,
      constraints: []
    }

    Transformer.add_entity(dsl_state, [:calculations], calc)
  end
end
