# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defimpl Diffo.Unwrap, for: Any do
  @moduledoc false

  def unwrap(value), do: value
end
