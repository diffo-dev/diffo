# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party do
  @moduledoc """
  Ash Resource for a TMF Party.

  Out-of-the-box concrete `Diffo.Provider.Party` derived from `BaseParty`. All TMF
  surface (attributes, actions, validations, jason encoding with TMF `@type` /
  `@referredType` mapping, outstanding) lives on the fragment so domain extenders
  inherit the full Party behaviour by including `BaseParty` and need only add their
  own domain-specific attributes and actions.

  See `Diffo.Provider.BaseParty` for full documentation.
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
