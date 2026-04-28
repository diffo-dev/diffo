# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Verifiers.VerifySpecification do
  @moduledoc "Verifies that the specification id is a valid UUID4"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    spec_id = Verifier.get_option(dsl_state, [:structure, :specification], :id)

    errors =
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

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end
end
