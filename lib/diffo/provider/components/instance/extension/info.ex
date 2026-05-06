# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Info do
  use Spark.InfoGenerator,
    extension: Diffo.Provider.Instance.Extension,
    sections: [:structure]

  @doc "Returns true if the module is a BaseInstance-derived resource"
  @spec instance?(module()) :: boolean()
  def instance?(module) do
    Code.ensure_loaded?(module) and
      Diffo.Provider.Instance.Extension in Ash.Resource.Info.extensions(module)
  end
end
