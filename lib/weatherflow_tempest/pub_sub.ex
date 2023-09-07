defmodule WeatherflowTempest.PubSub do
  @moduledoc """
  Convenience for interacting with Phoenix.Pubsub

  Interacts with the PubSub named in config:
  ```elixir
  config :weatherflow_tempest, :pubsub_name, MyApp.PubSub
  ```
  or via one named :weatherflow_tempest if that is not defined.

  UDP events received over the network are emitted via the "weatherflow:udp"
  topic.
  
  Events are published as an {event, payload} struct, with the event being an
  expanded version of the event type from the weatherflow API, and the parsed
  object as the payload.
  """

  @pubsub_name Application.compile_env(:weatherflow_tempest, :pubsub_name, :weatherflow_tempest)
  @udp_event_topic "weatherflow:udp"

  @doc """
  Subscribe to the correct pubsub name and channel to receive all UDP events as
  %Phoenix.PubSub.broadcast{} structs
  """
  def subscribe_to_udp_events(), do: Phoenix.PubSub.subscribe(@pubsub_name, @udp_event_topic)

  @doc false # this is designed to be called interally only by the the Client module
  def udp_event_broadcast(event, payload) do
    Phoenix.PubSub.broadcast(@pubsub_name, @udp_event_topic, {event, payload})
  end

  @doc """
  Return the name of the pubsub we're using
  """
  def get_pubsub_name(), do: @pubsub_name

end
