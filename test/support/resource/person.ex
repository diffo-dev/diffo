# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Person do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Person - Person Party
  """

  alias Diffo.Provider.BaseParty
  alias Diffo.Test.Nbn

  use Ash.Resource,
    fragments: [BaseParty],
    domain: Nbn

  resource do
    description "A Person"
    plural_name :persons
  end

  party do
    role :managed_by, Diffo.Test.Person
  end
end
