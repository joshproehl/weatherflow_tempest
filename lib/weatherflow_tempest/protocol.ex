defmodule WeatherflowTempest.Protocol do
  @moduledoc """
  The Weatherflow Protocol has a lot of magic fields. This parses and converts
  them to make the returned objects more intelligible.

  Byte-effecient arrays are unpacked into named fields based on the protocol docs
  published by Weatherflow.

  The following field standardizations are made to all event types:
    * "type" fields are removed. (Use the whole `{:type, %{}}` tuple)
    * "evt" fields containing the raw un-parsed event data are removed, and the data
      from those fields is flattened into a single event map.
    * "uptime" fields containing seconds-as-integers are given human-readable string
      representations such as "1 week, 4 days, 3 hours, 16 minutes", which are
      placed in an :uptime_string field
    * "timestamp" field containing the epoch time are converted to DateTime
    * All fields are converted to use atoms as keys. The only string keys used will
      be device serial numbers, i.e.:

      ```
        device_statuses: %{
            "AR-00000001" => %{
                firmware_revision: 23
            }
        }
      ```

    * :hub_sn key is added to the hub_status message type, allowing easy pattern
      matching for all events from a given hub.

  ## Notes:
  * The hub_status event returns a firmware_revision as a string rather than an
    integer, according to the API examples. We do **not** convert that integer to
    a string since it's unclear what Weatherflow's intent here is. Perhaps there
    will be a firmware revision "37beta2"?
  """

  use Timex
  import Bitwise
  
  @doc """
  Accepts the result tuple of Jason.decode()
  If the JSON could not be decoded bubble the error up to be handled by the
  `WeatherflowTempest.Client`, otherwise parse the event types defined by
  the Weatherflow spec.

  Returns a tuple containing an atom matching the event "type" field, followed
  by the parsed object as a map. (Because it is cleaner to pattern match the
  against the tuple than against a key in the map, and makes returning ar error
  tuple the easy way to bubble up any errors.)
  Some liberties are taken with renaming fields and altering the resulting
  structure for clarity. The "type" key is removed from all result maps, as the
  intention is to hold on to the entire tuple if you need to pass it around.

  For evt_precip, evt_strike, and rapid_wind messages we flatten the data into
  a single map for convenience. 

  For example, a rapid_wind event from the UDP API looks like this:
  ```json
    {
      "serial_number": "AR-00004049",
      "type":"rapid_wind",
      "hub_sn": "HB-00000001",
      "ob":[1493322445,2.3,128]
    }
  ```
  and we will parse that into:
  ```elixir
    {:rapid_wind,
     %{
      serial_number: "AR-00004049",
      hub_sn: "HB-00000001",
      timestamp: ~U[2017-04-27 19:47:25Z],
      wind_speed_mps: 2.3,
      wind_direction_degrees: 128
     }
    }
  ```

  However, the obs_air, obs_sky, and obs_st event types can return a list of
  observations, although they most often return just a single event.
  Because of this those observations are **not** flattened into a single map,
  and are instead returned as a list, sorted by ascending timestamp.
  They are returned under the :observations key, rather than the "obs" used
  by the API, for the sake of clarity.

  The API doesn't cearly define what would cause the devices to return a list
  of observations rather than a single one, so we can't make any assumptions
  here about de-duplication or repeated events unfortunately, and will simply
  parse and return whatever the API provides. Do note however that the logic
  in `WeatherflowTempest.Client` strips out all but the most recent event,
  so if you'd like to actually deal with a device that is sending lists of
  observations you'll need to use `WeatherflowTempest.Protocol` directly.
  """
  @spec handle_json({atom(), map()}) :: map()
  def handle_json({:error, %Jason.DecodeError{}} = error_tuple), do: error_tuple

  def handle_json({:ok, %{"type" => "evt_precip"} = obj}) do
    {:evt_precip,
      %{
        serial_number: obj["serial_number"],
        hub_sn: obj["hub_sn"],
        timestamp: DateTime.from_unix!(Enum.at(obj["evt"], 0)),
      }
    }
  end

  def handle_json({:ok, %{"type" => "evt_strike"} = obj}) do
    {:evt_strike,
      %{
        serial_number: obj["serial_number"],
        hub_sn: obj["hub_sn"],
        timestamp: DateTime.from_unix!(Enum.at(obj["evt"], 0)),
        distance_km: Enum.at(obj["evt"], 1),
        energy: Enum.at(obj["evt"], 2)
      }
    }
  end

  def handle_json({:ok, %{"type" => "rapid_wind"} = obj}) do
    {:rapid_wind,
      %{
        serial_number: obj["serial_number"],
        hub_sn: obj["hub_sn"],
        timestamp: DateTime.from_unix!(Enum.at(obj["ob"], 0)),
        wind_speed_mps: Enum.at(obj["ob"], 1),
        wind_direction_degrees: Enum.at(obj["ob"], 2),
      }
    }
  end

  def handle_json({:ok, %{"type" => "obs_air"} = obj}) do
    observations = Enum.map(obj["obs"], &parse_air_observation/1)
                   |> Enum.sort_by(&(&1.timestamp), {:asc, DateTime})
    {:obs_air,
      %{
        serial_number: obj["serial_number"],
        hub_sn: obj["hub_sn"],
        firmware_revision: obj["firmware_revision"],
        observations: observations,
      }
    }
  end

  def handle_json({:ok, %{"type" => "obs_sky"} = obj}) do
    observations = Enum.map(obj["obs"], &parse_sky_observation/1)
                   |> Enum.sort_by(&(&1.timestamp), {:asc, DateTime})

    {:obs_sky,
      %{
        serial_number: obj["serial_number"],
        hub_sn: obj["hub_sn"],
        firmware_revision: obj["firmware_revision"],
        observations: observations,
      }
    }
  end

  def handle_json({:ok, %{"type" => "obs_st"} = obj}) do
    observations = Enum.map(obj["obs"], &parse_tempest_observation/1)
                   |> Enum.sort_by(&(&1.timestamp), {:asc, DateTime})

    {:obs_st,
      %{
        serial_number: obj["serial_number"],
        hub_sn: obj["hub_sn"],
        firmware_revision: obj["firmware_revision"],
        observations: observations,
      }
    }
  end

  def handle_json({:ok, %{"type" => "device_status"} = obj}) do
    {:device_status,
      %{
        serial_number: obj["serial_number"],
        hub_sn: obj["hub_sn"],
        timestamp: DateTime.from_unix!(obj["timestamp"]),
        uptime: obj["uptime"],
        uptime_string: uptime_seconds_to_string(obj["uptime"]),
        voltage: obj["voltage"],
        firmware_revision: obj["firmware_revision"],
        rssi: obj["rssi"],
        hub_rssi: obj["hub_rssi"],
        sensor_status: parse_device_sensor_status(obj["sensor_status"]),
        debug: (obj["debug"] == 1),
      }
    }
  end

  def handle_json({:ok, %{"type" => "hub_status"} = obj}) do
    {:hub_status,
      %{
        hub_sn: obj["serial_number"],
        serial_number: obj["serial_number"],
        firmware_revision: obj["firmware_revision"],
        uptime: obj["uptime"],
        uptime_string: uptime_seconds_to_string(obj["uptime"]),
        rssi: obj["rssi"],
        timestamp: DateTime.from_unix!(obj["timestamp"]),
        reset_flags: parse_hub_reset_flags(obj["reset_flags"]),
        seq: obj["seq"],
        fs: :not_parsed__internal_use_only,
        radio_stats: parse_hub_radio_stats(obj["radio_stats"]),
        mqtt_stats: :not_parsed__internal_use_only,
      }
    }
  end


  defp precip_type(int_type) do
    case int_type do
      0 -> :none
      1 -> :rain
      2 -> :hail
      3 -> :rain_plus_hail
    end
  end

  defp parse_air_observation(obj) do
   Map.new()
   |> Map.put(:timestamp, DateTime.from_unix!(Enum.at(obj, 0)))
   |> Map.put(:station_pressure_MB, Enum.at(obj, 1))
   |> Map.put(:air_temperature_C, Enum.at(obj, 2))
   |> Map.put(:relative_humidity_percent, Enum.at(obj, 3))
   |> Map.put(:lightningstrike_count, Enum.at(obj, 4))
   |> Map.put(:lightningstrike_avg_distance_km, Enum.at(obj, 5))
   |> Map.put(:battery_volts, Enum.at(obj, 6))
   |> Map.put(:reportinterval_minutes, Enum.at(obj, 7))
  end

  defp parse_sky_observation(obj) do
    Map.new()
    |> Map.put(:timestamp, DateTime.from_unix!(Enum.at(obj, 0)))
    |> Map.put(:illuminance_lux, Enum.at(obj, 1))
    |> Map.put(:uv_index, Enum.at(obj, 2))
    |> Map.put(:rain_accumulated_mm, Enum.at(obj, 3))
    |> Map.put(:wind_lull_ms, Enum.at(obj, 4))
    |> Map.put(:wind_avg_ms, Enum.at(obj, 5))
    |> Map.put(:wind_gust_ms, Enum.at(obj, 6))
    |> Map.put(:wind_direction_degrees, Enum.at(obj, 7))
    |> Map.put(:battery_volts, Enum.at(obj, 8))
    |> Map.put(:reportinterval_minutes, Enum.at(obj, 9))
    |> Map.put(:solar_radiation_wm2, Enum.at(obj, 10))
    |> Map.put(:local_day_rain_accumulation, Enum.at(obj, 11))
    |> Map.put(:precipitation_type, precip_type(Enum.at(obj, 12)))
    |> Map.put(:wind_sample_interval_seconds, Enum.at(obj, 13))
  end

  defp parse_tempest_observation(obj) do
    Map.new()
    |> Map.put(:timestamp, DateTime.from_unix!(Enum.at(obj, 0)))
    |> Map.put(:wind_lull_ms, Enum.at(obj, 1))
    |> Map.put(:wind_avg_ms, Enum.at(obj, 2))
    |> Map.put(:wind_gust_ms, Enum.at(obj, 3))
    |> Map.put(:wind_direction_degrees, Enum.at(obj, 4))
    |> Map.put(:wind_sample_interval_seconds, Enum.at(obj, 5))
    |> Map.put(:station_pressure_MB, Enum.at(obj, 6))
    |> Map.put(:air_temperature_C, Enum.at(obj, 7))
    |> Map.put(:relative_humidity_percent, Enum.at(obj, 8))
    |> Map.put(:illuminance_lux, Enum.at(obj, 9))
    |> Map.put(:uv_index, Enum.at(obj, 10))
    |> Map.put(:solar_radiation_wm2, Enum.at(obj, 11))
    |> Map.put(:precip_accumulated_mm, Enum.at(obj, 12))
    |> Map.put(:precipitation_type, precip_type(Enum.at(obj, 13)))
    |> Map.put(:lightningstrike_avg_distance_km, Enum.at(obj, 14))
    |> Map.put(:lightningstrike_count, Enum.at(obj, 15))
    |> Map.put(:battery_volts, Enum.at(obj, 16))
    |> Map.put(:reportinterval_minutes, Enum.at(obj, 17))
  end

  defp parse_device_sensor_status(bf) do
    %{
      sensors_okay: (bf == 0),
      lightning_failed: (bf &&& 0b000000001) == 0b000000001,
      lightning_noise: (bf &&& 0b000000010) == 0b000000010,
      lightning_disturber: (bf &&& 0b000000100) == 0b000000100,
      pressure_failed: (bf &&& 0b000001000) == 0b000001000,
      temperature_failed: (bf &&& 0b000010000) == 0b000010000,
      rh_failed: (bf &&& 0b000100000) == 0b000100000,
      wind_failed: (bf &&& 0b001000000) == 0b001000000,
      precip_failed: (bf &&& 0b010000000) == 0b010000000,
      light_uv_failed: (bf &&& 0b100000000) == 0b100000000,
      power_booster_depleted: (bf &&& 0x00008000) == 0x00008000,
      power_booster_shore_power: (bf &&& 0x00010000) == 0x00010000,
    } 
  end

  defp uptime_seconds_to_string(up_seconds) do
    uptime = Timex.Duration.from_seconds(up_seconds)
    Timex.format_duration(uptime, :humanized)
  end

  defp parse_hub_radio_stats(stats_array) do
    %{
      version: Enum.at(stats_array, 0),
      reboot_count: Enum.at(stats_array, 1),
      i2c_bus_error_count: Enum.at(stats_array, 2),
      radio_status: parse_radio_status(Enum.at(stats_array, 3)),
      radio_network_id: Enum.at(stats_array, 4)
    }
  end

  defp parse_radio_status(status) do
    case status do
      0 -> "Radio Off"
      1 -> "Radio On"
      3 -> "Radio Active"
      7 -> "BLE Connected"
    end
  end

  defp parse_hub_reset_flags(flag_string) do
    flag_string
    |> String.split(",")
    |> Enum.map(&reset_flag_to_string/1)
  end

  defp reset_flag_to_string(f) do
    case f do
      "BOR" -> "Brownout reset"
      "PIN" -> "PIN reset"
      "POR" -> "Power reset"
      "SFT" -> "Software reset"
      "WDG" -> "Watchdog reset"
      "WWD" -> "Window watchdog reset"
      "LPW" -> "Low-power reset"
      _ -> "Unknown reset flag"
    end
  end

end
