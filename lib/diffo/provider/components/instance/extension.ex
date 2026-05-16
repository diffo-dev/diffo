# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension do
  @moduledoc "Marker extension — identifies BaseInstance-derived resources. DSL is in `Diffo.Provider.Extension`."
  use Spark.Dsl.Extension, sections: []
end
