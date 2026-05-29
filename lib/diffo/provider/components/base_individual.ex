# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.BaseIndividual do
  @moduledoc """
  Ash Resource Fragment for TMF632 Individual — a Party representing a single
  human being.

  Compose with `BaseParty` on a concrete leaf to get the TMF632 Individual
  attribute set, TMF camelCase jason wire shape, and individual-shaped
  outstanding signature.

  `Diffo.Provider.Individual` uses this fragment directly as the
  out-of-the-box TMF Individual resource. Domain extenders compose the same
  two fragments on their own leaf for richer domain identity:

      defmodule MyApp.Customer do
        use Ash.Resource,
          fragments: [Diffo.Provider.BaseParty, Diffo.Provider.BaseIndividual],
          domain: MyApp.Domain

        attributes do
          attribute :customer_segment, :atom, public?: true
        end

        actions do
          create :build do
            accept [:id, :href, :name, :given_name, :family_name, :birth_date, :customer_segment]
            change set_attribute(:type, :Individual)
          end
        end
      end

  ## Attributes

  All individual attributes are permissive (`allow_nil? true`) — tighten on
  your derived leaf if your domain requires e.g. a given_name + family_name.

  - `given_name` — first name.
  - `family_name` — last name (also known as surname).
  - `middle_name` — middle name or initial.
  - `title` — honorific (Pr, Dr, Sir, …).
  - `gender` — gender (TMF leaves it freeform).
  - `birth_date` — date of birth.
  - `nationality` — nationality.

  Deferred from this fragment (TMF632 v5 fields landing in follow-up tickets):

  - `legalName`, `formattedName`, `preferredGivenName`, `familyNamePrefix`,
    `aristocraticTitle`, `generation` (richer name composition)
  - `placeOfBirth`, `countryOfBirth`, `maritalStatus`, `deathDate`, `location`
    (richer demographics)
  - `status` (IndividualStateType — pairs with Specification state-machine work)
  - `otherName[]`, `individualIdentification[]`, `disability[]`,
    `languageAbility[]`, `skill[]` (nested resources)

  ## Wire shape (TMF632)

  `jason.pick` selects base + individual fields and renames to TMF camelCase
  (`givenName`, `familyName`, `middleName`, `birthDate`).
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    extensions: [AshOutstanding.Resource, AshJason.Resource]

  attributes do
    attribute :given_name, :string do
      description "the first name of the individual"
      allow_nil? true
      public? true
    end

    attribute :family_name, :string do
      description "the last name (surname) of the individual"
      allow_nil? true
      public? true
    end

    attribute :middle_name, :string do
      description "the middle name or initial"
      allow_nil? true
      public? true
    end

    attribute :title, :string do
      description "honorific (Pr, Dr, Sir, ...)"
      allow_nil? true
      public? true
    end

    attribute :gender, :string do
      description "gender"
      allow_nil? true
      public? true
    end

    attribute :birth_date, :utc_datetime do
      description "date of birth"
      allow_nil? true
      public? true
    end

    attribute :nationality, :string do
      description "nationality"
      allow_nil? true
      public? true
    end
  end

  jason do
    pick [
      :id,
      :href,
      :name,
      :type,
      :given_name,
      :family_name,
      :middle_name,
      :title,
      :gender,
      :birth_date,
      :nationality
    ]

    compact true

    rename type: "@type",
           given_name: "givenName",
           family_name: "familyName",
           middle_name: "middleName",
           birth_date: "birthDate"
  end

  outstanding do
    expect [:id, :name, :type]
  end
end
