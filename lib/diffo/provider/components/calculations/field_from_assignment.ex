# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.FieldFromAssignment do
  @moduledoc """
  Reads a field directly from an `AssignmentRelationship` record.

  Filters `AssignmentRelationship` by `target_id = current.id` and returns the named
  field from each matching record — no second hop to the source instance. This is the
  right choice when you want a value that lives on the relationship itself (`:value`,
  `:thing`, `:pool`, `:alias`) rather than on the assigning instance.

  Use `FieldViaAssignedRelationship` instead when you need a field from the source
  instance (e.g. `:name`).

  ## Options

  - `field:` *(required)* — atom naming the field to read from the relationship record
    (e.g. `:value`, `:thing`, `:pool`, `:alias`).
  - `alias:` *(optional)* — atom matching the `alias` attribute on the relationship.
    When omitted, all assignments where `target_id = current.id` are included.

  ## Examples

      # Port number assigned to this service under the :primary slot
      calculate :assigned_port, {:array, :integer},
        {Diffo.Provider.Calculations.FieldFromAssignment, [alias: :primary, field: :value]}

      # Pool name for every assignment on this instance
      calculate :assignment_pools, {:array, :atom},
        {Diffo.Provider.Calculations.FieldFromAssignment, [field: :pool]}
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    alias_name = opts[:alias]
    field = opts[:field]

    Enum.map(records, fn record ->
      record.id
      |> assignments(alias_name)
      |> Enum.map(&Map.get(&1, field))
    end)
  end

  defp assignments(id, nil) do
    Diffo.Provider.AssignmentRelationship
    |> Ash.Query.filter_input(target_id: id)
    |> Ash.read!(domain: Diffo.Provider)
  end

  defp assignments(id, alias_name) do
    Diffo.Provider.AssignmentRelationship
    |> Ash.Query.filter_input(target_id: id, alias: alias_name)
    |> Ash.read!(domain: Diffo.Provider)
  end
end
