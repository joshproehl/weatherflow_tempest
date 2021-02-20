defmodule WeatherflowTempest.Client do
  @moduledoc
  """
  Listens for packets from Weatherflow devices on the LAN and stores their latest state/update in its own state.
  """

  use GenServer
  alias WeatherflowTempest.Protocol

  @pubsub_name Application.get_env(:weatherflow_tempest, :pubsub_name, :weatherflow_tempest)

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
      socket: port(),
      packets_parsed: integer(),
      packet_errors: integer(),
      last_error: Map.t(),
      hubs: Map.t()
    }
    defstruct socket: nil,
              packets_parsed: 0,
              packet_errors: 0,
              last_error: %{},
              hubs: %{}
    
    # Delegate Access behaviour so we can use put_in to deeply-nested update hub info
    defdelegate fetch(term, key), to: Map
    defdelegate get(term, key, default), to: Map
    defdelegate get_and_update(term, key, fun), to: Map
  end

  defmodule Hub do
    @moduledoc false
    @type t :: %__MODULE__{
      event_precipitation: Map.t(),
      event_strike: Map.t(),
      rapid_wind: Map.t(),
      observation_air: Map.t(),
      observation_sky: Map.t(),
      observation_tempest: Map.t(),
      device_statuses: Map.t(),
      hub_status: Map.t()
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

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_latest() do
    GenServer.call(__MODULE__, {:get_latest})
  end

  def get_packet_stats() do
    GenServer.call(__MODULE__, {:get_packet_stats})
  end

  def get_hub_serials() do
    GenServer.call(__MODULE__, {:get_hub_serials})
  end


  ####################
  # Server (Callbacks)


  @impl true
  def init(:ok) do
    {:ok, socket} = :gen_udp.open(50222, [:binary, broadcast: true, active: true])
    {:ok, %State{socket: socket}}
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
    {:reply, %{packets_parsed: state.packets_parsed, packet_errors: state.packet_errors}, state}
  end

  @impl true
  def handle_call({:get_hub_serials}, _from, state) do
    {:reply, Enum.map(state.hubs, fn {k, _v} -> k end), state}
  end

  #########
  # update_state and associated functions
  # Handle each type of possible response returned by Protocol.handle_json
  
  defp update_state({:evt_precip, obj}, state) do
    Phoenix.PubSub.broadcast(@pubsub_name, "weatherflow:udp", {:event_precipitation, obj})
    {:noreply, state
               |> ensure_hub_sn_key(obj)
               |> put_in([:hubs, obj["hub_sn"], :event_precipitation], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:evt_strike, obj}, state) do
    Phoenix.PubSub.broadcast(@pubsub_name, "weatherflow:udp", {:event_strike, obj})
    {:noreply, state
               |> ensure_hub_sn_key(obj)
               |> put_in([:hubs, obj["hub_sn"], :event_strike], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:rapid_wind, obj}, state) do
    Phoenix.PubSub.broadcast(@pubsub_name, "weatherflow:udp", {:rapid_wind, obj})
    {:noreply, state
               |> ensure_hub_sn_key(obj)
               |> put_in([:hubs, obj["hub_sn"], :rapid_wind], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:obs_air, obj}, state) do
    Phoenix.PubSub.broadcast(@pubsub_name, "weatherflow:udp", {:observation_air, obj})
    {:noreply, state
               |> ensure_hub_sn_key(obj)
               |> put_in([:hubs, obj["hub_sn"], :observation_air], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:obs_sky, obj}, state) do
    Phoenix.PubSub.broadcast(@pubsub_name, "weatherflow:udp", {:observation_sky, obj})
    {:noreply, state
               |> ensure_hub_sn_key(obj)
               |> put_in([:hubs, obj["hub_sn"], :observation_sky], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:obs_st, obj}, state) do
    Phoenix.PubSub.broadcast(@pubsub_name, "weatherflow:udp", {:observation_tempest, obj})
    {:noreply, state
               |> ensure_hub_sn_key(obj)
               |> put_in([:hubs, obj["hub_sn"], :observation_tempest], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:device_status, obj}, state) do
    Phoenix.PubSub.broadcast(@pubsub_name, "weatherflow:udp", {:device_status, obj})
    {:noreply, state
               |> ensure_hub_sn_key(obj)
               |> put_in([:hubs, obj["hub_sn"], :device_statuses, obj["serial_number"]], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:hub_status, obj}, state) do
    Phoenix.PubSub.broadcast(@pubsub_name, "weatherflow:udp", {:hub_status, obj})
    {:noreply, state
               |> ensure_hub_sn_key(obj, "serial_number")
               |> put_in([:hubs, obj["serial_number"], :hub_status], obj)
               |> Map.update(:packets_parsed, 0, &(&1 + 1))}
  end

  defp update_state({:error, jason_error}, state) do
    {:noreply, state
               |> Map.put(:last_error, jason_error)
               |> Map.update(:packet_errors, 0, &(&1 + 1))}
  end

  defp ensure_hub_sn_key(state, obj, key \\ "hub_sn") do
    new_hubs = state.hubs
               |> Map.put_new(obj[key], %Hub{})
    %{state | hubs: new_hubs}
  end

end
