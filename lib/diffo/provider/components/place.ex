# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Place do
  @moduledoc """
  Abstract Place reader — plumbing, not a TMF subtype recommendation.

  TMF675 treats Place as abstract; the concrete subtypes are
  `Diffo.Provider.GeographicAddress`, `Diffo.Provider.GeographicSite`, and
  `Diffo.Provider.GeographicLocation`. Use those (or your own domain leaf
  composed from `BasePlace` + the matching `BaseGeographic*` fragment) for
  any **new** Place data.

  This resource is kept in core minimally to serve two roles:

    1. **Abstract reader for projection bootstrap.** `Diffo.Provider.get_place_by_id!/1`
       and friends load via this resource so `AshNeo4j.worlds/1` can project
       the loaded node to its outermost concrete world. Symmetric with how
       `Diffo.Provider.Instance` (the abstract reader for Instance) backs
       `Diffo.Provider.Calculations.InheritedCharacteristic` projection.
    2. **PlaceRef-typed placeholder.** A Place record with `type: :PlaceRef`
       and `referred_type:` set represents a reference to an externally-managed
       Place. `Diffo.Provider.create_place!(:PlaceRef, %{referred_type: :X, ...})`
       routes to this resource's `:create` action.

  See `Diffo.Provider.BasePlace` for the underlying fragment, attributes,
  validations, and TMF675 GeoJson wire encoding.

  ## Preferred API

  Production code should use the typed subtype leaves (`GeographicAddress` /
  `GeographicSite` / `GeographicLocation`) or, more ergonomically, the
  type-atom dispatcher on `Diffo.Provider`:

      Diffo.Provider.create_place!(:GeographicSite, %{...})

  Reads go through the dispatcher's projection path:

      Diffo.Provider.get_place_by_id!(id)    # returns concrete subtype struct
  """
  alias Diffo.Provider.BasePlace

  use Ash.Resource,
    fragments: [BasePlace],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Place"
    plural_name :places
  end
end
