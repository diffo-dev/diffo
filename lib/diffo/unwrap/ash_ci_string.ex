# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defimpl Diffo.Unwrap, for: Ash.CiString do
  @moduledoc false

  def unwrap(ci_string), do: Ash.CiString.to_comparable_string(ci_string)
end
