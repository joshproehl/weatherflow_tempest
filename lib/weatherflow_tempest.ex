defmodule WeatherflowTempest do
  @moduledoc """
  This module is merely used as a convenience for accessing the non-OTP
  functions of the overall library.
  """

  @doc delegate_to: {WeatheflowTempest.Client, :get_latest, 0}
  defdelegate get_latest, to: WeatherflowTempest.Client

  @doc delegate_to: {WeatheflowTempest.Client, :get_packet_stats, 0}
  defdelegate get_packet_stats, to: WeatherflowTempest.Client

  @doc delegate_to: {WeatheflowTempest.Client, :get_hub_serials, 0}
  defdelegate get_hub_serials, to: WeatherflowTempest.Client

  @doc delegate_to: {WeatheflowTempest.PubSub, :subscribe_to_udp_events, 0}
  defdelegate subscribe_to_udp_events, to: WeatherflowTempest.PubSub
end
