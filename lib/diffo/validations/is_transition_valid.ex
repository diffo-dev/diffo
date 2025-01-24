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
    new = Ash.Changeset.get_attribute(changeset, opts[:attribute])
    current = Ash.Changeset.get_data(changeset, opts[:attribute])
    transition_graph = opts[:transition_graph]
    # todo, determine if the transition is valid
    if (new == current) do
      :ok
    else
      if (new in transition_graph[current]) do
        :ok
      else
        # The returned error will be passed into `Ash.Error.to_ash_error/3`
        {:error, field: opts[:attribute], message: "transition is not valid"}
      end
    end
  end

  @impl true
  def atomic(changeset, opts, context) do
    validate(changeset, opts, context)
  end

  # this can be used as follows, where it will validate the transition of an Ash Resource
  # validate {Diffo.Validations.IsTransitionValid, attribute: :service_state, transition_graph: transition_graph}
end
