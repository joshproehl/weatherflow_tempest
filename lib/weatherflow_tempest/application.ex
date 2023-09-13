defmodule WeatherflowTempest.Application do
  @moduledoc false

  use Application

  def start(_type, _agrs) do
    children = [
    ]
    ++ maybe_start_client()
    ++ maybe_start_pubsub()

    opts = [strategy: :one_for_one, name: WeatherflowTempest]
    Supervisor.start_link(children, opts)
  end

  defp maybe_start_client() do
    case Mix.env() do
      :test -> []
      _ -> [{WeatherflowTempest.Client, []}]
    end
  end

  defp maybe_start_pubsub() do
    case Mix.env() do
      :test -> [{Phoenix.PubSub, [name: Application.get_env(:weatherflow_tempest, :pubsub_name)]}]
      _ -> []
    end
  end
end
