# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Broadband do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Broadband - V1 broadband service, demonstrating the simple BaseInstance pattern.
  Technology options include :fttb. The breaking change in BroadbandV2 is the
  removal of :fttb from the supported technology types.
  """
  alias Diffo.Provider.BaseInstance
  alias Diffo.Test.Servo

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Servo

  resource do
    description "A Broadband Service Instance (V1)"
    plural_name :broadbands
  end

  provider do
    specification do
      id "a1b2c3d4-e5f6-4a7b-8c9d-e0f1a2b3c4d5"
      name "broadband"
      type :serviceSpecification
      major_version 1
      description "A broadband access service"
      category "Access"
    end

    behaviour do
      actions do
        create :build
      end
    end
  end

  actions do
    create :build do
      accept [:id, :name, :type]
      change set_attribute(:type, :service)
      change load [:href]
      upsert? false
    end
  end
end
