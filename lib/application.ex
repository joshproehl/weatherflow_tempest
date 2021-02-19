defmodule WeatherflowTempest.Application do
  @moduledoc false

  use Application

  def start(_type, _agrs) do
    children = [
      #{WeatherflowTempest.Supervisor, name: WeatherflowTempest.Supervisor}
      {WeatherflowTempest.Client, []},
    ]

    opts = [strategy: :one_for_one, name: WeatherflowTempest]
    Supervisor.start_link(children, opts)
  end
end
