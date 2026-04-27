# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance do
  @moduledoc """
  Ash Resource for a TMF Service or Resource Instance
  """
  alias Diffo.Provider.BaseInstance

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Service or Resource Instance"
    plural_name :instances
  end
end
