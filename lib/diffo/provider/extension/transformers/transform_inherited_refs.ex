# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Transformers.TransformInheritedRefs do
  @moduledoc """
  Injects Ash calculations for `inherited_place`, `inherited_party`, and
  `inherited_characteristic` declarations.

  The consumer's resource module (`__MODULE__` of the resource being compiled)
  is passed as the `:world` opt to every injected calc — used for stamping
  `%Diffo.Unknown{}` sentinels at compile time rather than runtime resource
  introspection. See `Diffo.Provider.Calculations.InheritedPlace`,
  `InheritedParty`, and `InheritedCharacteristic` for each calc's local reason
  vocabulary.
  """
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  alias Diffo.Provider.Extension.InheritedPlaceDeclaration
  alias Diffo.Provider.Extension.InheritedPartyDeclaration
  alias Diffo.Provider.Extension.InheritedCharacteristicDeclaration
  alias Diffo.Provider.Extension.Traversal

  @impl true
  def transform(dsl_state) do
    places = Transformer.get_entities(dsl_state, [:provider, :places])
    parties = Transformer.get_entities(dsl_state, [:provider, :parties])
    characteristics = Transformer.get_entities(dsl_state, [:provider, :characteristics])
    resource = Transformer.get_persisted(dsl_state, :module)

    dsl_state =
      places
      |> Enum.filter(&is_struct(&1, InheritedPlaceDeclaration))
      |> Enum.reduce(dsl_state, &inject_place_calculation(&2, &1, resource))

    dsl_state =
      parties
      |> Enum.filter(&is_struct(&1, InheritedPartyDeclaration))
      |> Enum.reduce(dsl_state, &inject_party_calculation(&2, &1, resource))

    dsl_state =
      characteristics
      |> Enum.filter(&is_struct(&1, InheritedCharacteristicDeclaration))
      |> Enum.reduce(dsl_state, &inject_inherited_characteristic_calculation(&2, &1, resource))

    {:ok, dsl_state}
  end

  defp inject_place_calculation(dsl_state, %InheritedPlaceDeclaration{} = decl, resource) do
    via = decl.via || [decl.role]

    calc = %Ash.Resource.Calculation{
      name: decl.role,
      type: {:array, :map},
      calculation:
        {Diffo.Provider.Calculations.InheritedPlace,
         [via: via, source_role: decl.source_role, world: resource]},
      description: "Inherited place via assignment alias traversal",
      arguments: [],
      public?: true,
      allow_nil?: true,
      constraints: []
    }

    Transformer.add_entity(dsl_state, [:calculations], calc)
  end

  defp inject_party_calculation(dsl_state, %InheritedPartyDeclaration{} = decl, resource) do
    via = decl.via || [decl.role]

    calc = %Ash.Resource.Calculation{
      name: decl.role,
      type: {:array, :map},
      calculation:
        {Diffo.Provider.Calculations.InheritedParty,
         [via: via, source_role: decl.source_role, world: resource]},
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
    case Traversal.normalize(decl.via, decl.name) do
      {:ok, hops} ->
        read = decl.read || decl.name
        type = if decl.collapse, do: :map, else: {:array, :map}

        calc = %Ash.Resource.Calculation{
          name: decl.name,
          type: type,
          calculation:
            {Diffo.Provider.Calculations.InheritedCharacteristic,
             [hops: hops, read: read, as: decl.as, world: resource, collapse: decl.collapse]},
          description: "Inherited typed characteristic via graph traversal",
          arguments: [],
          public?: true,
          allow_nil?: true,
          constraints: []
        }

        Transformer.add_entity(dsl_state, [:calculations], calc)

      # Transformers run before verifiers; a malformed `via` is left untouched here
      # so VerifyCharacteristics can report it as a clean DslError rather than this
      # transformer crashing on a match error.
      {:error, _reason} ->
        dsl_state
    end
  end
end
