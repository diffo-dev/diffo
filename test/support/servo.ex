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

  alias Diffo.Test.Shelf
  alias Diffo.Test.Card

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
  end
end
