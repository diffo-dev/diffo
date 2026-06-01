# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Traversal do
  @moduledoc """
  Compile-time normalisation of a `via:` hop list into a canonical, validated form.

  A traversal is an ordered list of hops, each walking one graph edge in one direction.
  Direction is mechanical and mechanism-independent — it names which end of the stored
  edge *this* instance is on:

  - `:forward` — this instance is the edge `source`; filter `source_id = me`, follow to
    `target_id`.
  - `:reverse` — this instance is the edge `target`; filter `target_id = me`, follow to
    `source_id`.

  Mechanism is `:assignment` (`AssignmentRelationship`) or `:relationship`
  (`DefinedSimpleRelationship`). The two axes are independent, so any
  mechanism × direction combination is a legal hop and chains of any length compose.

  ## User hop forms

  - `alias` *(bare atom)* — shorthand for `{:reverse, assignment: alias}` (inherit from
    your assigner — the common case, and the zero-config default for an omitted `via:`).
  - `{:forward | :reverse, assignment: alias}`
  - `{:forward | :reverse, relationship: type}` — relationship filtered by `type` only.
  - `{:forward | :reverse, relationship: [type: t, alias: a]}` — by `type` and/or `alias`.

  ## Canonical form

  `normalize/2` returns `{:ok, hops}` where each hop is
  `{:forward | :reverse, :assignment | :relationship, selector}` — selector
  `%{alias: a}` for assignment, `%{type: t, alias: a}` for relationship (either of `t`/`a`
  may be `nil`, but not both). On a malformed hop it returns `{:error, reason}` for the
  verifier to surface as a `DslError`.

  Used at compile time by `TransformInheritedRefs` (to inject the calc) and
  `VerifyCharacteristics` (to validate). The runtime counterpart is
  `Diffo.Provider.Calculations.Traversal`.
  """

  @directions [:forward, :reverse]

  @doc """
  Normalises a user `via:` value (or `nil`) into a canonical hop list.

  When `via` is `nil`, defaults to a single reverse-assignment hop keyed by `name`
  (i.e. `via: [name]`). Returns `{:ok, hops}` or `{:error, reason}`.
  """
  def normalize(nil, name) when is_atom(name), do: normalize([name], name)

  def normalize(via, _name) when is_list(via) do
    via
    |> Enum.reduce_while({:ok, []}, fn raw, {:ok, acc} ->
      case normalize_hop(raw) do
        {:ok, hop} -> {:cont, {:ok, [hop | acc]}}
        {:error, _} = err -> {:halt, err}
      end
    end)
    |> case do
      {:ok, hops} -> {:ok, Enum.reverse(hops)}
      err -> err
    end
  end

  def normalize(other, _name), do: {:error, {:invalid_via, other}}

  # Bare atom ⇒ reverse assignment by alias (the shorthand / default).
  defp normalize_hop(alias) when is_atom(alias) and not is_nil(alias),
    do: {:ok, {:reverse, :assignment, %{alias: alias}}}

  defp normalize_hop({direction, opts}) when direction in @directions and is_list(opts) do
    cond do
      Keyword.has_key?(opts, :assignment) ->
        assignment_hop(direction, Keyword.get(opts, :assignment))

      Keyword.has_key?(opts, :relationship) ->
        relationship_hop(direction, Keyword.get(opts, :relationship))

      true ->
        {:error, {:hop_missing_mechanism, {direction, opts}}}
    end
  end

  defp normalize_hop(other), do: {:error, {:invalid_hop, other}}

  defp assignment_hop(direction, alias) when is_atom(alias) and not is_nil(alias),
    do: {:ok, {direction, :assignment, %{alias: alias}}}

  defp assignment_hop(_direction, alias),
    do: {:error, {:assignment_requires_alias, alias}}

  # Relationship selector: a bare `type` atom, or a keyword with `type:` and/or `alias:`.
  defp relationship_hop(direction, type) when is_atom(type) and not is_nil(type),
    do: {:ok, {direction, :relationship, %{type: type, alias: nil}}}

  defp relationship_hop(direction, opts) when is_list(opts) do
    type = Keyword.get(opts, :type)
    alias = Keyword.get(opts, :alias)

    if is_nil(type) and is_nil(alias) do
      {:error, {:relationship_requires_type_or_alias, opts}}
    else
      {:ok, {direction, :relationship, %{type: type, alias: alias}}}
    end
  end

  defp relationship_hop(_direction, other),
    do: {:error, {:relationship_requires_type_or_alias, other}}
end
