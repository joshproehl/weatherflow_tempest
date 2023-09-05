defmodule WeatherflowTempest.Client do
  @moduledoc """
  Listens for packets from Weatherflow devices on the LAN, parses them, and
  stores their latest state/update in its own state, while emitting the
  parsed events via either a callback function or a Phoenix.PubSub broadcast.

  ## Changes from UDP API

  It's important to note that we make some changes to the structure of the
  results returned by the raw WeartherFlow UDP API:
    * Events containing observations are flattened into a single observation
    with all observation keys as top-level keys, rather than objects with
    nested "obs" keys.
    * Events containing lists of observations are emitted as multiple events. 
    * Event names are altered to be more descriptive. See the
      [Event Examples](#module-event-examples) section below for event names
      and example return data.

  It is unclear when the devices will actually return a list of observations in
  a single "obs" list, and in testing with live devices it hasn't actually been
  observed.   
  However, to accomodate the case that it might happen what we'll do is create
  a unique event for every item in the observation list, and emit them in order
  of ascending timestamp. These will be the flattened events described above.  
  This simplifies handling the events from the perspective of users of the
  library, since it makes the expected output completely predictable.


  ## Usage

  There are two ways to get data from the Client: 
    1) via a callback function
    2) via Phoenix.PubSub

  You can use either, or both, depending on your needs.

  ### via Callback Function

  A callback function is passed in to the `start_link` function as part of the
  options list, under the "callback_func" key. (Multiple can be passed in, and
  will all be called.)
  The callback function will be called with two arguments:
    1) the event type, as an atom
    2) the event data, as a map

  ```elixir
  def handle_weatherflow_event(event_type, event_data) do
    # do something with the data received from the event
  end

  {:ok, pid} = WeatherflowTempest.Client.start_link([callback_func: &handle_weatherflow_event/2])
  ```

  > #### Blocking Callback Warning {: .warning}
  > Your callback functions will block the client from processing any further
  > data, so efforts should be made to keep them as lightweight as possible,
  > and hand off any complex processing.

  It is worth noting that the callback function will *not* be notified of any
  JSON parsing errors, only successfully parsed events.

  ### via Phoenix.Pubsub

  If you'd prefer to receive events via Phoenix.PubSub, you can configure the
  pubsub you'd like to use in your config file:
  ```elixir
  config :weatherflow_tempest, :pubsub_name, MyApp.PubSub
  ```

  You must also start the WeatherflowTempest.Client, commonly as a child of
  your Application Supervisor in application.ex:
  ```elixir
  def start(_type, _args) do
    children = [
      {WeatherflowTempest.Client, []},
    ]
    opts = [strategy: one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```

  Events are published as an {{:weatherflow, event_type}, event_data} struct,
  on the topic "weatherflow:udp".

  To subscribe to all events the convenience function
  `WeatherflowTempest.PubSub.subscribe_to_udp_events/0` is provided.
  Handling all broadcast weatherflow events looks something like:
  ```elixir
  def handle_info({{:weatherflow, event_type}, event_data}, socket) do
    IO.puts("Got a \#\{event_type\} message!")
    {:noreply, socket}
  end
  ```
  And of course you can match on specific event types as well.

  Events are emitted to the PubSub in ascending timestamp order, but due to
  the nature of PubSub if your usage requires that events be processed in
  strict timeline order you may wish to use the callback function instead.


  ## Event Examples

  Both methods of receiving events will receive the same event_types and the
  same event_data objects, the only difference is how they are received by your
  application.

  Any given "hub" should only emit both :observation_air and :observation_sky
  events, or only emit :observation_tempest events, depending on which product
  it is. Keeping all three observation types for each hub allows the calling
  application to easily handle both types of hubs simply by matching on the
  event type or value in the `%WeatherflowTempest.Client.Hub{}` struct. 
  (The alternative, having a single :observation event/field, would require that
  we embed the product type in the data, which would be a bit less clear to
  handle since each type of observation contains different fields.)

  Examples of the map returned by all event types are documented below:

  #### :event_precipitation
  ```elixir
  %{
    serial_number: "SK-00008453",
    hub_sn: "HB-00000001",
    timestamp: ~U[2017-04-27 19:47:25Z]
  }
  ```

  #### :event_strike
  ```elixir
  %{
    serial_number: "AR-00004049",
    hub_sn: "HB-00000001",
    timestamp: ~U[2017-04-27 19:47:25Z]
  }
  ```

  #### :rapid_wind
  ```elixir
  %{
    serial_number: "SK-00008453",
    hub_sn: "HB-00000001",
    timestamp: ~U[2017-04-27 19:47:25Z],
    wind_speed_mps: 2.3,
    wind_direction_degrees: 128
  }
  ```

  #### :observation_air
  ```elixir
  %{
    serial_number: "AR-00004049",
    hub_sn: "HB-00000001",
    firmware_revision: 17,
    observations: [
      %{
        timestamp: ~U[2017-04-26 00:00:35Z],
        station_pressure_MB: 835.0,
        air_temperature_C: 10.0,
        relative_humidity_percent: 45,
        lightningstrike_count: 0,
        lightningstrike_avg_distance_km: 0,
        battery: 3.46,
        reportinterval_mintues: 1
      }
    ]
  }
  ```

  #### :observation_sky
  ```elixir
  %{
    serial_number: "SK-00008453",
    hub_sn: "HB-00000001",
    firmware_revision: 29,
    observations: [
      %{
        timestamp: ~U[2017-04-27 19:29:00Z],
        illuminance_lux: 9000,
        uv_index: 10,
        rain_accumulated_mm: 0.0,
        wind_lull_ms: 2.6,
        wind_avg_ms: 4.6,
        wind_gust_ms: 7.4,
        wind_direction_degrees: 187,
        battery_volts: 3.12,
        reportinterval_minutes: 1,
        solar_radiation_wm2: 130,
        local_day_rain_accumulation: nil,
        precipitation_type: :none,
        wind_sample_interval_seconds: 3
      }
    ]
  }
  ```

  #### :observation_tempest
  ```elixir
  %{
    serial_number: "ST-00000512",
    hub_sn: "HB-00013030",
    firmware_revision: 129,
    observations: [
      %{
        timestamp: ~U[2020-05-08 14:36:54Z],
        wind_lull_ms: 0.18,
        wind_avg_ms: 0.22,
        wind_gust_ms: 0.27,
        wind_direction_degrees: 144,
        wind_sample_interval_seconds: 6,
        station_pressure_MB: 1017.57,
        air_temperature_C: 22.37,
        relative_humidity_percent: 50.26,
        illuminance_lux: 328,
        uv_index: 0.03,
        solar_radiation_wm2: 3,
        precip_accumulated_mm: 0.000000,
        precipitation_type: :none,
        lightningstrike_avg_distance_km: 0,
        lightningstrike_count: 0,
        battery_volts: 2.410,
        reportinterval_minutes: 1
      }
    ]
  }
  ```

  #### :device_status
  ```elixir
  %{
    serial_number: "AR-00004049",
    hub_sn: "HB-00000001",
    timestamp: ~U[2017-11-16 18:12:03Z],
    uptime: 2189,
    uptime_string: "36 minutes, 29 seconds",
    voltage: 3.50,
    firmware_revision: 17, 
    rssi: -17,
    hub_rssi: -87,
    sensor_status: %{
      sensors_okay: true,
      lightning_failed: false,
      lightning_noise: false,
      lightning_disturber: false,
      pressure_failed: false,
      temperature_failed: false,
      rh_failed: false,
      wind_failed: false,
      precip_failed: false,
      light_uv_failed: false,
      power_booster_depleted: false,
      power_booster_shore_power: false,
    },
    debug: false,
  }
  ```

  #### :hub_status
  ```elixir
  %{
    hub_sn: "HB-00000001",
    serial_number: "HB-00000001",
    firmware_revision: "35",
    uptime: 1670133,
    uptime_string: "2 weeks, 5 days, 7 hours, 55 minutes, 33 seconds",
    rssi: -62,
    timestamp: ~U[2017-05-25 15:04:51Z],
    reset_flags: ["Brownout reset", "PIN reset", "Power reset"],
    seq: 48,
    fs: :not_parsed__internal_use_only,
    radio_stats: %{
      version: 2,
      reboot_count: 1,
      i2c_bus_error_count: 0,
      radio_status: "Radio Active",
      radio_network_id: 2839
    },
    mqtt_stats: :not_parsed__internal_use_only,
  }
  ```
  """

  use GenServer
  alias WeatherflowTempest.Protocol

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
      socket: port(),
      packets_parsed: integer(),
      packet_errors: integer(),
      last_error: map(),
      hubs: map(),
      callback_funcs: [function()],
    }
    defstruct socket: nil,
              packets_parsed: 0,
              packet_errors: 0,
              last_error: %{},
              hubs: %{},
              callback_funcs: []
    
    # Delegate Access behaviour so we can use put_in to deeply-nested update hub info
    defdelegate fetch(term, key), to: Map
    defdelegate get(term, key, default), to: Map
    defdelegate get_and_update(term, key, fun), to: Map
  end

  defmodule Hub do
    @moduledoc """
    A struct representing the most recent data and status of a particular hub.

    Note that if a particular observation type hasn't yet been heard for this
    hub then some keys may be empty maps.
    """
    @type t :: %__MODULE__{
      event_precipitation: map(),
      event_strike: map(),
      rapid_wind: map(),
      observation_air: map(),
      observation_sky: map(),
      observation_tempest: map(),
      device_statuses: map(),
      hub_status: map()
    }
    defstruct event_precipitation: %{},
              event_strike: %{},
              rapid_wind: %{},
              observation_air: %{},
              observation_sky: %{},
              observation_tempest: %{},
              device_statuses: %{},
              hub_status: %{}

    # Delegate Access behaviour so we can use put_in to deeply-nested update hub info
    @doc false
    defdelegate fetch(term, key), to: Map
    @doc false
    defdelegate get(term, key, default), to: Map
    @doc false
    defdelegate get_and_update(term, key, fun), to: Map
  end

  ########
  # Client

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get all the latest data that the client has heard.

  Note that the resulting WeatherflowTempest.Client.Hub struct may contain
  empty fields if the client hasn't heard certain types of events yet.

  ## Examples

      iex> WeatherflowTempest.Client.get_latest()
      %{
        "HUB_SERIAL_ONE" => %WeatherflowTempest.Client.Hub{...}
      }

  """
  @spec get_latest() :: %{String.t() => WeatherflowTempest.Client.Hub.t()}
  def get_latest() do
    GenServer.call(__MODULE__, {:get_latest})
  end

  @doc """
  Get the total number of UDP packets and errors received by the client.

  ## Examples
  
      iex> WeatherflowTempest.Client.get_packet_stats()
      %{
        packets_parsed: 123,
        packet_errors: 0
      }

  """
  @spec get_packet_stats() :: map()
  def get_packet_stats() do
    GenServer.call(__MODULE__, {:get_packet_stats})
  end

  @doc """
  Get a list of serial numbers of Weatherflow Hubs that have been heard from.

  ## Examples
  
      iex> WeatherflowTempest.Client.get_hub_serials()
      ["HUB_SERIAL_ONE", "HUB_SERIAL_TWO"]

  """
  @spec get_hub_serials() :: [String.t()]
  def get_hub_serials() do
    GenServer.call(__MODULE__, {:get_hub_serials})
  end


  ####################
  # Server (Callbacks)

  @impl true
  def init(opts) do
    {:ok, socket} = :gen_udp.open(Application.get_env(:weatherflow_tempest, :listen_port, 50222),
                                  [:binary, broadcast: true, active: true])

    {:ok,
      %State{
        socket: socket,
        callback_funcs: Keyword.get_values(opts, :callback_func)
      }
    }
  end

  @impl true
  def handle_info({:udp, _socket, _ip, _port, payload}, state) do
    Jason.decode(payload)
    |> Protocol.handle_json
    |> update_state(state)
  end

  @impl true
  def handle_call({:get_latest}, _from, state) do
    {:reply, state.hubs, state}
  end

  @impl true
  def handle_call({:get_packet_stats}, _from, state) do
    {:reply,
      %{packets_parsed: state.packets_parsed, packet_errors: state.packet_errors},
      state}
  end

  @impl true
  def handle_call({:get_hub_serials}, _from, state) do
    {:reply, Enum.map(state.hubs, fn {k, _v} -> k end), state}
  end


  #########
  # update_state and associated functions
  # Handle each type of possible response returned by Protocol.handle_json
  # (Since the Protocol handler is responsible for sorting by ascending
  # timestamp we will assume that the last item in the list is the most
  # recent observation.)
  # At this point this function should be more correctly named
  # "broadcast_and_update_state" or something like that, or should have
  # yet another level of functions that it calls to break up updating state
  # from broadcasting events and passing data to the callback. (This could
  # help better ensure that we're using the same event name for both the
  # callback and the broadcast too...)
  # But we're going to leave it for now.
  
  defp update_state({:evt_precip, obj}, state) do
    WeatherflowTempest.PubSub.udp_event_broadcast(:event_precipitation, obj)
    maybe_do_callbacks(state.callback_funcs, :event_precipitation, obj)
    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :event_precipitation], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:evt_strike, obj}, state) do
    WeatherflowTempest.PubSub.udp_event_broadcast(:event_strike, obj)
    maybe_do_callbacks(state.callback_funcs, :event_strike, obj)
    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :event_strike], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:rapid_wind, obj}, state) do
    WeatherflowTempest.PubSub.udp_event_broadcast(:rapid_wind, obj)
    maybe_do_callbacks(state.callback_funcs, :rapid_wind, obj)
    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :rapid_wind], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:obs_air, obj}, state) do
    base_obj = Map.delete(obj, :observations)

    last_obs_obj = Enum.reduce(obj.observations, nil, fn(obs, _acc) ->
      merged_obj = Map.merge(base_obj, obs)
      WeatherflowTempest.PubSub.udp_event_broadcast(:observation_air, merged_obj)
      maybe_do_callbacks(state.callback_funcs, :observation_air, merged_obj)
      merged_obj
    end)

    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :observation_air], last_obs_obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:obs_sky, obj}, state) do
    base_obj = Map.delete(obj, :observations)

    last_obs_obj = Enum.reduce(obj.observations, nil, fn(obs, _acc) ->
      merged_obj = Map.merge(base_obj, obs)
      WeatherflowTempest.PubSub.udp_event_broadcast(:observation_sky, merged_obj)
      maybe_do_callbacks(state.callback_funcs, :observation_sky, merged_obj)
      merged_obj
    end)

    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :observation_sky], last_obs_obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:obs_st, obj}, state) do
    base_obj = Map.delete(obj, :observations)

    last_obs_obj = Enum.reduce(obj.observations, nil, fn(obs, _acc) ->
      merged_obj = Map.merge(base_obj, obs)
      WeatherflowTempest.PubSub.udp_event_broadcast(:observation_tempest, merged_obj)
      maybe_do_callbacks(state.callback_funcs, :observation_tempest, merged_obj)
      merged_obj
    end)

    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :observation_tempest], last_obs_obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:device_status, obj}, state) do
    WeatherflowTempest.PubSub.udp_event_broadcast(:device_status, obj)
    maybe_do_callbacks(state.callback_funcs, :device_status, obj)
    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :device_statuses, obj.serial_number], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:hub_status, obj}, state) do
    WeatherflowTempest.PubSub.udp_event_broadcast(:hub_status, obj)
    maybe_do_callbacks(state.callback_funcs, :hub_status, obj)
    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.serial_number, :hub_status], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:error, jason_error}, state) do
    {:noreply, state
               |> Map.put(:last_error, jason_error)
               |> Map.update(:packet_errors, 0, &(&1 + 1))}
  end

  # The state initalizes the callback as an empty list, so if the user doesn't
  # explicitly pass in any functions to start_link, then this will be a no-op.
  defp maybe_do_callbacks(callback_funcs, event_type, event_obj) do
    if Enum.count(callback_funcs) > 0 do
      Enum.each(callback_funcs, fn(callback_func) ->
        if not is_nil(callback_func), do: callback_func.(event_type, event_obj)
      end)
      :ok
    else
      :noop
    end
  end

  defp ensure_hub_sn_key_in_state(state, obj) do
    new_hubs = state.hubs
               |> Map.put_new(obj.hub_sn, %Hub{})
    %{state | hubs: new_hubs}
  end

end
