# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Verifiers.VerifyProviderDomain do
  @moduledoc """
  Verifies that a provider resource (Instance / Party / Place — anything composing
  `Diffo.Provider.Extension`) carries the `:Provider` Neo4j label.

  `:Provider` is what makes provider polymorphism work: cross-world projection
  (`Diffo.Provider.get_*_by_id!/1`, `AshNeo4j.worlds/1`) and `PlaceRef` / `PartyRef` /
  `belongs_to` resolution all MATCH on `[:Provider, <base-type>]`. A node gets `:Provider`
  either because its domain *is* `Diffo.Provider` (the built-in leaves — `:Provider` is
  their `domain_label`) or because its domain composes `Diffo.Provider.DomainFragment`
  (which writes `:Provider` as the domain-fragment label).

  Forget the fragment on a consumer domain and the node simply lacks `:Provider`: provider
  readers stop finding it and projection **silently** returns nothing. This verifier turns
  that silent footgun into a compile-time error pointing at the fix.

  ## Resolution (and why it isn't the persisted `:all_labels`)

  We can't trust the `:all_labels` AshNeo4j persists, because its domain-fragment slot is
  resolved with `Code.ensure_loaded?` at compile time — if the domain hasn't loaded yet
  (resource/domain compile order), it bakes a `nil` fragment label even though the node
  *does* get `:Provider` at runtime (where `domain_fragment_label/1` falls back to the
  domain). So we resolve the domain ourselves:

    * `domain_label == :Provider` → fine (built-in / `Diffo.Provider` domain).
    * otherwise resolve the domain (compiling it if needed) and check it emits `:Provider`
      via `AshNeo4j.DataLayer.Domain.Info.neo4j_label/1`.

  If the domain genuinely can't be resolved at this point in compilation, we **stay silent**
  — a best-effort guard never false-positives on a resource that may be correct at runtime.
  In practice the domain is available by the time a consumer's resource compiles, so the
  forgotten-fragment case is caught.
  """
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError

  @impl true
  def verify(dsl_state) do
    if provider_label?(dsl_state) do
      :ok
    else
      {:error, missing_provider_error(dsl_state)}
    end
  end

  # True when the node will carry :Provider — or when we can't determine it (don't
  # false-positive). False only when we can confirm the domain emits no :Provider label.
  defp provider_label?(dsl_state) do
    if Verifier.get_persisted(dsl_state, :domain_label) == :Provider do
      true
    else
      domain = Verifier.get_persisted(dsl_state, :domain)

      with true <- is_atom(domain) and not is_nil(domain),
           {:module, ^domain} <- Code.ensure_compiled(domain),
           true <- function_exported?(domain, :spark_dsl_config, 0) do
        AshNeo4j.DataLayer.Domain.Info.neo4j_label(domain) == {:ok, :Provider}
      else
        # Domain unresolvable here (not loadable / compile cycle) — can't confirm a
        # problem, so don't raise.
        _ -> true
      end
    end
  end

  defp missing_provider_error(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    domain = Verifier.get_persisted(dsl_state, :domain)

    DslError.exception(
      module: resource,
      path: [:provider],
      message:
        "provider: #{inspect(resource)} does not carry the :Provider Neo4j label, so it can't " <>
          "participate in provider polymorphism (cross-world projection, and PlaceRef / " <>
          "PartyRef / belongs_to resolution, all MATCH on :Provider). Its domain " <>
          "#{inspect(domain)} must compose Diffo.Provider.DomainFragment:\n\n" <>
          "    use Ash.Domain, fragments: [Diffo.Provider.DomainFragment]"
    )
  end
end
