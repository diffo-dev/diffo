defmodule Diffo.Validations.RelatedResourcesDifferent do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  RelatedResourcesDifferentNames - Ash Resource Validation checking related Resources are different
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    if is_atom(opts[:relationship]) do
      if is_atom(opts[:attribute]) do
        {:ok, opts}
      else
        {:error, ":attribute must be an atom!"}
      end
    else
      {:error, "relationship must be an atom!"}
    end
  end

  @impl true
  def validate(changeset, opts, _context) do
    IO.inspect(changeset, label: :related_resources_different_names_changeset)
    IO.inspect(opts, opts: :related_resources_different_names_opts)
    :ok
  end

  # this can be used as follows, where it will validate using that related characteristic have different name values
  # validate {Diffo.Validations.RelatedResourcesDifferent, relationship: :characteristic, attribute: :name}
end
