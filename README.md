# Weatherflow Tempest

> Get data from a Weatherflow weather station over the LAN.

Online docs found at [https://hexdocs.pm/weatherflow_tempest](https://hexdocs.pm/weatherflow_tempest).  
Code and bug reports are at [https://github.com/joshproehl/weatherflow_tempest](https://github.com/joshproehl/weatherflow_tempest).

Current Weatherflow UDP API version targeted is [143](https://weatherflow.github.io/Tempest/api/udp/v143/).

Supported devices:
- Air/Sky
- Tempest

## Installation

Add `weatherflow_tempest` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:weatherflow_tempest, "~> 0.1.0"}
  ]
end
```
and fetch your dependencies with
```
$ mix deps.get
```

Configure the PubSub output in your config.exs (or _env_.exs):

```elixir
config :weatherflow_tempest, :pubsub_name, MyApp.PubSub
```
If none is defined it will start a pubsub named :weatherflow_tempest and output
events there.

## Usage

You can get the latest data heard from the station via `WeatherflowTempest.get_latest`,
which will return a map containing the last received message of each message type.

To subscribe to all events use the convenience function
`WeatherflowTempest.PubSub.subscribe_to_udp_events()`, and then handle all incoming
events with something like:
```elixir
def handle_info(%{topic: "weatherflow:udp", event: event_type, payload: payload} = msg, socket) do
  Logger.debug("Got event type #{msg.event}")
  {:noreply, socket}
end
```

The broadcasts use `%Phoenix.Socket.Broadcast{}` structs, the topic is set as
"weatherflow:udp", the event represents the type of event, and the payload is the
flattened and transformed payload from the Weatherflow station.

The events returned are fullname-expanded versions of the type codes of the
WeatherFlow API:
- :event_precipitation
- :event_strike
- :rapid_wind
- :observation_air
- :observation_sky
- :observation_tempest
- :device_status
- :hub_status

The payload for each event is transformed from the UDP API format by
`WeatherFlowTempest.Client`, but in short it will be a map containing all data returned
by the API as key/value pairs. 

It is worth noting that the type key is stripped from the results (due to us changing
the event names to be clearer), so if you are passing the messages on further you will
need to keep the association between object and type manually.
