defmodule Diffo.Provider.Service do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Service - utilities relating to service
  """

  def service_states() do
    [:initial, :feasibilityChecked, :reserved, :inactive, :active, :suspended, :cancelled, :terminated]
  end

  def default_service_state do
    :initial
  end

  def service_operating_statuses() do
    [:pending, :configured, :starting, :running, :degraded, :failed, :limited, :stopping, :stopped, :unknown]
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

  def service_state_transition_map() do
    Aja.OrdMap.new([
      {:initial, [:feasibilityChecked, :reserved, :inactive, :active, :cancelled]},
      {:feasibilityChecked, [:reserved, :inactive, :active, :cancelled]},
      {:reserved, [:inactive, :active, :cancelled]},
      {:inactive, [:active, :terminated]},
      {:active, [:inactive, :suspended, :terminated]},
      {:suspended, [:active, :terminated]}
    ])
  end

  @doc """
  Removes unsupported states from a state transition map
  ## Examples
    iex> Diffo.Provider.Service.service_state_transition_map()
    ...> |> Diffo.Provider.Service.remove_states([:reserved, :suspended, :inactive])
    ...> |> Diffo.Provider.Service.list_transitions()
    [ initial: :feasibilityChecked,
      initial: :active,
      initial: :cancelled,
      feasibilityChecked: :active,
      feasibilityChecked: :cancelled,
      active: :terminated
    ]

  """
  def remove_states(map, unsupported_states) do
    #  drop unsupported_state keys and remove unsupported_state values from remaining supported keys, leaving only supported states in keys and values
    for {key, val} <- Aja.OrdMap.drop(map, unsupported_states), into: %Aja.OrdMap{}, do:
      {key, Enum.reject(val, fn x -> x in unsupported_states end)}
  end

  @doc """
  Lists the transitions allowed by a state transition map
  ## Examples
    iex> Diffo.Provider.Service.service_state_transition_map()
    ...> |> Diffo.Provider.Service.remove_states([:reserved, :suspended, :inactive])
    ...> |> Diffo.Provider.Service.list_transitions()
    [ initial: :feasibilityChecked,
      initial: :active,
      initial: :cancelled,
      feasibilityChecked: :active,
      feasibilityChecked: :cancelled,
      active: :terminated
    ]

  """
  def list_transitions(map) do
    # we want an entry for each transition
    for state <- Aja.OrdMap.keys(map), next_state <- map[state], into: [] do
      {state, next_state}
    end
  end

  @doc """
  Removes a transition from the state transition map
    ## Examples
    iex> Diffo.Provider.Service.service_state_transition_map()
    ...> |> Diffo.Provider.Service.remove_states([:reserved, :suspended, :inactive])
    ...> |> Diffo.Provider.Service.remove_transition({:initial, :active})
    ...> |> Diffo.Provider.Service.list_transitions()
    [ initial: :feasibilityChecked,
      initial: :cancelled,
      feasibilityChecked: :active,
      feasibilityChecked: :cancelled,
      active: :terminated
    ]

  """
    def remove_transition(map, {current, next}) do
    {_current_value, updated} = Aja.OrdMap.get_and_update(map, current, fn next_states -> {current, List.delete(next_states, next)} end)
    updated
  end


  @doc """
  Indicates whether the transition is valid
  ## Examples
    iex> map = Diffo.Provider.Service.service_state_transition_map()
    iex> Diffo.Provider.Service.is_transition_valid(map, {:active, :terminated})
    true
    iex> Diffo.Provider.Service.is_transition_valid(map, {:active, :cancelled})
    false
  """
  def is_transition_valid(map, {current, next}) do
    next in map[current]
  end
end
