defmodule WeatherflowTempest do
  # doc delegation won't work before we're on ExDoc 0.23
  
  #@doc delegate_to: {WeatheflowTempest.Client, :get_latest, 0}
  @doc "Delegated to `WeatherflowTempest.Client.get_latest/0` for convenience"
  defdelegate get_latest, to: WeatherflowTempest.Client

  #@doc delegate_to: {WeatheflowTempest.Client, :get_packet_stats, 0}
  @doc "Delegated to `WeatherflowTempest.Client.get_packet_stats/0` for convenience"
  defdelegate get_packet_stats, to: WeatherflowTempest.Client

  #@doc delegate_to: {WeatheflowTempest.Client, :get_hub_serials, 0}
  @doc "Delegated to `WeatherflowTempest.Client.get_hub_serials/0` for convenience"
  defdelegate get_hub_serials, to: WeatherflowTempest.Client
end
