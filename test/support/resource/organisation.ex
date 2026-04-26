# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Organisation do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Organisation - Organisation Party
  """

  alias Diffo.Provider.BaseParty
  alias Diffo.Test.Nbn

  use Ash.Resource,
    fragments: [BaseParty],
    domain: Nbn

  resource do
    description "An Organisation"
    plural_name :organisations
  end

  instance do
    role :facilitates, Diffo.Provider.Instance
  end
end
