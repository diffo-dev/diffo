# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.ServiceState do
  @moduledoc false
  # Service lifecycle vocabulary (TMF638 ServiceStateType / ServiceOperatingStatusType).
  # Lives in its own module so the `Diffo.Provider.Service` fragment can reference these
  # lists in its attribute constraints (a fragment cannot call its own functions inside
  # its own DSL during compilation).

  def states() do
    [
      :initial,
      :feasibilityChecked,
      :reserved,
      :inactive,
      :active,
      :suspended,
      :cancelled,
      :terminated
    ]
  end

  def default_state do
    :initial
  end

  def operating_statuses() do
    [
      :pending,
      :feasible,
      :not_feasible,
      :configured,
      :starting,
      :running,
      :degraded,
      :failed,
      :limited,
      :stopping,
      :stopped,
      :unknown
    ]
  end

  def default_operating_status() do
    :unknown
  end

  def default_operating_status(state) do
    case state do
      :initial -> :pending
      :feasibilityChecked -> :pending
      :reserved -> :pending
      :inactive -> :configured
      :active -> :started
      :suspended -> :limited
      :terminated -> :stopped
      :cancelled -> :unknown
      _ -> :unknown
    end
  end
end
