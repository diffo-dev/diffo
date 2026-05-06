# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defimpl Diffo.Unwrap, for: Ash.NotLoaded do
  @moduledoc false

  def unwrap(%{field: field}) do
    raise "Diffo.Unwrap: #{field} was not loaded"
  end
end
