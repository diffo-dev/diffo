defmodule Diffo.Validations.IsTransitionValid do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  IsTransitionValid - Ash Resource Validation checking whether transition is valid
  """
  use Ash.Resource.Validation
  import Untangle

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
    debug(changeset, "changeset")
    debug(opts, "opts")
    next = Atom.to_string(Ash.Changeset.get_argument_or_attribute(changeset, opts[:state]))
    current = Atom.to_string(Ash.Changeset.get_data(changeset, opts[:state]))
    debug(next, "next")
    debug(current, "current")
    loaded_instance = Ash.load!(changeset.data, [opts[:transition_map]], lazy?: true, reuse_values?: true)
    debug(loaded_instance, "loaded_instance")
    transition_map = Map.get(loaded_instance, opts[:transition_map])
    debug(transition_map, "transition_map")
    if (Diffo.Provider.Service.is_transition_valid(transition_map, current, next)) do
      :ok
    else
      # The returned error will be passed into `Ash.Error.to_ash_error/3`
      {:error, field: opts[:attribute], message: "state transition is not valid"}
    end
  end


  # this can be used as follows, where it will validate the transition of an Ash Resource
  # validate {Diffo.Validations.IsTransitionValid, state: :state, transition_map: transition_map}
end
