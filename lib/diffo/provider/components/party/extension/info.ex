# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party.Extension.Info do
  alias Diffo.Provider.Extension.Info, as: ExtInfo

  @doc "Returns true if the module is a BaseParty-derived resource"
  @spec party?(module()) :: boolean()
  defdelegate party?(module), to: ExtInfo

  @doc false
  defdelegate instances(module), to: ExtInfo, as: :provider_instances

  @doc false
  defdelegate parties(module), to: ExtInfo, as: :provider_parties

  @doc false
  defdelegate places(module), to: ExtInfo, as: :provider_places
end
