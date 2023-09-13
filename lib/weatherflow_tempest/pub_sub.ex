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

  @pubsub_name Application.compile_env(:weatherflow_tempest, :pubsub_name)
  @udp_event_topic "weatherflow:udp"

  @doc """
  Subscribe to the correct pubsub name and channel to receive all UDP events as
  %Phoenix.PubSub.broadcast{} structs
  """
  def subscribe_to_udp_events(), do: Phoenix.PubSub.subscribe(@pubsub_name, @udp_event_topic)

  @doc """
  Return the name of the pubsub we're using
  """
  def get_pubsub_name(), do: @pubsub_name

  @doc false
  # This function is intended only to be called from the WeatherflowTempest.Client
  # If the compile env doesn't define a pubsub_name then this function is a noop
  def udp_event_broadcast(event, payload) do
    if @pubsub_name do 
      Phoenix.PubSub.broadcast(@pubsub_name,
                               @udp_event_topic,
                               {{:weatherflow, event}, payload})
      :ok
    else
      :noop
    end
  end
end
