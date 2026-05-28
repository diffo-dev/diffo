# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Unknown do
  @moduledoc """
  Sentinel value for *"we tried and couldn't determine this in our current view
  of the graph"* — the X state, complementary to Ash's `NotLoaded` (the U state).

  `NotLoaded` represents the load-lifecycle "uninitialised" — the value wasn't
  loaded yet; ask again. `Unknown` represents the post-resolution "tried and
  couldn't" — the calc ran, the cross-world lookup didn't yield a value. Both
  are explicit values; consumers pattern-match them as distinct outcomes
  alongside concrete values and `nil`.

  ## Shape

      %Diffo.Unknown{
        world:   MyApp.SomeResource,   # outermost (Domain, Resource) producer — stored as Resource
        reason:  :role_not_declared,   # world-local atom; vocabulary owned by the producing world
        context: %{role: :uni, …}      # world-local diagnostic data
      }

  `:world` is the outermost `(Domain, Resource)` pair the Unknown was produced
  under, stored as the **Resource module** since the Domain is derivable via
  `Ash.Resource.Info.domain/1`. The Domain alone is insufficient — within a
  single Domain, multiple concrete resources can extend the same base fragment
  (e.g. `Diffo.Provider.AssignmentRelationship` and
  `Diffo.Provider.DefinedSimpleRelationship` are distinct worlds in the same
  Domain). Together Domain + Resource identify the producer uniquely.

  `:reason` is `atom()` at the structural level only — no enum narrowing. Each
  calc moduledoc declares its own reason vocabulary; the central type stays
  open. Reasons are world-local; the producing world owns the vocabulary.

  `:context` is `term()` — each world decides what to put there. Diagnostic,
  not load-bearing.

  ## Discipline (per `AGENTS.md`)

  - **Compile-time stamping of `:world`.** Transformers that inject
    cross-boundary calcs pass the consumer's resource as an opt; the calc
    stamps it on every Unknown it emits. No runtime resource lookup needed.
  - **Calcs are total.** A calc that crosses a boundary never raises on
    missing data — it returns the value, `nil`, or `%Diffo.Unknown{}`. The
    consumer pattern-matches.
  - **Projection across worlds, free composition within.** An outer-world
    calc that encounters an inner-world Unknown wraps it
    (`%Diffo.Unknown{world: OuterResource, reason: :inner_unknown, context:
    %{inner: original}}`); calcs within the same world share vocabulary and
    can read each other's `:reason` directly without projecting through.
  - **No central reason registry.** Resist the urge to enumerate reasons
    anywhere shared. Each world documents its vocabulary in the moduledocs
    of the calcs that produce it.
  - **The metadata describes the producer only.** The consumer brings its
    own world context. AshNeo4j-side: see `AshNeo4j.worlds/1` for the
    symmetric "outer-world metadata on reads" primitive.
  """

  defstruct [:world, :reason, :context]

  @type t :: %__MODULE__{
          world: module(),
          reason: atom(),
          context: term()
        }

  @doc """
  Returns the Ash Domain of the producing world (the outermost world that
  emitted this Unknown). Derived from `:world` via `Ash.Resource.Info.domain/1`.
  """
  @spec domain(t()) :: module() | nil
  def domain(%__MODULE__{world: world}) when is_atom(world) and not is_nil(world) do
    Ash.Resource.Info.domain(world)
  end

  def domain(%__MODULE__{}), do: nil
end
