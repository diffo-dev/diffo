# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Servo do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Servo - a service and resource management domain
  """
  use Ash.Domain,
    otp_app: :diffo,
    validate_config_inclusion?: false

  alias Diffo.Test.Instance.Shelf
  alias Diffo.Test.Instance.Card
  alias Diffo.Test.Instance.Broadband
  alias Diffo.Test.Instance.BroadbandV2
  alias Diffo.Test.Characteristic.Shelf, as: ShelfCharacteristic
  alias Diffo.Test.Characteristic.Card, as: CardCharacteristic
  alias Diffo.Test.Characteristic.DeploymentClass
  alias Diffo.Provider.AssignableCharacteristic

  domain do
    description "service and resource management"
  end

  resources do
    resource Shelf do
      define :get_shelf_by_id, action: :read, get_by: :id
      define :build_shelf, action: :build
      define :define_shelf, action: :define
      define :relate_shelf, action: :relate
      define :assign_slot, action: :assign_slot
    end

    resource Card do
      define :get_card_by_id, action: :read, get_by: :id
      define :build_card, action: :build
      define :define_card, action: :define
      define :relate_card, action: :relate
      define :assign_port, action: :assign_port
    end

    resource Broadband do
      define :build_broadband, action: :build
      define :get_broadband_by_id, action: :read, get_by: :id
    end

    resource BroadbandV2 do
      define :build_broadband_v2, action: :build
      define :get_broadband_v2_by_id, action: :read, get_by: :id
    end

    resource ShelfCharacteristic
    resource CardCharacteristic
    resource DeploymentClass
    resource AssignableCharacteristic
  end
end
