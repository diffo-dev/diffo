# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Verifiers.VerifySpecificationKind do
  @moduledoc """
  Verifies the declared `specification do type` matches the instance's kind:

    * a **Service** leaf (composes `Diffo.Provider.Service`) must declare
      `type :serviceSpecification`
    * a **Resource** leaf (composes `Diffo.Provider.Resource`) must declare
      `type :resourceSpecification`

  The kind is detected by the discriminating attribute each subtype fragment
  contributes — `:state` for Service, `:lifecycle_state` for Resource. A resource
  that declares no specification (e.g. the generic `Diffo.Provider.Instance`), or
  that composes neither subtype fragment, is not checked.

  This is the compile-time guard carried over from #191: it keeps an instance and
  its specification on the same side of the Service/Resource divide.
  """
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError

  @impl true
  def verify(dsl_state) do
    spec_type = Verifier.get_option(dsl_state, [:provider, :specification], :type)

    case {spec_type, instance_kind(dsl_state)} do
      {nil, _} -> :ok
      {_, nil} -> :ok
      {:serviceSpecification, :service} -> :ok
      {:resourceSpecification, :resource} -> :ok
      {spec_type, kind} -> {:error, mismatch_error(dsl_state, spec_type, kind)}
    end
  end

  defp instance_kind(dsl_state) do
    attribute_names =
      dsl_state |> Verifier.get_entities([:attributes]) |> Enum.map(& &1.name)

    cond do
      :state in attribute_names -> :service
      :lifecycle_state in attribute_names -> :resource
      true -> nil
    end
  end

  defp mismatch_error(dsl_state, spec_type, kind) do
    resource = Verifier.get_persisted(dsl_state, :module)
    expected = if kind == :service, do: :serviceSpecification, else: :resourceSpecification

    DslError.exception(
      module: resource,
      path: [:provider, :specification, :type],
      message:
        "specification: a #{kind} instance must declare type #{inspect(expected)}, got #{inspect(spec_type)}"
    )
  end
end
