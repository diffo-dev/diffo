# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Info do
  use Spark.InfoGenerator,
    extension: Diffo.Provider.Instance.Extension,
    sections: [:specification, :features, :characteristics]
end
