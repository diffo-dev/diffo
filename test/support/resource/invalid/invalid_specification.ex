# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.InvalidSpecification do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  InvalidSpecification - Resource Instance with an Invalid Specification
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.ActionHelper

  alias Diffo.Test.Servo

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Servo

  resource do
    description "Ash Resource with an invalid specification"
  end

  specification do
    id "ef016d85-9dbd-429c-04da-1df56cc7dda5"
    name "invalidSpecification"
    type :resourceSpecification
    category "Network Resource"
  end

  actions do
    create :build do
      description "creates a new InvalidSpecification resource instance for build"
      accept [:id, :name, :type, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context ->
               ActionHelper.build_before(changeset)
             end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(
                 changeset,
                 result,
                 Servo,
                 :get_invalid_specification_by_id
               )
             end)

      change load [:href]
      upsert? false
    end
  end
end
