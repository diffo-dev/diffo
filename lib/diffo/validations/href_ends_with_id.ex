defmodule Diffo.Validations.HrefEndsWithId do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  HrefEndsWithId - Ash Resource Validation checking href ends with id
  """
  use Ash.Resource.Validation

  @impl true
  def init(opts) do
    if is_atom(opts[:id]) do
      if is_atom(opts[:href]) do
        {:ok, opts}
      else
        {:error, ":href attribute must be an atom!"}
      end
    else
      {:error, ":id attribute must be an atom!"}
    end
  end

  @impl true
  def validate(changeset, opts, _context) do
    id = Ash.Changeset.get_attribute(changeset, opts[:id])
    href = Ash.Changeset.get_attribute(changeset, opts[:href])
    if href == nil or String.ends_with?(href, id) do
      :ok
    else
      # The returned error will be passed into `Ash.Error.to_ash_error/3`
      {:error, field: opts[:href], message: "href doesn't end with id"}
    end
  end

  @impl true
  def atomic(changeset, opts, context) do
    validate(changeset, opts, context)
  end

  # this can be used as follows, where it will validate the :id and :href attribute value of an Ash Resource
  # validate {Diffo.Validations.HrefEndsWithId, id: :id, href: :href}
end
