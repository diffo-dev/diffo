# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Place.Extension do
  @moduledoc """
  DSL Extension customising a Place.

  Provides compile-time declaration blocks for domain-specific Place kinds
  built on `Diffo.Provider.BasePlace`. All declarations are introspectable via
  `Diffo.Provider.Place.Extension.Info`.

  See the [DSL cheat sheet](DSL-Diffo.Provider.Place.Extension.html) for the full DSL reference.
  See `Diffo.Provider.BasePlace` for full usage documentation.
  """
  use Spark.Dsl.Extension, sections: []
end
