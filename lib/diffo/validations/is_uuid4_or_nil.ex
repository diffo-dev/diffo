defmodule Diffo.Validations.IsUuid4OrNil do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference


  IsUuid4OrNil - Ash Resource Validation checking uuid is v4 if supplied
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
    value = Ash.Changeset.get_attribute(changeset, opts[:attribute])

    if Diffo.Uuid.uuid4_or_nil?(value) do
      :ok
    else
      # The returned error will be passed into `Ash.Error.to_ash_error/3`
      {:error, field: opts[:attribute], message: "must be a uuid v4 or nil"}
    end
  end

  @impl true
  def atomic(changeset, opts, context) do
    validate(changeset, opts, context)
  end

  # this can be used as follows, where it will validate the :id value of an Ash Resource
  # validate {Diffo.Validations.IsUuid4OrNil, attribute: :id}
end
