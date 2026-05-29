# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Individual do
  @moduledoc """
  Ash Resource for a TMF632 Individual.

  Out-of-the-box concrete leaf derived from `BaseParty` + `BaseIndividual`.
  Sets `type: :Individual` on the `:build` action; accepts the union of base
  Party + individual-specific fields.

  See `Diffo.Provider.BaseIndividual` for the attribute set and TMF wire
  shape. See `Diffo.Provider.BaseParty` for the base attributes inherited via
  fragment composition.

  ## Cross-world consumers

  Domain extenders compose the same two fragments on their own leaf rather than
  extending this one. See the `BaseIndividual` docstring for an example.
  """
  alias Diffo.Provider.BaseParty
  alias Diffo.Provider.BaseIndividual

  use Ash.Resource,
    fragments: [BaseParty, BaseIndividual],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF632 Individual"
    plural_name :individuals
  end

  actions do
    create :build do
      description "creates a typed individual"

      accept [
        :id,
        :href,
        :name,
        :given_name,
        :family_name,
        :middle_name,
        :title,
        :gender,
        :birth_date,
        :nationality
      ]

      change set_attribute(:type, :Individual)
      upsert? true
    end

    update :define do
      description "defines fields on an individual (base + individual-specific)"

      accept [
        :name,
        :href,
        :given_name,
        :family_name,
        :middle_name,
        :title,
        :gender,
        :birth_date,
        :nationality
      ]
    end
  end
end
