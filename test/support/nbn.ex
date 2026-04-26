# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Nbn do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Nbn - a lightweight example domain for testing BaseParty and Party DSL
  """
  use Ash.Domain,
    otp_app: :diffo,
    validate_config_inclusion?: false

  alias Diffo.Test.Organisation
  alias Diffo.Test.Person

  domain do
    description "NBN party domain"
  end

  resources do
    resource Organisation do
      define :create_organisation, action: :create
      define :get_organisation_by_id, action: :read, get_by: :id
      define :list_organisations, action: :list
    end

    resource Person do
      define :create_person, action: :create
      define :get_person_by_id, action: :read, get_by: :id
      define :list_persons, action: :list
    end
  end
end
