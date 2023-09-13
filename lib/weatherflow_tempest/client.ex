defmodule WeatherflowTempest.Client do
  @moduledoc """
  Listens for packets from Weatherflow devices on the LAN and stores their latest
  state/update in its own state.

  Outputs events via `WeatherflowTempest.PubSub.udp_event_broadcast/2`.

  Events containing observations are flattened into a single observation with all
  observation keys as top-level keys.

  For observations, we'll get a list of observations. Sometimes.
  It's unclear when the devices will actually do this, and in testing
  with live devices it hasn't actually been observed.
  However, to accomodate the case that it might happen what we'll do is
  iterate the list, emitting a PubSub broadcast for **each** unique
  observation, but only saving the most recent into the state.
  (Since the Protocol handler is responsible for sorting by ascending
  timestamp we will assume that the last item in the list is the most
  recent observation.)
  
  This will allow any other module taking advantage of the PubSub
  broadcasts to get complete data.
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
      callback_func: function(),
    }
    defstruct socket: nil,
              packets_parsed: 0,
              packet_errors: 0,
              last_error: %{},
              hubs: %{},
              callback_func: nil
    
    # Delegate Access behaviour so we can use put_in to deeply-nested update hub info
    defdelegate fetch(term, key), to: Map
    defdelegate get(term, key, default), to: Map
    defdelegate get_and_update(term, key, fun), to: Map
  end

  defmodule Hub do
    @moduledoc false
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
    defdelegate fetch(term, key), to: Map
    defdelegate get(term, key, default), to: Map
    defdelegate get_and_update(term, key, fun), to: Map
  end

  ########
  # Client

  @doc false
  def start_link(opts \\ %{callback_func: nil}) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get all the latest data that the client has received.

  Returns a map where each key is a string for the hub serial, and the value is a
  `%WeatherflowTempest.Client.Hub` struct.
  """
  @spec get_latest() :: %{String.t() => WeatherflowTempest.Client.Hub.t()}
  def get_latest() do
    GenServer.call(__MODULE__, {:get_latest})
  end

  @doc """
  Get the total number of UDP packets and errors received by the client.
  """
  @spec get_packet_stats() :: map()
  def get_packet_stats() do
    GenServer.call(__MODULE__, {:get_packet_stats})
  end

  @doc """
  Get a list of serial numbers of Weatherflow Hubs that have been heard from.
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
        callback_func: opts.callback_func,
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
  # At this point this function should be more correctly named
  # "broadcast_and_update_state" or something like that, or should have
  # yet another level of functions that it calls to break up updating state
  # from broadcasting events and passing data to the callback. (This could
  # help better ensure that we're using the same event name for both the
  # callback and the broadcast too...)
  # But we're going to leave it for now.
  
  defp update_state({:evt_precip, obj}, state) do
    WeatherflowTempest.PubSub.udp_event_broadcast(:event_precipitation, obj)
    maybe_do_callback(state.callback_func, :event_precipitation, obj)
    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :event_precipitation], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:evt_strike, obj}, state) do
    WeatherflowTempest.PubSub.udp_event_broadcast(:event_strike, obj)
    maybe_do_callback(state.callback_func, :event_strike, obj)
    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :event_strike], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:rapid_wind, obj}, state) do
    WeatherflowTempest.PubSub.udp_event_broadcast(:rapid_wind, obj)
    maybe_do_callback(state.callback_func, :rapid_wind, obj)
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
      maybe_do_callback(state.callback_func, :observation_air, merged_obj)
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
      maybe_do_callback(state.callback_func, :observation_sky, merged_obj)
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
      maybe_do_callback(state.callback_func, :observation_tempest, merged_obj)
      merged_obj
    end)

    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :observation_tempest], last_obs_obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:device_status, obj}, state) do
    WeatherflowTempest.PubSub.udp_event_broadcast(:device_status, obj)
    maybe_do_callback(state.callback_func, :device_status, obj)
    {:noreply, state
               |> ensure_hub_sn_key_in_state(obj)
               |> put_in([:hubs, obj.hub_sn, :device_statuses, obj.serial_number], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:hub_status, obj}, state) do
    WeatherflowTempest.PubSub.udp_event_broadcast(:hub_status, obj)
    maybe_do_callback(state.callback_func, :hub_status, obj)
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

  # The state initalizes the callback as nil, so if the user doesn't
  # explicitly pass in a function to start_link, then this will be a no-op.
  defp maybe_do_callback(callback_func, event_type, event_obj) do
    if callback_func do
      callback_func.(event_type, event_obj)
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
