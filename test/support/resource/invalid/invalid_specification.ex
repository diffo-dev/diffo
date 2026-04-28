# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.InvalidSpecification do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  InvalidSpecification - Resource Instance with an Invalid Specification
  """

  alias Diffo.Provider.BaseInstance

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Diffo.Test.Servo

  resource do
    description "Ash Resource with an invalid specification"
  end

  structure do
    specification do
      id "ef016d85-9dbd-429c-04da-1df56cc7dda5"
      name "invalidSpecification"
      type :resourceSpecification
      category "Network Resource"
    end
  end

  actions do
    create :build do
      description "creates a new InvalidSpecification resource instance for build"
      accept [:id, :name, :type, :which]
      change set_attribute(:type, :resource)
      change load [:href]
      upsert? false
    end
  end
end
