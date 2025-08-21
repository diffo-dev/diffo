defmodule Diffo.Repo do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference


  Repo - persistance
  """

  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(_stack) do
    config = Application.get_env(:boltx, Bolt)
    Boltx.start_link(config)
  end
end
