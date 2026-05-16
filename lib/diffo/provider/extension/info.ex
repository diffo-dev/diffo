# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Info do
  use Spark.InfoGenerator,
    extension: Diffo.Provider.Extension,
    sections: [:provider]

  @doc "Returns true if the module is a BaseInstance-derived resource"
  @spec instance?(module()) :: boolean()
  def instance?(module) do
    Code.ensure_loaded?(module) and
      Diffo.Provider.Instance.Extension in Ash.Resource.Info.extensions(module)
  end

  @doc "Returns true if the module is a BaseParty-derived resource"
  @spec party?(module()) :: boolean()
  def party?(module) do
    Code.ensure_loaded?(module) and
      Diffo.Provider.Party.Extension in Ash.Resource.Info.extensions(module)
  end

  @doc "Returns true if the module is a BasePlace-derived resource"
  @spec place?(module()) :: boolean()
  def place?(module) do
    Code.ensure_loaded?(module) and
      Diffo.Provider.Place.Extension in Ash.Resource.Info.extensions(module)
  end
end
