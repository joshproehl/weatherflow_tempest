defmodule WeatherflowTempest.ProtocolTest do
  use ExUnit.Case, async: true
  alias WeatherflowTempest.Protocol

  test "bubbles up the error tuple from Jason.decode when given malformed JSON" do
    assert {:error, %Jason.DecodeError{} = _err}
              = Protocol.handle_json(Jason.decode("{\"good_key\":\"is good\", BADKEY}"))
  end

  describe "handling a evt_precip message" do
    setup do
      [good_message: """
        {
            "serial_number": "SK-00008453",
            "type":"evt_precip",
            "hub_sn": "HB-00000001",
            "evt":[1493322445]
        }
        """,
      ]
    end

    test "returns the correct type as the first tuple element", %{good_message: msg} do
      assert {:evt_precip, _} = Protocol.handle_json(Jason.decode(msg))
    end

    test "returns object with the expected keys", %{good_message: msg} do
      {:evt_precip, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res) == 3
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{timestamp: _} = res
    end

    test "returns values that should remain unchanged in expected formats", %{good_message: msg} do
      {:evt_precip, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.serial_number == "SK-00008453"
      assert res.hub_sn == "HB-00000001"
    end

    test "returns timestamp as a parsed DateTime", %{good_message: msg} do
      {:evt_precip, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.timestamp == ~U[2017-04-27 19:47:25Z]
    end
  end

  describe "handling a evt_strike message" do
    setup do
      [good_message: """
        {
          "serial_number": "AR-00004049",
          "type":"evt_strike",
          "hub_sn": "HB-00000001",
          "evt":[1493322445,27,3848]
        }
        """,
      ]
    end

    test "returns the correct type as the first tuple element", %{good_message: msg} do
      assert {:evt_strike, _} = Protocol.handle_json(Jason.decode(msg))
    end

    test "returns object with the expected keys", %{good_message: msg} do
      {:evt_strike, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res) == 5
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{timestamp: _} = res
      assert %{distance_km: _} = res
      assert %{energy: _} = res
    end

    test "returns values that should remain unchanged in expected formats", %{good_message: msg} do
      {:evt_strike, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.serial_number == "AR-00004049"
      assert res.hub_sn == "HB-00000001"
    end

    test "returns timestamp as a parsed DateTime", %{good_message: msg} do
      {:evt_strike, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.timestamp == ~U[2017-04-27 19:47:25Z]
    end

    test "returns the message specific values", %{good_message: msg} do
      {:evt_strike, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.distance_km == 27
      assert res.energy == 3848
    end
  end
    
  describe "handling a rapid_wind message" do
    setup do
      [good_message: """
        {
          "serial_number": "SK-00008453",
          "type":"rapid_wind",
          "hub_sn": "HB-00000001",
          "ob":[1493322445,2.3,128]
        }
        """,
      ]
    end

    test "returns the correct type as the first tuple element", %{good_message: msg} do
      assert {:rapid_wind, _} = Protocol.handle_json(Jason.decode(msg))
    end

    test "returns object with the expected keys", %{good_message: msg} do
      {:rapid_wind, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res) == 5
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{timestamp: _} = res
      assert %{wind_speed_mps: _} = res
      assert %{wind_direction_degrees: _} = res
    end

    test "returns values that should remain unchanged in expected formats", %{good_message: msg} do
      {:rapid_wind, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.serial_number == "SK-00008453"
      assert res.hub_sn == "HB-00000001"
    end

    test "returns timestamp as a parsed DateTime", %{good_message: msg} do
      {:rapid_wind, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.timestamp == ~U[2017-04-27 19:47:25Z]
    end

    test "returns the message specific values", %{good_message: msg} do
      {:rapid_wind, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.wind_speed_mps == 2.3
      assert res.wind_direction_degrees == 128
    end
  end

  describe "handling a obs_air message" do
    setup do
      [good_message: """
        {
          "serial_number": "AR-00004049",
          "type":"obs_air",
          "hub_sn": "HB-00000001",
          "obs":[[1493164835,835.0,10.0,45,0,0,3.46,1]],
          "firmware_revision": 17
        }
        """,
        # Note that the obs are newest-first, to test if they get
        # re-sorted into ascending order correctly
        double_obs_message: """
        {
          "serial_number": "AR-00004049",
          "type":"obs_air",
          "hub_sn": "HB-00000001",
          "obs":[
            [1493164865,836.0,11.0,46,1,6,3.45,1],
            [1493164835,835.0,10.0,45,0,0,3.46,1]
          ],
          "firmware_revision": 17
        }
        """,
      ]
    end

    test "returns the correct type as the first tuple element", %{good_message: msg} do
      assert {:obs_air, _} = Protocol.handle_json(Jason.decode(msg))
    end

    test "returns object with the expected keys", %{good_message: msg} do
      {:obs_air, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res) == 4
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{observations: _} = res
      assert %{firmware_revision: _} = res
    end

    test "returns values that should remain unchanged in expected formats", %{good_message: msg} do
      {:obs_air, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.serial_number == "AR-00004049"
      assert res.hub_sn == "HB-00000001"
      assert res.firmware_revision == 17
    end

    test "returns values from an observation correctly", %{good_message: msg} do
      {:obs_air, res} = Protocol.handle_json(Jason.decode(msg))
      ob1 = Enum.at(res.observations, 0)
      assert ob1.timestamp == ~U[2017-04-26 00:00:35Z]
      assert ob1.station_pressure_MB == 835.0
      assert ob1.air_temperature_C == 10.0
      assert ob1.relative_humidity_percent == 45
      assert ob1.lightningstrike_count == 0
      assert ob1.lightningstrike_avg_distance_km == 0
      assert ob1.battery == 3.46
      assert ob1.reportinterval_minutes == 1
    end

    test "returns multiple observations, and sorts by ascending timestamp", %{double_obs_message: msg} do
      {:obs_air, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res.observations) == 2
      ob1 = Enum.at(res.observations, 0)
      ob2 = Enum.at(res.observations, 1)
      assert ob1.timestamp == ~U[2017-04-26 00:00:35Z]
      assert ob1.station_pressure_MB == 835.0
      assert ob1.battery == 3.46
      assert ob2.timestamp == ~U[2017-04-26 00:01:05Z]
      assert ob2.station_pressure_MB == 836.0
      assert ob2.battery == 3.45
    end
  end

  describe "handling a obs_sky message" do
    setup do
      [good_message: """
        {
          "serial_number": "SK-00008453",
          "type":"obs_sky",
          "hub_sn": "HB-00000001",
          "obs":[[1493321340,9000,10,0.0,2.6,4.6,7.4,187,3.12,1,130,null,0,3]],
          "firmware_revision": 29
        }
        """,
        # Note that obs are in not in epoch order, in order to test sorting.
        # We're also using this message to test parsing of the precip_type,
        # so each type is represented
        multi_obs_message: """
        {
          "serial_number": "SK-00008453",
          "type":"obs_sky",
          "hub_sn": "HB-00000001",
          "obs":[
            [1493321340,9000,10,0.0,2.6,4.6,7.4,187,3.12,1,130,null,2,3],
            [1493321370,8000,9,0.5,2.5,4.5,7.3,186,3.10,1,125,1,3,3],
            [1493321310,8000,9,0.5,2.5,4.5,7.3,186,3.10,1,125,1,1,3],
            [1493321280,8000,9,0.5,2.5,4.5,7.3,186,3.10,1,125,1,0,3]
          ],
          "firmware_revision": 29
        }
        """,
      ]
    end

    test "returns the correct type as the first tuple element", %{good_message: msg} do
      assert {:obs_sky, _} = Protocol.handle_json(Jason.decode(msg))
    end

    test "returns object with the expected keys", %{good_message: msg} do
      {:obs_sky, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res) == 4
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{observations: _} = res
      assert %{firmware_revision: _} = res
    end

    test "returns values that should remain unchanged in expected formats", %{good_message: msg} do
      {:obs_sky, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.serial_number == "SK-00008453"
      assert res.hub_sn == "HB-00000001"
      assert res.firmware_revision == 29
    end

    test "returns values from an observation correctly", %{good_message: msg} do
      {:obs_sky, res} = Protocol.handle_json(Jason.decode(msg))
      ob1 = Enum.at(res.observations, 0)
      assert ob1.timestamp == ~U[2017-04-27 19:29:00Z]
      assert ob1.illuminance_lux == 9000
      assert ob1.uv_index == 10
      assert ob1.rain_accumulated_mm == 0.0
      assert ob1.wind_lull_ms == 2.6
      assert ob1.wind_avg_ms == 4.6
      assert ob1.wind_gust_ms == 7.4
      assert ob1.wind_direction_degrees == 187
      assert ob1.battery_volts == 3.12
      assert ob1.reportinterval_minutes == 1
      assert ob1.solar_radiation_wm2 == 130
      assert ob1.local_day_rain_accumulation == nil
      assert ob1.precipitation_type == :none
      assert ob1.wind_sample_interval_seconds == 3
    end

    test "returns multiple observations, and sorts by ascending timestamp", %{multi_obs_message: msg} do
      {:obs_sky, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res.observations) == 4
      ob1 = Enum.at(res.observations, 0)
      ob2 = Enum.at(res.observations, 1)
      ob3 = Enum.at(res.observations, 2)
      ob4 = Enum.at(res.observations, 3)
      assert ob1.timestamp == ~U[2017-04-27 19:28:00Z]
      assert ob2.timestamp == ~U[2017-04-27 19:28:30Z]
      assert ob3.timestamp == ~U[2017-04-27 19:29:00Z]
      assert ob4.timestamp == ~U[2017-04-27 19:29:30Z]
    end

    # Note that this test depends on the observations being sorted in
    # ascending timestamp order, which is checked by the previous test.
    # However if we were ever to change that sort order this would break.
    test "returns different precip types correctly", %{multi_obs_message: msg} do
      {:obs_sky, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res.observations) == 4
      ob1 = Enum.at(res.observations, 0)
      ob2 = Enum.at(res.observations, 1)
      ob3 = Enum.at(res.observations, 2)
      ob4 = Enum.at(res.observations, 3)
      assert ob1.precipitation_type == :none
      assert ob2.precipitation_type == :rain
      assert ob3.precipitation_type == :hail
      assert ob4.precipitation_type == :rain_plus_hail
    end
  end

  describe "handling a obs_st message" do
    setup do
      [good_message: """
        {
          "serial_number": "ST-00000512",
          "type": "obs_st",
          "hub_sn": "HB-00013030",
          "obs": [
              [1588948614,0.18,0.22,0.27,144,6,1017.57,22.37,50.26,328,0.03,3,0.000000,0,0,0,2.410,1]
          ],
          "firmware_revision": 129
        }
        """,
        # Note that obs are in not in epoch order, in order to test sorting.
        # We're also using this message to test parsing of the precip_type,
        # so each type is represented
        multi_obs_message: """
        {
          "serial_number": "ST-00000512",
          "type": "obs_st",
          "hub_sn": "HB-00013030",
          "obs": [
              [1588948674,0.18,0.22,0.27,144,6,1017.57,22.37,50.26,328,0.03,3,0.000000,3,0,0,2.410,1],
              [1588948614,0.18,0.22,0.27,144,6,1017.57,22.37,50.26,328,0.03,3,0.000000,1,0,0,2.410,1],
              [1588948644,0.18,0.22,0.27,144,6,1017.57,22.37,50.26,328,0.03,3,0.000000,2,0,0,2.410,1],
              [1588948584,0.18,0.22,0.27,144,6,1017.57,22.37,50.26,328,0.03,3,0.000000,0,0,0,2.410,1]
          ],
          "firmware_revision": 129
        }
        """,
      ]
    end

    test "returns the correct type as the first tuple element", %{good_message: msg} do
      assert {:obs_st, _} = Protocol.handle_json(Jason.decode(msg))
    end

    test "returns object with the expected keys", %{good_message: msg} do
      {:obs_st, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res) == 4
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{observations: _} = res
      assert %{firmware_revision: _} = res
    end

    test "returns values that should remain unchanged in expected formats", %{good_message: msg} do
      {:obs_st, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.serial_number == "ST-00000512"
      assert res.hub_sn == "HB-00013030"
      assert res.firmware_revision == 129
    end

    test "returns values from an observation correctly", %{good_message: msg} do
      {:obs_st, res} = Protocol.handle_json(Jason.decode(msg))
      ob1 = Enum.at(res.observations, 0)
      assert ob1.timestamp == ~U[2020-05-08 14:36:54Z]
      assert ob1.wind_lull_ms == 0.18
      assert ob1.wind_avg_ms == 0.22
      assert ob1.wind_gust_ms == 0.27
      assert ob1.wind_direction_degrees == 144
      assert ob1.wind_sample_interval_seconds == 6
      assert ob1.station_pressure_MB == 1017.57
      assert ob1.air_temperature_C == 22.37
      assert ob1.relative_humidity_percent == 50.26
      assert ob1.illuminance_lux == 328
      assert ob1.uv_index == 0.03
      assert ob1.solar_radiation_wm2 == 3
      assert ob1.precip_accumulated_mm == 0.000000
      assert ob1.precipitation_type == :none
      assert ob1.lightningstrike_avg_distance_km == 0
      assert ob1.lightningstrike_count == 0
      assert ob1.battery_volts == 2.410 
      assert ob1.reportinterval_minutes == 1
    end

    test "returns multiple observations, and sorts by ascending timestamp", %{multi_obs_message: msg} do
      {:obs_st, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res.observations) == 4
      ob1 = Enum.at(res.observations, 0)
      ob2 = Enum.at(res.observations, 1)
      ob3 = Enum.at(res.observations, 2)
      ob4 = Enum.at(res.observations, 3)
      assert ob1.timestamp == ~U[2020-05-08 14:36:24Z]
      assert ob2.timestamp == ~U[2020-05-08 14:36:54Z]
      assert ob3.timestamp == ~U[2020-05-08 14:37:24Z]
      assert ob4.timestamp == ~U[2020-05-08 14:37:54Z]
    end

    # Note that this test depends on the observations being sorted in
    # ascending timestamp order, which is checked by the previous test.
    # However if we were ever to change that sort order this would break.
    test "returns different precip types correctly", %{multi_obs_message: msg} do
      {:obs_st, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res.observations) == 4
      ob1 = Enum.at(res.observations, 0)
      ob2 = Enum.at(res.observations, 1)
      ob3 = Enum.at(res.observations, 2)
      ob4 = Enum.at(res.observations, 3)
      assert ob1.precipitation_type == :none
      assert ob2.precipitation_type == :rain
      assert ob3.precipitation_type == :hail
      assert ob4.precipitation_type == :rain_plus_hail
    end
  end

  describe "handling a device_status message" do
    setup do
      [good_message: build_device_status()]
    end

    test "returns the correct type as the first tuple element", %{good_message: msg} do
      assert {:device_status, _} = Protocol.handle_json(Jason.decode(msg))
    end

    test "returns object with the expected keys", %{good_message: msg} do
      {:device_status, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res) == 11
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{timestamp: _} = res
      assert %{uptime: _} = res
      assert %{uptime_string: _} = res
      assert %{voltage: _} = res
      assert %{firmware_revision: _} = res
      assert %{rssi: _} = res
      assert %{hub_rssi: _} = res
      assert %{sensor_status: _} = res
      assert %{debug: _} = res
    end

    test "returns values that should remain unchanged in expected formats", %{good_message: msg} do
      {:device_status, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.serial_number == "AR-00004049"
      assert res.hub_sn == "HB-00000001"
      assert res.uptime == 2189
      assert res.voltage == 3.50
      assert res.firmware_revision == 17
      assert res.rssi == -17
      assert res.hub_rssi == -87
    end

    test "returns timestamp as a parsed DateTime", %{good_message: msg} do
      {:device_status, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.timestamp == ~U[2017-11-16 18:12:03Z]
    end

    # Note that this is actually testing the Timex library's 
    # `Timex.format_duration/2` function.
    # It would be better to perhaps regex this to make sure it contained
    # certain elements? Maybe just testing that it's a non-empty string?
    test "returns uptime_string as human readable text", %{good_message: msg} do
      {:device_status, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.uptime_string == "36 minutes, 29 seconds"
    end

    # The goal here is to test the private protocol function 
    # parse_device_sensor_status to make sure that we're parsing the bitfield
    # correctly.
    test "returns correct sensor status information" do
      assert {:device_status,
                %{sensor_status: %{
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
              }}} = Protocol.handle_json(Jason.decode(build_device_status(0)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: true,
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
              }}} = Protocol.handle_json(Jason.decode(build_device_status(1)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: false,
                    lightning_noise: true,
                    lightning_disturber: false,
                    pressure_failed: false,
                    temperature_failed: false,
                    rh_failed: false,
                    wind_failed: false,
                    precip_failed: false,
                    light_uv_failed: false,
                    power_booster_depleted: false,
                    power_booster_shore_power: false,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(2)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: false,
                    lightning_noise: false,
                    lightning_disturber: true,
                    pressure_failed: false,
                    temperature_failed: false,
                    rh_failed: false,
                    wind_failed: false,
                    precip_failed: false,
                    light_uv_failed: false,
                    power_booster_depleted: false,
                    power_booster_shore_power: false,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(4)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: false,
                    lightning_noise: false,
                    lightning_disturber: false,
                    pressure_failed: true,
                    temperature_failed: false,
                    rh_failed: false,
                    wind_failed: false,
                    precip_failed: false,
                    light_uv_failed: false,
                    power_booster_depleted: false,
                    power_booster_shore_power: false,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(8)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: false,
                    lightning_noise: false,
                    lightning_disturber: false,
                    pressure_failed: false,
                    temperature_failed: true,
                    rh_failed: false,
                    wind_failed: false,
                    precip_failed: false,
                    light_uv_failed: false,
                    power_booster_depleted: false,
                    power_booster_shore_power: false,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(16)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: false,
                    lightning_noise: false,
                    lightning_disturber: false,
                    pressure_failed: false,
                    temperature_failed: false,
                    rh_failed: true,
                    wind_failed: false,
                    precip_failed: false,
                    light_uv_failed: false,
                    power_booster_depleted: false,
                    power_booster_shore_power: false,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(32)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: false,
                    lightning_noise: false,
                    lightning_disturber: false,
                    pressure_failed: false,
                    temperature_failed: false,
                    rh_failed: false,
                    wind_failed: true,
                    precip_failed: false,
                    light_uv_failed: false,
                    power_booster_depleted: false,
                    power_booster_shore_power: false,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(64)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: false,
                    lightning_noise: false,
                    lightning_disturber: false,
                    pressure_failed: false,
                    temperature_failed: false,
                    rh_failed: false,
                    wind_failed: false,
                    precip_failed: true,
                    light_uv_failed: false,
                    power_booster_depleted: false,
                    power_booster_shore_power: false,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(128)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: false,
                    lightning_noise: false,
                    lightning_disturber: false,
                    pressure_failed: false,
                    temperature_failed: false,
                    rh_failed: false,
                    wind_failed: false,
                    precip_failed: false,
                    light_uv_failed: true,
                    power_booster_depleted: false,
                    power_booster_shore_power: false,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(256)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: false,
                    lightning_noise: false,
                    lightning_disturber: false,
                    pressure_failed: false,
                    temperature_failed: false,
                    rh_failed: false,
                    wind_failed: false,
                    precip_failed: false,
                    light_uv_failed: false,
                    power_booster_depleted: true,
                    power_booster_shore_power: false,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(32768)))

      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
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
                    power_booster_shore_power: true,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(65536)))

      # Now we've tested every individual field, so let's test a combination
      assert {:device_status,
                %{sensor_status: %{
                    sensors_okay: false,
                    lightning_failed: true,
                    lightning_noise: false,
                    lightning_disturber: false,
                    pressure_failed: false,
                    temperature_failed: false,
                    rh_failed: true,
                    wind_failed: false,
                    precip_failed: false,
                    light_uv_failed: true,
                    power_booster_depleted: true,
                    power_booster_shore_power: false,
              }}} = Protocol.handle_json(Jason.decode(build_device_status(1+32+256+32768)))
    end
  end

  describe "handling a hub_status message" do
    setup do
      [good_message: build_hub_status()]
    end

    test "returns the correct type as the first tuple element", %{good_message: msg} do
      assert {:hub_status, _} = Protocol.handle_json(Jason.decode(msg))
    end

    test "returns object with the expected keys", %{good_message: msg} do
      {:hub_status, res} = Protocol.handle_json(Jason.decode(msg))
      assert Enum.count(res) == 12
      assert %{hub_sn: _} = res
      assert %{serial_number: _} = res
      assert %{firmware_revision: _} = res
      assert %{uptime: _} = res
      assert %{uptime_string: _} = res
      assert %{rssi: _} = res
      assert %{timestamp: _} = res
      assert %{reset_flags: _} = res
      assert %{seq: _} = res
      assert %{fs: _} = res
      assert %{radio_stats: _} = res
      assert %{mqtt_stats: _} = res
    end

    test "returns values that should remain unchanged in expected formats", %{good_message: msg} do
      {:hub_status, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.serial_number == "HB-00000001"
      assert res.firmware_revision == "35"
      assert res.uptime == 1670133
      assert res.rssi == -62
      assert res.seq == 48
      assert res.fs == :not_parsed__internal_use_only
      assert res.mqtt_stats == :not_parsed__internal_use_only
    end

    test "returns timestamp as a parsed DateTime", %{good_message: msg} do
      {:hub_status, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.timestamp == ~U[2017-05-25 15:04:51Z]
    end

    test "copies the serial_number field into the hub_sn field", %{good_message: msg} do
      {:hub_status, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.hub_sn == res.serial_number
    end
    #
    # Note that this is actually testing the Timex library's 
    # `Timex.format_duration/2` function.
    # It would be better to perhaps regex this to make sure it contained
    # certain elements? Maybe just testing that it's a non-empty string?
    test "returns uptime_string as human readable text", %{good_message: msg} do
      {:hub_status, res} = Protocol.handle_json(Jason.decode(msg))
      assert res.uptime_string == "2 weeks, 5 days, 7 hours, 55 minutes, 33 seconds"
    end

    test "returns parsed radio status object, and correctly parses all possible radio statuses to human-readable string" do
      assert {:hub_status,
              %{radio_stats:
                %{version: 2,
                  reboot_count: 1,
                  i2c_bus_error_count: 0,
                  radio_status: "Radio Active",
                  radio_network_id: 2839
             }}} = Protocol.handle_json(Jason.decode(build_hub_status(nil, 3)))

      assert {:hub_status,
              %{radio_stats:
                %{radio_status: "Radio Off",
             }}} = Protocol.handle_json(Jason.decode(build_hub_status(nil, 0)))

      assert {:hub_status,
              %{radio_stats:
                %{radio_status: "Radio On",
             }}} = Protocol.handle_json(Jason.decode(build_hub_status(nil, 1)))

      assert {:hub_status,
              %{radio_stats:
                %{radio_status: "BLE Connected",
             }}} = Protocol.handle_json(Jason.decode(build_hub_status(nil, 7)))
    end

    test "returns an array of human-readable flags for reset flags field" do
      assert {:hub_status,
              %{reset_flags: [
                "Brownout reset",
                "PIN reset",
                "Power reset",
                "Software reset",
                "Watchdog reset",
                "Window watchdog reset",
                "Low-power reset"
             ]}} = Protocol.handle_json(Jason.decode(build_hub_status("BOR,PIN,POR,SFT,WDG,WWD,LPW")))
    end

    test "reset flags field handles unexpected flag" do
      assert {:hub_status,
              %{reset_flags: ["Brownout reset","Unknown reset flag"]
             }} = Protocol.handle_json(Jason.decode(build_hub_status("BOR,BRF")))
    end
  end


  #####
  # Helper functions
  #####
  
  defp build_device_status(sensor_status \\ 0) do
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
      "sensor_status": #{sensor_status},
      "debug": 0
    }
    """
  end

  defp build_hub_status(reset_flags \\ "BOR,PIN,POR", radio_status \\ 3) do
    """
    {
      "serial_number":"HB-00000001",
      "type":"hub_status",
      "firmware_revision":"35",
      "uptime":1670133,
      "rssi":-62,
      "timestamp":1495724691,
      "reset_flags": \"#{reset_flags}\",
      "seq": 48,
      "fs": [1, 0, 15675411, 524288],
      "radio_stats": [2, 1, 0, #{radio_status}, 2839],
      "mqtt_stats": [1, 0]
    }
    """
  end
end
