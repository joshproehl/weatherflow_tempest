defmodule WeatherflowTempest.Protocol do
  @moduledoc """
    The Protocol has a lot of magic fields. This parses and converts them to make the returned objects more intelligible.

    This will standardarize some field names, as well as make everything a named top-level field.
    Basically it unpacks their byte-effecient arrays of values into something easier to grok, and standardizes some field names.
  """

  use Bitwise
  use Timex
  
  @spec handle_json(Map.t()) :: Map.t()
  def handle_json({:error, %Jason.DecodeError{} = err}) do
    {:error, :json_error}
  end

  def handle_json({:ok, %{"type" => "evt_precip"} = obj}) do
    event = Map.new(:timestamp, DateTime.from_unix!(Enum.at(obj["evt"], 0)))

    {:evt_precip, obj 
                  |> Map.delete("type")
                  |> Map.put(:event, event)
                  |> Map.delete("evt") }
  end

  def handle_json({:ok, %{"type" => "evt_strike"} = obj}) do
    event = Map.new()
            |> Map.put(:timestamp, DateTime.from_unix!(Enum.at(obj["evt"], 0)))
            |> Map.put(:distance_km, Enum.at(obj["evt"], 1))
            |> Map.put(:energy, Enum.at(obj, 2))
    {:evt_strike, obj
                  |> Map.delete("type")
                  |> Map.put(:event, event)
                  |> Map.delete("evt") }
  end

  def handle_json({:ok, %{"type" => "rapid_wind"} = obj}) do
    observation = Map.new()
                  |> Map.put(:timestamp, DateTime.from_unix!(Enum.at(obj["ob"], 0)))
                  |> Map.put(:windspeed_mps, Enum.at(obj["ob"], 1))
                  |> Map.put(:wind_direction_degrees, Enum.at(obj["ob"], 2))
    {:rapid_wind, obj
                  |> Map.delete("type")
                  |> Map.put(:observation, observation)
                  |> Map.delete("ob")}
  end

  def handle_json({:ok, %{"type" => "obs_air"} = obj}) do
    observations = Enum.map(obj["obs"], &parse_air_observation/1)
                   |> Enum.sort_by(&(&1.timestamp), {:asc, Date})

    {:obs_air, obj
               |> Map.delete("type")
               |> Map.put(:observations, observations)
               |> Map.delete("obs")}
  end

  def handle_json({:ok, %{"type" => "obs_sky"} = obj}) do
    observations = Enum.map(obj["obs"], &parse_sky_observation/1)
                   |> Enum.sort_by(&(&1.timestamp), {:asc, Date})

    {:obs_sky, obj
               |> Map.delete("type")
               |> Map.put(:observations, observations)
               |> Map.delete("obs")}
  end

  def handle_json({:ok, %{"type" => "obs_st"} = obj}) do
    observations = Enum.map(obj["obs"], &parse_tempest_observation/1)
                   |> Enum.sort_by(&(&1.timestamp), {:asc, Date})

    {:obs_st, obj
              |> Map.delete("type")
              |> Map.put(:observations, observations)
              |> Map.delete("obs")}
  end

  def handle_json({:ok, %{"type" => "device_status"} = obj}) do
    {:device_status, obj
                     |> Map.delete("type")
                     |> Map.put(:sensor_status, parse_device_sensor_status(obj["sensor_status"]))
                     |> Map.delete("sensor_status")
                     |> Map.put(:timestamp, DateTime.from_unix!(obj["timestamp"]))
                     |> Map.delete("timestamp")}
  end

  def handle_json({:ok, %{"type" => "hub_status"} = obj}) do
    {:hub_status, obj
                  |> Map.delete("type")
                  |> Map.put(:uptime, hub_uptime_to_string(obj["uptime"]))
                  |> Map.delete("uptime")
                  |> Map.put(:timestamp, DateTime.from_unix!(obj["timestamp"]))
                  |> Map.delete("timestamp")
                  |> Map.put(:radio_stats, parse_hub_radio_stats(obj["radio_stats"]))
                  |> Map.delete("radio_stats")
                  |> Map.put(:reset_flags, parse_hub_reset_flags(obj["reset_flags"]))
                  |> Map.delete("reset_flags")}
  end


  defp precip_type(int_type) do
    case int_type do
      0 -> :none
      1 -> :rain
      2 -> :hail
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
   |> Map.put(:battery, Enum.at(obj, 6))
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
      light_uv_failed: (bf &&& 0b100000000) == 0b100000000
    } 
  end

  defp hub_uptime_to_string(up_seconds) do
    uptime = Duration.from_seconds(up_seconds)
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
    end
  end

end
