# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defimpl Diffo.Unwrap, for: List do
  @moduledoc false

  def unwrap(list), do: Enum.map(list, &Diffo.Unwrap.unwrap/1)
end
