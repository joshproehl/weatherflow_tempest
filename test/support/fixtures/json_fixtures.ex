defmodule WeatherflowTempest.JSONFixtures do
  @moduledoc """
  This module defines the fixtures to use for testing.
  The example_* functions use the example code from the Weatherflow API docs,
  presenting their example JSON as a string, so that we can test
  the end-to-end JSON parsing and handling.

  Any *_with_* function is a modification of the example code to create
  cases that do not have examples. These examples are created by parsing the
  example code, injecting some changes into it, and turning it back into a
  string. Doing it this way means that if the API doc examples are updated
  the fixture can be updated in one single place.

  Ideally we'd have some sort of code that would check these fixtures
  in the example_* functions against the API docs to make sure that the
  fixtures were always up to date with the docs.
  """

  def example_evt_precip do
    """
      {
        "serial_number": "SK-00008453",
        "type":"evt_precip",
        "hub_sn": "HB-00000001",
        "evt":[1493322445]
      }
    """
  end

  def example_evt_strike do
    """
      {
        "serial_number": "AR-00004049",
        "type":"evt_strike",
        "hub_sn": "HB-00000001",
        "evt":[1493322445,27,3848]
      }
    """
  end

  def example_rapid_wind do
    """
      {
        "serial_number": "SK-00008453",
        "type":"rapid_wind",
        "hub_sn": "HB-00000001",
        "ob":[1493322445,2.3,128]
      }
    """
  end

  def example_obs_air do
    """
      {
        "serial_number": "AR-00004049",
        "type":"obs_air",
        "hub_sn": "HB-00000001",
        "obs":[[1493164835,835.0,10.0,45,0,0,3.46,1]],
        "firmware_revision": 17
      }
    """
  end

  def example_obs_sky do
    """
      {
        "serial_number": "SK-00008453",
        "type":"obs_sky",
        "hub_sn": "HB-00000001",
        "obs":[[1493321340,9000,10,0.0,2.6,4.6,7.4,187,3.12,1,130,null,0,3]],
        "firmware_revision": 29
      }
    """
  end

  def example_obs_st do
    """
      {
        "serial_number": "ST-00000512",
        "type": "obs_st",
        "hub_sn": "HB-00013030",
        "obs": [
            [1588948614,0.18,0.22,0.27,144,6,1017.57,22.37,50.26,328,0.03,3,0.000000,0,0,0,2.410,1]
        ],
        "firmware_revision": 129
      }
    """
  end

  def example_device_status do
    """
      {
        "serial_number": "AR-00004049",
        "type": "device_status",
        "hub_sn": "HB-00000001",
        "timestamp": 1510855923,
        "uptime": 2189,
        "voltage": 3.50,
        "firmware_revision": 17,
        "rssi": -17,
        "hub_rssi": -87,
        "sensor_status": 0,
        "debug": 0
      }
    """
  end

  def example_hub_status do
    """
      {
        "serial_number":"HB-00000001",
        "type":"hub_status",
        "firmware_revision":"35",
        "uptime":1670133,
        "rssi":-62,
        "timestamp":1495724691,
        "reset_flags": "BOR,PIN,POR",
        "seq": 48,
        "fs": [1, 0, 15675411, 524288],
        "radio_stats": [2, 1, 0, 3, 2839],
        "mqtt_stats": [1, 0]
      }
    """
  end



  def obs_air_with_two_observations do
    # Note that the obs are newest-first, to test if they get
    # re-sorted into ascending order correctly
    new_obs = Jason.decode! """
      {
        "obs":[
          [1493164865,836.0,11.0,46,1,6,3.45,1],
          [1493164835,835.0,10.0,45,0,0,3.46,1]
        ]
      }
    """

    Jason.decode!(example_obs_air())
    |> Map.merge(new_obs)
    |> Jason.encode!
  end

  def obs_sky_with_multiple_observations do
    # Note that obs are in not in epoch order, in order to test sorting.
    # We're also using this message to test parsing of the precip_type,
    # so each type is represented
    new_obs = Jason.decode! """
      {
        "obs":[
          [1493321340,9000,10,0.0,2.6,4.6,7.4,187,3.12,1,130,null,2,3],
          [1493321370,8000,9,0.5,2.5,4.5,7.3,186,3.10,1,125,1,3,3],
          [1493321310,8000,9,0.5,2.5,4.5,7.3,186,3.10,1,125,1,1,3],
          [1493321280,8000,9,0.5,2.5,4.5,7.3,186,3.10,1,125,1,0,3]
        ]
      }
    """

    Jason.decode!(example_obs_sky())
    |> Map.merge(new_obs)
    |> Jason.encode!
  end

  def obs_st_with_multiple_observations do
    # Note that obs are in not in epoch order, in order to test sorting.
    # We're also using this message to test parsing of the precip_type,
    # so each type is represented
    new_obs = Jason.decode! """
      {
        "obs": [
            [1588948674,0.18,0.22,0.27,144,6,1017.57,22.37,50.26,328,0.03,3,0.000000,3,0,0,2.410,1],
            [1588948614,0.18,0.22,0.27,144,6,1017.57,22.37,50.26,328,0.03,3,0.000000,1,0,0,2.410,1],
            [1588948644,0.18,0.22,0.27,144,6,1017.57,22.37,50.26,328,0.03,3,0.000000,2,0,0,2.410,1],
            [1588948584,0.18,0.22,0.27,144,6,1017.57,22.37,50.26,328,0.03,3,0.000000,0,0,0,2.410,1]
        ]
      }
    """

    Jason.decode!(example_obs_st())
    |> Map.merge(new_obs)
    |> Jason.encode!
  end

  def device_status_with_sensor_status(sensor_status \\ 0) do
    Jason.decode!(example_device_status())
    |> Map.put("sensor_status", sensor_status)
    |> Jason.encode!
  end

  def hub_status_with_reset_flags_and_radio_status(reset_flags \\ "BOR,PIN,POR", radio_status \\ 3) do
    Jason.decode!(example_hub_status())
    |> Map.put("reset_flags", reset_flags)
    |> replace_radio_status(radio_status)
    |> Jason.encode!
  end

  defp replace_radio_status(json_map, new_radio_status) do
    Map.put(json_map, "radio_stats", List.replace_at(json_map["radio_stats"], 3, new_radio_status))
  end
end
