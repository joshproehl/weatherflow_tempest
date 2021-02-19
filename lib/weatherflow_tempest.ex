defmodule WeatherflowTempest do
  defdelegate get_latest, to: WeatherflowTempest.Client
  defdelegate get_packet_stats, to: WeatherflowTempest.Client
end
