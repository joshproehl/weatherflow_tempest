defmodule WeatherflowTempest.Application do
  @moduledoc false

  use Application

  def start(_type, _agrs) do
    children =
      [] ++
        maybe_start_client()

    opts = [strategy: :one_for_one, name: WeatherflowTempest]
    Supervisor.start_link(children, opts)
  end

  # The client should not start if the config says not to, but it also should not start
  # in the test environment where it will be started on-demand, but not techincally in
  # "callbacks only" mode.
  defp maybe_start_client() do
    case Application.get_env(:weatherflow_tempest, :callbacks_only) do
      true ->
        []

      _ ->
        case Mix.env() do
          :test -> []
          _ -> [{WeatherflowTempest.Client, []}]
        end
    end
  end
end
