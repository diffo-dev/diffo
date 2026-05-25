# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Place do
  @moduledoc """
  Ash Resource for a TMF Place.

  Out-of-the-box concrete `Diffo.Provider.Place` derived from `BasePlace`. All TMF
  surface (attributes, actions, validations, jason encoding including the TMF675
  GeoJson polymorphism, outstanding) lives on the fragment so domain extenders
  inherit the full Place behaviour by including `BasePlace` and need only add their
  own domain-specific attributes and actions.

  See `Diffo.Provider.BasePlace` for full documentation.
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
