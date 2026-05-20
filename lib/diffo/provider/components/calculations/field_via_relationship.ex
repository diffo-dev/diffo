# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.FieldViaRelationship do
  @moduledoc """
  Reads a field from target instances reached via `DefinedSimpleRelationship`.

  Traverses `DefinedSimpleRelationship` in the forward direction — filtering by
  `source_id = current.id` — and returns the named field from each resolved target
  instance. Both `type:` and `alias:` are optional filters; when omitted they match
  any value on that dimension.

  ## Options

  - `field:` *(required)* — atom naming the field to read from the target instance
    (e.g. `:name`, `:type`).
  - `alias:` *(optional)* — atom matching the `alias` attribute on the relationship.
    When omitted, relationships with any alias (including nil) are included.
  - `type:` *(optional)* — atom matching the `type` attribute on the relationship
    (e.g. `:assignedTo`, `:reliesOn`). When omitted, all types are included.

  Providing neither filter returns fields from every forward `DefinedSimpleRelationship`
  on this instance. In practice at least one of `alias:` or `type:` should be supplied,
  since a source instance typically has many forward relationships pointing to unrelated
  things.

  ## Examples

      # Name of the target reached via the :provides alias
      calculate :provider_name, {:array, :string},
        {Diffo.Provider.Calculations.FieldViaRelationship, [alias: :provides, field: :name]}

      # Name of the target reached via the :link alias, restricted to :assignedTo type
      calculate :assigned_linked_name, {:array, :string},
        {Diffo.Provider.Calculations.FieldViaRelationship,
         [type: :assignedTo, alias: :link, field: :name]}
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    alias_name = opts[:alias]
    type = opts[:type]
    field = opts[:field]

    Enum.map(records, fn record ->
      filter = [source_id: record.id]
      filter = if type, do: Keyword.put(filter, :type, type), else: filter
      filter = if alias_name, do: Keyword.put(filter, :alias, alias_name), else: filter

      Diffo.Provider.DefinedSimpleRelationship
      |> Ash.Query.filter_input(filter)
      |> Ash.read!(domain: Diffo.Provider)
      |> Enum.flat_map(fn rel ->
        Diffo.Provider.Instance
        |> Ash.Query.filter_input(id: rel.target_id)
        |> Ash.read!(domain: Diffo.Provider)
        |> Enum.map(&Map.get(&1, field))
      end)
    end)
  end
end
