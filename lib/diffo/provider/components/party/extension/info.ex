# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party.Extension.Info do
  use Spark.InfoGenerator,
    extension: Diffo.Provider.Party.Extension,
    sections: [:instance, :party]
end
