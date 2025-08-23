  defmodule Diffo.Provider.Instance.Extension.Info do
    use Spark.InfoGenerator, extension: Diffo.Provider.Instance.Extension, sections: [:specification, :features, :characteristics]

  end
