# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defimpl Diffo.Unwrap, for: Ash.Union do
  def unwrap(%{value: value}), do: Diffo.Unwrap.unwrap(value)
end
