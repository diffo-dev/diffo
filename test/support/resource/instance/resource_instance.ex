# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Instance.ResourceInstance do
  @moduledoc """
  Generic Resource test leaf — `BaseInstance` + `Resource` with no fixed
  specification DSL. The resource-flavoured counterpart to
  `Diffo.Test.Instance.ServiceInstance`; created via `Diffo.Test.create_instance!/1`
  when the specification is a `:resourceSpecification`. Inherits the shared
  `:create` action (accepting `specified_by`) from `BaseInstance`.
  """
  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Resource

  use Ash.Resource,
    fragments: [BaseInstance, Resource],
    domain: Diffo.Test.Servo

  resource do
    description "A generic Resource test instance"
    plural_name :resource_instances
  end
end
