defmodule WeatherflowTempest do
  defdelegate get_latest, to: WeatherflowTempest.Client
  defdelegate get_packet_stats, to: WeatherflowTempest.Client
  defdelegate get_hub_serials, to: WeatherflowTempest.Client
end
