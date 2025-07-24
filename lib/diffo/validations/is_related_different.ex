defmodule Diffo.Validations.IsRelatedDifferent do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  IsRelatedDifferent - Ash Resource Validation checking related Instance has different attribute value
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    if is_atom(opts[:attribute]) do
      if is_atom(opts[:related_id]) do
        {:ok, opts}
      else
        {:error, ":related_id must be an atom!"}
      end
    else
      {:error, "attribute must be an atom!"}
    end
  end

  @impl true
  @spec validate(Ash.Changeset.t(), nil | maybe_improper_list() | map(), any()) ::
          :ok | {:error, [{:field, any()} | {:message, <<_::256>>}, ...]}
  def validate(changeset, opts, _context) do
    case Ash.Changeset.fetch_argument_or_change(changeset, opts[:related_id]) do
      :error ->
        # related_id isn't changing
        :ok
        {:ok, nil}
        # related_id is nil
        :ok

      {:ok, related_id} ->
        case Diffo.Provider.get_instance_by_id(related_id) do
          {:error, _error} ->
            # no related
            :ok

          {:ok, related} ->
            value = Ash.Changeset.get_attribute(changeset, opts[:attribute])

            case Map.get(related, opts[:attribute]) do
              nil ->
                :ok

              ^value ->
                {:error, field: opts[:attribute], message: "related has same attribute value"}

              _ ->
                :ok
            end
        end
    end
  end

  # this can be used as follows, where it will validate using :which and :twin_id attribute value of an Ash Resource
  # validate {Diffo.Validations.IsRelatedDifferent, attribute: :which, related_id: :twin_id}
end
