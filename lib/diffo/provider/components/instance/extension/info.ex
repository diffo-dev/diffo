# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Info do
  alias Diffo.Provider.Extension.Info, as: ExtInfo

  @doc "Returns true if the module is a BaseInstance-derived resource"
  @spec instance?(module()) :: boolean()
  defdelegate instance?(module), to: ExtInfo

  @doc false
  defdelegate structure_parties(module), to: ExtInfo, as: :provider_parties

  @doc false
  defdelegate structure_places(module), to: ExtInfo, as: :provider_places

  @doc false
  defdelegate structure_characteristics(module), to: ExtInfo, as: :provider_characteristics

  @doc false
  defdelegate structure_features(module), to: ExtInfo, as: :provider_features
end
