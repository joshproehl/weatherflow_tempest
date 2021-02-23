defmodule WeatherflowTempest.Application do
  @moduledoc false

  use Application

  def start(_type, _agrs) do
    children = [
      {WeatherflowTempest.Client, []},
    ]
    ++ maybe_start_pubsub()

    opts = [strategy: :one_for_one, name: WeatherflowTempest]
    Supervisor.start_link(children, opts)
  end

  defp maybe_start_pubsub() do
    case Application.get_env(:weatherflow_tempest, :pubsub_name) do
      nil -> [{Phoenix.PubSub, [name: WeatherflowTempest.PubSub.get_pubsub_name()]}]
      _ -> []
    end
  end
end
