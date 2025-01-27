defmodule Diffo.Validations.IsTransitionValid do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  IsTransitionValid - Ash Resource Validation checking whether transition is valid
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    if is_atom(opts[:attribute]) do
      {:ok, opts}
    else
      {:error, "attribute must be an atom!"}
    end
  end

  @impl true
  def validate(changeset, opts, _context) do
    next = Ash.Changeset.get_attribute(changeset, opts[:attribute])
    current = Ash.Changeset.get_data(changeset, opts[:attribute])
    transition_map = Diffo.Provider.Service.service_state_transition_map
    # todo, determine if the transition is valid
    if (next == current) do
      :ok
    else
      if (Diffo.Provider.Service.is_transition_valid(transition_map, {current, next})) do
        :ok
      else
        # The returned error will be passed into `Ash.Error.to_ash_error/3`
        {:error, field: opts[:attribute], message: "state transition is not valid"}
      end
    end
  end

  @impl true
  def atomic(changeset, opts, context) do
    validate(changeset, opts, context)
  end

  # this can be used as follows, where it will validate the transition of an Ash Resource
  # validate {Diffo.Validations.IsTransitionValid, attribute: :state, transition_map: transition_map}
end
