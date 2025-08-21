defmodule Diffo.Provider.InstanceSpecification.Transformer do
  @moduledoc false

  use Spark.Dsl.Transformer

  def transform(dsl) do
    {:ok, dsl}
  end
end
