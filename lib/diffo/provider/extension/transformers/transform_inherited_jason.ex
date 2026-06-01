# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Transformers.TransformInheritedJason do
  @moduledoc """
  Surfaces inherited and reverse-inherited results into the TMF JSON view.

  `TransformInheritedRefs` injects the Ash calculations for `inherited_place`,
  `inherited_party`, `inherited_characteristic`, and
  `reverse_inherited_characteristic` so they are loadable via `Ash.load/2`. That
  alone keeps the brought-up values off the consumer-visible TMF surface — the
  calc result never reaches the `place` / `relatedParty` / `serviceCharacteristic`
  / `resourceCharacteristic` arrays on encode.

  This transformer closes that gap. It appends one focused `jason.customize` step
  per TMF array — but only for the inherited kinds the resource actually declares:

    * `inherited_place` → `Diffo.Provider.Instance.Util.surface_inherited_places/2`
      (the `place` array)
    * `inherited_party` → `Diffo.Provider.Instance.Util.surface_inherited_parties/2`
      (the `relatedParty` array)
    * `inherited_characteristic` / `reverse_inherited_characteristic` →
      `Diffo.Provider.Instance.Util.surface_inherited_characteristics/2`
      (the `serviceCharacteristic` / `resourceCharacteristic` array)

  Each step — at encode time — reads its inherited calc(s) off the record, drops
  `%Diffo.Unknown{}` sentinels (X-state is the Diffo diagnostic surface, not the
  TMF wire), and appends the concrete structs to its array. Each surfaced struct
  encodes via its own `Jason.Encoder`, so subtype fidelity is preserved without
  hand-building any TMF object here. See the `Diffo.Provider.Instance.Util`
  functions for the runtime logic and the ordering convention.

  Single responsibility by design: calc injection stays in `TransformInheritedRefs`
  (an API concern), wire surfacing lives here (a TMF concern). The two evolve
  independently.

  Runs **after** `TransformInheritedRefs` (the calcs must exist) and **before**
  `AshJason.Resource.Transformer` (which compiles the `jason do` steps into the
  `Jason.Encoder` implementation).
  """
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  alias Diffo.Provider.Extension.InheritedPlaceDeclaration
  alias Diffo.Provider.Extension.InheritedPartyDeclaration
  alias Diffo.Provider.Extension.InheritedCharacteristicDeclaration
  alias Diffo.Provider.Extension.ReverseInheritedCharacteristicDeclaration
  alias Diffo.Provider.Instance.Util

  @impl true
  def after?(Diffo.Provider.Extension.Transformers.TransformInheritedRefs), do: true
  def after?(_), do: false

  @impl true
  def before?(AshJason.Resource.Transformer), do: true
  def before?(_), do: false

  @impl true
  def transform(dsl_state) do
    places = Transformer.get_entities(dsl_state, [:provider, :places])
    parties = Transformer.get_entities(dsl_state, [:provider, :parties])
    characteristics = Transformer.get_entities(dsl_state, [:provider, :characteristics])

    dsl_state =
      dsl_state
      |> maybe_add_step(
        declared?(places, [InheritedPlaceDeclaration]),
        &Util.surface_inherited_places/2
      )
      |> maybe_add_step(
        declared?(parties, [InheritedPartyDeclaration]),
        &Util.surface_inherited_parties/2
      )
      |> maybe_add_step(
        declared?(characteristics, [
          InheritedCharacteristicDeclaration,
          ReverseInheritedCharacteristicDeclaration
        ]),
        &Util.surface_inherited_characteristics/2
      )

    {:ok, dsl_state}
  end

  defp maybe_add_step(dsl_state, false, _fun), do: dsl_state

  defp maybe_add_step(dsl_state, true, fun) do
    step = %AshJason.TransformerHelpers.Step{type: :customize, input: fun}
    # Append, not prepend. AshJason threads `result` through the `[:jason]` steps
    # in list order, and the base Service/Resource fragment's own customize step is
    # what *builds* the `serviceCharacteristic` / `resourceCharacteristic` (and
    # `place` / `relatedParty`) arrays. The surfacing step appends to those arrays,
    # so it must run *after* the fragment materialises them — prepending (the
    # `add_entity` default) ran it first, before the array existed, and the fragment
    # then clobbered the surfaced value. See #202.
    Transformer.add_entity(dsl_state, [:jason], step, type: :append)
  end

  defp declared?(entities, declaration_modules) do
    Enum.any?(entities, fn entity ->
      Enum.any?(declaration_modules, &is_struct(entity, &1))
    end)
  end
end
