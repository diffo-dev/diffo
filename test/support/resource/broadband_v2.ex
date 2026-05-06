# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.BroadbandV2 do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  BroadbandV2 - V2 broadband service. Breaking change from V1: :fttb has been
  removed from supported technology types, requiring data remediation on any V1
  instance with technology: :fttb before respecification.
  """
  alias Diffo.Provider.BaseInstance
  alias Diffo.Test.Servo

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Servo

  resource do
    description "A Broadband Service Instance (V2)"
    plural_name :broadband_v2s
  end

  structure do
    specification do
      id "f6e5d4c3-b2a1-4f0e-9d8c-7b6a5f4e3d2c"
      name "broadband"
      type :serviceSpecification
      major_version 2
      description "A broadband access service — :fttb technology retired"
      category "Access"
    end
  end

  behaviour do
    actions do
      create :build
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
