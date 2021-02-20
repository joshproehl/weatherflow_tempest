defmodule WeatherflowTempest.Application do
  @moduledoc false

  use Application

  def start(_type, _agrs) do
    children = [
      {Phoenix.PubSub, [name: Application.get_env(:weatherflow_tempest, :pubsub_name, :weatherflow_tempest)]},
      {WeatherflowTempest.Client, []},
    ]

    opts = [strategy: :one_for_one, name: WeatherflowTempest]
    Supervisor.start_link(children, opts)
  end
end
