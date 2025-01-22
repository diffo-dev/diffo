defmodule Diffo.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [Diffo.Repo]

    opts = [strategy: :one_for_one, name: Diffo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
