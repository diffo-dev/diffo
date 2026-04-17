# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defprotocol Diffo.Unwrap do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Unwrap - A Diffo protocol for unwrapping values
  """

  @fallback_to_any true
  def unwrap(value)
end
