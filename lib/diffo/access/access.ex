defmodule Diffo.Access do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Access - example domain
  """
  use Ash.Domain,
    otp_app: :diffo

  alias Diffo.Access.DslAccess
  alias Diffo.Access.Shelf
  alias Diffo.Access.Card
  alias Diffo.Access.Cable
  alias Diffo.Access.Path

  resources do
    resource DslAccess do
      define :get_dsl_by_id, action: :read, get_by: :id
      define :qualify_dsl, action: :qualify
      define :qualify_dsl_result, action: :qualify_result
      define :design_dsl_result, action: :design_result
    end

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

    resource Cable do
      define :get_cable_by_id, action: :read, get_by: :id
      define :build_cable, action: :build
      define :define_cable, action: :define
      define :relate_cable, action: :relate
      define :assign_pair, action: :assign_pair
    end

    resource Path do
      define :get_path_by_id, action: :read, get_by: :id
      define :build_path, action: :build
      define :define_path, action: :define
      define :relate_path, action: :relate
    end
  end
end
