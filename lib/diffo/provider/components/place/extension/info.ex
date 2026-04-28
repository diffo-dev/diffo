# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Place.Extension.Info do
  use Spark.InfoGenerator,
    extension: Diffo.Provider.Place.Extension,
    sections: []

  @doc "Returns true if the module is a BasePlace-derived resource"
  @spec place?(module()) :: boolean()
  def place?(module) do
    Code.ensure_loaded?(module) and
      Diffo.Provider.Place.Extension in Ash.Resource.Info.extensions(module)
  end
end
