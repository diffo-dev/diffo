# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party do
  @moduledoc """
  Ash Resource for a TMF Party

  The out-of-the-box TMF Party resource. Uses `BaseParty` as a fragment and adds
  JSON serialisation with TMF `@type` / `@referredType` key mapping and outstanding
  validation covering the core TMF Party fields.

  Use `Diffo.Provider.Party` directly via the `Diffo.Provider` domain when working with
  generic TMF parties (e.g. party refs on instances). For domain-specific parties with
  richer identity — such as an RSP or a Customer — extend `BaseParty` directly in your
  own domain and define a `build` action that sets `type` or `referred_type` appropriately.

  See `Diffo.Provider.BaseParty` for full usage documentation.
  """
  alias Diffo.Provider.BaseParty

  use Ash.Resource,
    fragments: [BaseParty],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Party"
    plural_name :parties
  end

  jason do
    pick [:id, :href, :name, :referred_type, :type]
    compact true
    rename referred_type: "@referredType", type: "@type"
  end

  outstanding do
    expect [:id, :name, :referred_type, :type]
  end
end
