# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Verifiers.VerifySpecification do
  @moduledoc "Verifies that the specification DSL values satisfy the Specification resource's attribute constraints"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError

  # Fields validated against Specification attribute constraints (id handled separately)
  @spec_fields [
    :name,
    :type,
    :major_version,
    :minor_version,
    :patch_version,
    :tmf_version,
    :description,
    :category
  ]

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)

    errors = check_id(dsl_state, resource) ++ check_attributes(dsl_state, resource)

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  defp check_id(dsl_state, resource) do
    spec_id = Verifier.get_option(dsl_state, [:structure, :specification], :id)

    if spec_id && !Diffo.Uuid.uuid4?(spec_id) do
      [
        DslError.exception(
          module: resource,
          path: [:structure, :specification, :id],
          message: "specification: id must be a valid UUID4"
        )
      ]
    else
      []
    end
  end

  defp check_attributes(dsl_state, resource) do
    spec_attrs =
      Ash.Resource.Info.attributes(Diffo.Provider.Specification)
      |> Map.new(&{&1.name, &1})

    Enum.flat_map(@spec_fields, fn field ->
      value = Verifier.get_option(dsl_state, [:structure, :specification], field)
      attr = Map.get(spec_attrs, field)

      if not is_nil(value) && not is_nil(attr) do
        case Ash.Type.apply_constraints(attr.type, value, attr.constraints) do
          {:ok, _} ->
            []

          {:error, errors} ->
            [
              DslError.exception(
                module: resource,
                path: [:structure, :specification, field],
                message: "specification: #{field} - #{format_errors(errors)}"
              )
            ]
        end
      else
        []
      end
    end)
  end

  defp format_errors(errors) when is_list(errors) do
    if Keyword.keyword?(errors) do
      format_error(errors)
    else
      errors |> Enum.map(&format_error/1) |> Enum.join(", ")
    end
  end

  defp format_error(kwlist) do
    {message, bindings} = Keyword.pop(kwlist, :message, "invalid value")

    Enum.reduce(bindings, message, fn {key, val}, msg ->
      String.replace(msg, "%{#{key}}", to_string(val))
    end)
  end
end
