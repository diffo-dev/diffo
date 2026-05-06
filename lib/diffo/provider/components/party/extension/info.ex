# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party.Extension.Info do
  use Spark.InfoGenerator,
    extension: Diffo.Provider.Party.Extension,
    sections: [:instances, :parties, :places]

  @doc "Returns true if the module is a BaseParty-derived resource"
  @spec party?(module()) :: boolean()
  def party?(module) do
    Code.ensure_loaded?(module) and
      Diffo.Provider.Party.Extension in Ash.Resource.Info.extensions(module)
  end
end
