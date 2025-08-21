defmodule Diffo.Provider.Service do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference


  Service - utilities relating to service
  """

  def service_states() do
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

  def default_service_state do
    :initial
  end

  def service_operating_statuses() do
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

  def default_service_operating_status() do
    :unknown
  end

  def default_service_operating_status(state) do
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
