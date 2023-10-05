defmodule WeatherflowTempest.Application do
  @moduledoc false

  use Application

  def start(_type, _agrs) do
    children =
      []
      ++ maybe_start_client()
      ++ maybe_start_pubsub()

    opts = [strategy: :one_for_one, name: WeatherflowTempest]
    Supervisor.start_link(children, opts)
  end

  # The client should not start if the config says not to, but it also should not start
  # in the test environment where it will be started on-demand, but not techincally in
  # "callbacks only" mode.
  defp maybe_start_client() do
    case Application.get_env(:weatherflow_tempest, :callbacks_only) do
      true -> []
      _    -> case Mix.env do
                :test -> []
                _     -> [{WeatherflowTempest.Client, []}]
              end
    end
  end

  # The pubsub needs to be started in the test environment.
  # The possibility to start it in other envs is actually legacy, from when we
  # might have been starting our own custom PubSub. That's not currently a
  # feature, but if we bought that back this is where we'd do it.
  defp maybe_start_pubsub() do
    case Mix.env() do
      :test -> [{Phoenix.PubSub, [name: Application.get_env(:weatherflow_tempest, :pubsub_name)]}]
      _ -> []
    end
  end
end
