# Weatherflow Tempest

> A library for handling the data from the LAN API for WeatherFlow weather stations.

Online docs found at [https://hexdocs.pm/weatherflow_tempest](https://hexdocs.pm/weatherflow_tempest).  
Code and bug reports are at [https://github.com/joshproehl/weatherflow_tempest](https://github.com/joshproehl/weatherflow_tempest).

Current Weatherflow UDP API version targeted is [171](https://weatherflow.github.io/Tempest/api/udp/v171/).

Supported devices:
- Air/Sky
- Tempest

Yes, the library is called "weatherflow tempest". Why it was created that way,
when it has always supported both Tempest and the earlier device, is lost to
time. Maybe because it was going to handle a veritable tempest of UDP packets?


## Installation

Add `weatherflow_tempest` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_pubsub, "~> 2.0"}, # Only required if using PubSub broadcasts
    {:weatherflow_tempest, "~> 1.0.0"}
  ]
end
```
and fetch your dependencies with
```
$ mix deps.get
```


## Usage

The data from the WeatherFlow UDP LAN API can be emitted either via a callback
function for your application to handle, or put out via a Phoenix.PubSub
instance, which is especially useful if you're trying to get data into
something like a LiveView.

```elixir
#######################################
# Example usage via Callback function #

def handle_weatherflow_event(event_type, event_data) do
  # do something with the data received from the event
end

{:ok, pid} = WeatherflowTempest.Client.start_link([callback_func: &handle_weatherflow_event/2])
```

```elixir
######################################
# Example PubSub usage in a LiveView #

# In order to utilize PubSub you must configure the PubSub instance to use
# via your application config, and you must start the Client, probably by
# adding it as a child of your Application Supervisor.

def mount(_params, _session, socket) do
    WeatherflowTempest.PubSub.subscribe_to_udp_events()
    {:ok, socket}
end

def handle_info({{:weatherflow, event_type}, event_data}, socket) do
  IO.puts("Got a \#\{event_type\} message!")
  # Update your LiveView socket with the data!
  {:noreply, socket}
end
```

Full configuration and usage for both methods can be found in the
`WeatherflowTempest.Client` docs.

You can get the latest data heard from the station via
`WeatherflowTempest.get_latest/0`, which will return a map containing the most
recent data that has been heard from every Weatherflow device on the LAN, but
in practice you will probably want to use either the callback function or the
PubSub broadcast to be able to handle events as they occur, and only use
`WeatherflowTempest.get_latest/0` to seed initial values to your app. (When
starting a new LiveView page for example.)

> #### Note {: .info}
> 
> While it is technically possible to start the application with neither a
> PubSub name configured nor a callback function given, it is not the intended
> way to use the library.  
> In this case the Client will still start, but you will only be able to access
> the data via the `WeatherflowTempest.get_latest/0` function, and will not be
> able to receive individual events.

The payload for each event is transformed from the UDP API strucure by
`WeatherFlowTempest.Client`, but in short it will be a map containing all data returned
by the API as key/value pairs. Examples of returned data can be found in 
[Event Examples](WeatherflowTempest.Client.html#module-event-examples).
