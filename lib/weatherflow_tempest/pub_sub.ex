defmodule WeatherflowTempest.PubSub do
  @moduledoc """
  Publishes events via Phoenix.PubSub.

  In order to use Phoenix.PubSub broadcasting you must ensure that your
  application also require phoenix_pubsub in its deps.

  Configure the pubsub you'd like to use in the appropriate config file:
  ```elixir
  config :weatherflow_tempest, :pubsub_name, MyApp.PubSub
  ```

  Events are published as an {{:weatherflow, event_type}, event_data} struct,
  on the "weatherflow:udp" topic. 
  If no pubsub_name is defined in the config, then no PubSub messages are
  broadcast.

  The tuple {:weatherflow, event} is used as they key in order to make it easy
  to match against all Weatherflow related events if your pubsub subscriber
  also receives messages from other pubsub topics.

  The `event` is an expanded version of the event type from the weatherflow API,
  and the parsed object as the payload. 
  Full documentation for the event names and structures is available in the
  `WeatherflowTempest.Client` module.
  """

  @pubsub_name Application.compile_env(:weatherflow_tempest, :pubsub_name)
  @udp_event_topic "weatherflow:udp"

  @doc """
  Convenience method to subscribe to the correct pubsub name and channel to
  receive all parsed UDP events received as pubsub messages.
  """
  def subscribe_to_udp_events(), do: Phoenix.PubSub.subscribe(@pubsub_name, @udp_event_topic)

  @doc """
  Return the name of the pubsub we're using.
  Might be useful if you want to subscribe to the UDP events yourself, or
  check on which pubsub is being used at runtime
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
