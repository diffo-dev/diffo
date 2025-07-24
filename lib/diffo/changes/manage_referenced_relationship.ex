defmodule Diffo.Changes.ManageReferencedRelationship do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  ManageReferencedRelationship - Manage a relationship where the relationship name is an argument value
  """
  use Ash.Resource.Change

  # transform and validate opts
  @impl true
  def init(opts) do
    if is_atom(opts[:relationship_name_field]) do
      if is_atom(opts[:argument]) do
        {:ok, opts}
      else
        {:error, "argument must be an atom"}
      end
    else
      {:error, "relationship_name_field must be an atom"}
    end
  end

  @impl true
  def change(changeset, opts, _context) do
    IO.inspect(changeset, label: :changeset)
    IO.inspect(opts, label: :opts)

    case Ash.Changeset.fetch_change(changeset, opts[:relationship_name_field]) do
      {:ok, relationship_name} ->
        IO.inspect(relationship_name, label: :relationship_name)

        case argument = opts[:argument] do
          nil ->
            changeset

          _ ->
            IO.inspect(argument, label: :argument)

            Ash.Changeset.manage_relationship(argument, relationship_name,
              type: :append_and_remove
            )
        end

      :error ->
        changeset
    end
  end
end
