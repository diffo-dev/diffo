# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Util do
  @moduledoc false
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  def assert_compile_time_warning(module, message, fun) when is_bitstring(message) do
    output = capture_io(:stderr, fun)
    assert output =~ String.trim_leading("#{module}", "Elixir.")
    assert output =~ message
  end
end
