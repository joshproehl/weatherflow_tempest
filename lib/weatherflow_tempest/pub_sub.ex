defmodule WeatherflowTempest.PubSub do
  @moduledoc """
  Convenience for interacting with Phoenix.Pubsub

  Interacts with the PubSub named in config:
  ```elixir
  config :weatherflow_tempest, :pubsub_name, MyApp.PubSub
  ```
  or via one named :weatherflow_tempest if that is not defined.
  
  Events are published as %Phoenix.Pubsub.broadcast{} structs with the "event" field
  being the event type from the Weatherflow API, and the parsed object as the payload.
  UDP events received over the network are emitted over the "weatherflow:udp" topic.
  """

  @pubsub_name Application.get_env(:weatherflow_tempest, :pubsub_name, :weatherflow_tempest)
  @udp_event_topic "weatherflow:udp"

  @doc """
  Subscribe to the correct pubsub name and channel to receive all UDP events as
  %Phoenix.PubSub.broadcast{} structs
  """
  def subscribe_to_udp_events(), do: Phoenix.PubSub.subscribe(@pubsub_name, @udp_event_topic)

  @doc false # this is designed to be called interally only.
  def udp_event_broadcast(event, payload) do
    t_broadcast(@udp_event_topic, event, payload)
  end

  @doc """
  Return the name of the pubsub we're using
  """
  def get_pubsub_name(), do: @pubsub_name

  defp t_broadcast(topic, event, payload) do
    Phoenix.PubSub.broadcast(@pubsub_name, topic, %{
      __struct__: Phoenix.Socket.Broadcast,
      topic: topic,
      event: event,
      payload: payload
    },
    Phoenix.Channel.Server)
  end
end
