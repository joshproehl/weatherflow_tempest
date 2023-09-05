defmodule WeatherflowTempest do
  @doc delegate_to: {WeatheflowTempest.Client, :get_latest, 0}
  defdelegate get_latest, to: WeatherflowTempest.Client

  @doc delegate_to: {WeatheflowTempest.Client, :get_packet_stats, 0}
  defdelegate get_packet_stats, to: WeatherflowTempest.Client

  @doc delegate_to: {WeatheflowTempest.Client, :get_hub_serials, 0}
  defdelegate get_hub_serials, to: WeatherflowTempest.Client
end
