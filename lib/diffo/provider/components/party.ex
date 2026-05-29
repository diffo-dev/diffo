# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party do
  @moduledoc """
  Abstract Party reader — plumbing, not a TMF subtype recommendation.

  TMF632 treats Party as abstract; the concrete subtypes are
  `Diffo.Provider.Organization` and `Diffo.Provider.Individual`. Use those
  (or your own domain leaf composed from `BaseParty` + the matching
  `BaseOrganization` / `BaseIndividual` fragment) for any **new** Party data.

  This resource is kept in core minimally to serve three roles:

    1. **Abstract reader for projection bootstrap.** `Diffo.Provider.get_party_by_id!/1`
       and friends load via this resource so `AshNeo4j.worlds/1` can project
       the loaded node to its outermost concrete world. Symmetric with how
       `Diffo.Provider.Place` (the abstract reader for Place) and
       `Diffo.Provider.Instance` (the abstract reader for Instance) serve
       their respective cascades.
    2. **PartyRef-typed placeholder.** A Party record with `type: :PartyRef`
       and `referred_type:` set represents a reference to an externally-managed
       Party. `Diffo.Provider.create_party!(:PartyRef, %{referred_type: :X, ...})`
       routes to this resource's `:create` action.
    3. **`:Entity`-typed abstract Party.** Diffo extends the TMF632 type enum
       with `:Entity` for party-like aggregates that aren't strictly Organization
       or Individual. `Diffo.Provider.create_party!(:Entity, %{...})` routes
       here.

  See `Diffo.Provider.BaseParty` for the underlying fragment, attributes,
  validations, and TMF `@type` / `@referredType` wire mapping.

  ## Preferred API

  Production code should use the typed subtype leaves (`Organization` /
  `Individual`) or, more ergonomically, the type-atom dispatcher on
  `Diffo.Provider`:

      Diffo.Provider.create_party!(:Organization, %{...})

  Reads go through the dispatcher's projection path:

      Diffo.Provider.get_party_by_id!(id)    # returns concrete subtype struct
  """
  alias Diffo.Provider.BaseParty

  use Ash.Resource,
    fragments: [BaseParty],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Party"
    plural_name :parties
  end
end
