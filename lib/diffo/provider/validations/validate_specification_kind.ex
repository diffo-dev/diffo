# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Validations.ValidateSpecificationKind do
  @moduledoc """
  Validates that the specification an instance is being specified by matches the
  instance kind: a **Service** must be specified by a `:serviceSpecification`, a
  **Resource** by a `:resourceSpecification`.

  Runtime counterpart to the compile-time
  `Diffo.Provider.Extension.Verifiers.VerifySpecificationKind`. The verifier guards
  the statically-declared `specification do type` on consumer leaves; this guards
  the specification associated **at runtime** via the `specified_by` argument —
  covering generic instances (`Provider.Instance` and resource leaves with no spec
  DSL) and `respecify`, which the verifier cannot see.

  Declared on the `Service` / `Resource` fragments with the expected spec type, so
  each kind carries its own constraint. A no-op on changes that do not set
  `specified_by`. A missing/unreadable spec is left to other machinery — this
  validation only rejects a *present, wrong-kind* specification.
  """
  use Ash.Resource.Validation

  alias Ash.Changeset

  @impl true
  def init(opts) do
    case opts[:expected] do
      kind when kind in [:serviceSpecification, :resourceSpecification] ->
        {:ok, opts}

      other ->
        {:error,
         "expected: must be :serviceSpecification or :resourceSpecification, got #{inspect(other)}"}
    end
  end

  @impl true
  def validate(changeset, opts, _context) do
    expected = opts[:expected]

    case Changeset.get_argument(changeset, :specified_by) do
      nil ->
        :ok

      specified_by ->
        case Diffo.Provider.get_specification_by_id(specified_by) do
          {:ok, %{type: ^expected}} ->
            :ok

          {:ok, %{type: actual}} ->
            {:error, field: :specified_by, message: error_message(expected, actual)}

          {:error, _} ->
            :ok
        end
    end
  end

  defp error_message(expected, actual) do
    "specification kind mismatch: expected a #{inspect(expected)}, got #{inspect(actual)}"
  end
end
