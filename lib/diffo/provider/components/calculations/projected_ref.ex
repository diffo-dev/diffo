# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.ProjectedRef do
  @moduledoc """
  Reusable cross-world projection calculation.

  Replaces typed `belongs_to` for cross-resource references where the target's
  concrete subtype isn't known at the source resource's compile time. The calc
  resolves the target to its outermost concrete world at read time via
  `AshNeo4j.worlds/1` — late-binding by design, open-world by construction.

  Used by `Diffo.Provider.PlaceRef` and `Diffo.Provider.PartyRef` to replace
  their `belongs_to` relationships pointing at the generic Place/Party/Instance
  abstract readers. Also usable directly on consumer leaves that want to point
  at any subtype across the cascade (e.g. `BaseGeographicSite.address` →
  `GeographicAddress` or consumer-domain Address leaf).

  ## Usage

      calculate :place, :struct,
        {Diffo.Provider.Calculations.ProjectedRef,
         [id_field: :place_id, reader: Diffo.Provider.Place]}

  ## Options

    * `:id_field` (atom, required) — the attribute on the calculated record that
      holds the target's id.
    * `:reader` (module, required) — the *abstract reader* resource for the
      target type. Lets the calc do a bootstrap `Ash.get` to load the target
      node so `AshNeo4j.worlds/1` can project it to its outermost concrete
      world. For diffo built-ins: `Diffo.Provider.Place`, `Diffo.Provider.Party`,
      `Diffo.Provider.Instance` — each kept in core minimally for this role.

  ## Result per input record

    * `nil` — the source record's `id_field` is `nil` (legitimate absence; no
      ref to project).
    * concrete struct — the outermost concrete world's resource, loaded with
      all subtype-specific attributes.
    * `%Diffo.Unknown{}` — `id_field` is set but the target couldn't be
      projected (see reason vocabulary).

  Plus the standard `%Ash.NotLoaded{}` until the calc is loaded.

  ## Reason vocabulary (local to the calling record's world)

    * `:no_target` — bootstrap `Ash.get` failed; target id doesn't exist in the
      graph. Context carries `%{id_field: atom, target_id: id, reader: module}`.
    * `:no_concrete_world` — bootstrap loaded but `AshNeo4j.worlds/1` returned
      `[]`. Context carries `%{id_field: atom, target_id: id}`.
    * `:projection_failed` — projection identified a concrete world but its
      `Ash.get` failed. Rare; indicates a Neo4j label / Ash resource mismatch.
      Context carries `%{id_field: atom, target_id: id, resource: module}`.

  Per the **Cross-domain lookups** AGENTS.md section, reasons are world-local —
  consumers in other worlds should treat them as opaque and (if composing) wrap
  via `:inner_unknown`.

  ## `:world` stamping

  Each `%Diffo.Unknown{}` is stamped with `record.__struct__` — the consumer's
  concrete resource (e.g. `Diffo.Provider.PlaceRef` or `MyApp.SomeRef`). No
  transformer injection needed because the calc runs per-record at runtime and
  the consumer's resource is directly available from the record.
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    id_field = Keyword.fetch!(opts, :id_field)
    reader = Keyword.fetch!(opts, :reader)

    Enum.map(records, fn record ->
      world = record.__struct__

      case Map.get(record, id_field) do
        nil ->
          nil

        target_id ->
          project(reader, target_id, id_field, world)
      end
    end)
  end

  defp project(reader, target_id, id_field, world) do
    reader_domain = Ash.Resource.Info.domain(reader)

    case Ash.get(reader, target_id, domain: reader_domain) do
      {:error, _} ->
        %Diffo.Unknown{
          world: world,
          reason: :no_target,
          context: %{id_field: id_field, target_id: target_id, reader: reader}
        }

      {:ok, target} ->
        case AshNeo4j.worlds(target) do
          [{_, projected_resource} | _] ->
            load_concrete(projected_resource, target_id, id_field, world)

          [] ->
            %Diffo.Unknown{
              world: world,
              reason: :no_concrete_world,
              context: %{id_field: id_field, target_id: target_id}
            }
        end
    end
  end

  defp load_concrete(resource, target_id, id_field, world) do
    domain = Ash.Resource.Info.domain(resource)

    case Ash.get(resource, target_id, domain: domain) do
      {:ok, projected} ->
        projected

      {:error, _} ->
        %Diffo.Unknown{
          world: world,
          reason: :projection_failed,
          context: %{id_field: id_field, target_id: target_id, resource: resource}
        }
    end
  end
end
