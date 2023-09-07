defmodule WeatherflowTempest.ProtocolTest do
  use ExUnit.Case, async: true
  alias WeatherflowTempest.Protocol
  alias WeatherflowTempest.JSONFixtures, as: F

  test "bubbles up the error tuple from Jason.decode when given malformed JSON" do
    assert {:error, %Jason.DecodeError{} = _err}
              = Protocol.handle_json(Jason.decode("{\"good_key\":\"is good\", BADKEY}"))
  end

  describe "handling a evt_precip message" do
    test "returns the correct type as the first tuple element" do
      assert {:evt_precip, _} = Protocol.handle_json(Jason.decode(F.example_evt_precip))
    end

    test "returns object with the expected keys" do
      {:evt_precip, res} = Protocol.handle_json(Jason.decode(F.example_evt_precip))
      assert Enum.count(res) == 3
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{timestamp: _} = res
    end

    test "returns values that should remain unchanged in expected formats" do
      {:evt_precip, res} = Protocol.handle_json(Jason.decode(F.example_evt_precip))
      assert res.serial_number == "SK-00008453"
      assert res.hub_sn == "HB-00000001"
    end

    test "returns timestamp as a parsed DateTime" do
      {:evt_precip, res} = Protocol.handle_json(Jason.decode(F.example_evt_precip))
      assert res.timestamp == ~U[2017-04-27 19:47:25Z]
    end
  end

  describe "handling a evt_strike message" do
    test "returns the correct type as the first tuple element" do
      assert {:evt_strike, _} = Protocol.handle_json(Jason.decode(F.example_evt_strike))
    end

    test "returns object with the expected keys" do
      {:evt_strike, res} = Protocol.handle_json(Jason.decode(F.example_evt_strike))
      assert Enum.count(res) == 5
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{timestamp: _} = res
      assert %{distance_km: _} = res
      assert %{energy: _} = res
    end

    test "returns values that should remain unchanged in expected formats" do
      {:evt_strike, res} = Protocol.handle_json(Jason.decode(F.example_evt_strike))
      assert res.serial_number == "AR-00004049"
      assert res.hub_sn == "HB-00000001"
    end

    test "returns timestamp as a parsed DateTime" do
      {:evt_strike, res} = Protocol.handle_json(Jason.decode(F.example_evt_strike))
      assert res.timestamp == ~U[2017-04-27 19:47:25Z]
    end

    test "returns the message specific values" do
      {:evt_strike, res} = Protocol.handle_json(Jason.decode(F.example_evt_strike))
      assert res.distance_km == 27
      assert res.energy == 3848
    end
  end
    
  describe "handling a rapid_wind message" do
    test "returns the correct type as the first tuple element" do
      assert {:rapid_wind, _} = Protocol.handle_json(Jason.decode(F.example_rapid_wind))
    end

    test "returns object with the expected keys" do
      {:rapid_wind, res} = Protocol.handle_json(Jason.decode(F.example_rapid_wind))
      assert Enum.count(res) == 5
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{timestamp: _} = res
      assert %{wind_speed_mps: _} = res
      assert %{wind_direction_degrees: _} = res
    end

    test "returns values that should remain unchanged in expected formats" do
      {:rapid_wind, res} = Protocol.handle_json(Jason.decode(F.example_rapid_wind))
      assert res.serial_number == "SK-00008453"
      assert res.hub_sn == "HB-00000001"
    end

    test "returns timestamp as a parsed DateTime" do
      {:rapid_wind, res} = Protocol.handle_json(Jason.decode(F.example_rapid_wind))
      assert res.timestamp == ~U[2017-04-27 19:47:25Z]
    end

    test "returns the message specific values" do
      {:rapid_wind, res} = Protocol.handle_json(Jason.decode(F.example_rapid_wind))
      assert res.wind_speed_mps == 2.3
      assert res.wind_direction_degrees == 128
    end
  end

  describe "handling a obs_air message" do
    test "returns the correct type as the first tuple element" do
      assert {:obs_air, _} = Protocol.handle_json(Jason.decode(F.example_obs_air))
    end

    test "returns object with the expected keys" do
      {:obs_air, res} = Protocol.handle_json(Jason.decode(F.example_obs_air))
      assert Enum.count(res) == 4
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{observations: _} = res
      assert %{firmware_revision: _} = res
    end

    test "returns values that should remain unchanged in expected formats" do
      {:obs_air, res} = Protocol.handle_json(Jason.decode(F.example_obs_air))
      assert res.serial_number == "AR-00004049"
      assert res.hub_sn == "HB-00000001"
      assert res.firmware_revision == 17
    end

    test "returns values from an observation correctly" do
      {:obs_air, res} = Protocol.handle_json(Jason.decode(F.example_obs_air))
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

    test "returns multiple observations, and sorts by ascending timestamp" do
      {:obs_air, res} = Protocol.handle_json(Jason.decode(F.obs_air_with_two_observations))
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
    test "returns the correct type as the first tuple element" do
      assert {:obs_sky, _} = Protocol.handle_json(Jason.decode(F.example_obs_sky))
    end

    test "returns object with the expected keys" do
      {:obs_sky, res} = Protocol.handle_json(Jason.decode(F.example_obs_sky))
      assert Enum.count(res) == 4
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{observations: _} = res
      assert %{firmware_revision: _} = res
    end

    test "returns values that should remain unchanged in expected formats" do
      {:obs_sky, res} = Protocol.handle_json(Jason.decode(F.example_obs_sky))
      assert res.serial_number == "SK-00008453"
      assert res.hub_sn == "HB-00000001"
      assert res.firmware_revision == 29
    end

    test "returns values from an observation correctly" do
      {:obs_sky, res} = Protocol.handle_json(Jason.decode(F.example_obs_sky))
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

    test "returns multiple observations, and sorts by ascending timestamp" do
      {:obs_sky, res} = Protocol.handle_json(Jason.decode(F.obs_sky_with_multiple_observations))
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
    test "returns different precip types correctly" do
      {:obs_sky, res} = Protocol.handle_json(Jason.decode(F.obs_sky_with_multiple_observations))
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
    test "returns the correct type as the first tuple element" do
      assert {:obs_st, _} = Protocol.handle_json(Jason.decode(F.example_obs_st))
    end

    test "returns object with the expected keys" do
      {:obs_st, res} = Protocol.handle_json(Jason.decode(F.example_obs_st))
      assert Enum.count(res) == 4
      assert %{serial_number: _} = res
      assert %{hub_sn: _} = res
      assert %{observations: _} = res
      assert %{firmware_revision: _} = res
    end

    test "returns values that should remain unchanged in expected formats" do
      {:obs_st, res} = Protocol.handle_json(Jason.decode(F.example_obs_st))
      assert res.serial_number == "ST-00000512"
      assert res.hub_sn == "HB-00013030"
      assert res.firmware_revision == 129
    end

    test "returns values from an observation correctly" do
      {:obs_st, res} = Protocol.handle_json(Jason.decode(F.example_obs_st))
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

    test "returns multiple observations, and sorts by ascending timestamp" do
      {:obs_st, res} = Protocol.handle_json(Jason.decode(F.obs_st_with_multiple_observations))
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
    test "returns different precip types correctly" do
      {:obs_st, res} = Protocol.handle_json(Jason.decode(F.obs_st_with_multiple_observations))
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
    test "returns the correct type as the first tuple element" do
      assert {:device_status, _} = Protocol.handle_json(Jason.decode(F.example_device_status))
    end

    test "returns object with the expected keys" do
      {:device_status, res} = Protocol.handle_json(Jason.decode(F.example_device_status))
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

    test "returns values that should remain unchanged in expected formats" do
      {:device_status, res} = Protocol.handle_json(Jason.decode(F.example_device_status))
      assert res.serial_number == "AR-00004049"
      assert res.hub_sn == "HB-00000001"
      assert res.uptime == 2189
      assert res.voltage == 3.50
      assert res.firmware_revision == 17
      assert res.rssi == -17
      assert res.hub_rssi == -87
    end

    test "returns timestamp as a parsed DateTime" do
      {:device_status, res} = Protocol.handle_json(Jason.decode(F.example_device_status))
      assert res.timestamp == ~U[2017-11-16 18:12:03Z]
    end

    # Note that this is actually testing the Timex library's 
    # `Timex.format_duration/2` function.
    # It would be better to perhaps regex this to make sure it contained
    # certain elements? Maybe just testing that it's a non-empty string?
    test "returns uptime_string as human readable text" do
      {:device_status, res} = Protocol.handle_json(Jason.decode(F.example_device_status))
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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(0)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(1)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(2)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(4)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(8)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(16)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(32)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(64)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(128)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(256)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(32768)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(65536)))

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
              }}} = Protocol.handle_json(Jason.decode(F.device_status_with_sensor_status(1+32+256+32768)))
    end
  end

  describe "handling a hub_status message" do
    test "returns the correct type as the first tuple element" do
      assert {:hub_status, _} = Protocol.handle_json(Jason.decode(F.example_hub_status))
    end

    test "returns object with the expected keys" do
      {:hub_status, res} = Protocol.handle_json(Jason.decode(F.example_hub_status))
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

    test "returns values that should remain unchanged in expected formats" do
      {:hub_status, res} = Protocol.handle_json(Jason.decode(F.example_hub_status))
      assert res.serial_number == "HB-00000001"
      assert res.firmware_revision == "35"
      assert res.uptime == 1670133
      assert res.rssi == -62
      assert res.seq == 48
      assert res.fs == :not_parsed__internal_use_only
      assert res.mqtt_stats == :not_parsed__internal_use_only
    end

    test "returns timestamp as a parsed DateTime" do
      {:hub_status, res} = Protocol.handle_json(Jason.decode(F.example_hub_status))
      assert res.timestamp == ~U[2017-05-25 15:04:51Z]
    end

    test "copies the serial_number field into the hub_sn field" do
      {:hub_status, res} = Protocol.handle_json(Jason.decode(F.example_hub_status))
      assert res.hub_sn == res.serial_number
    end
    #
    # Note that this is actually testing the Timex library's 
    # `Timex.format_duration/2` function.
    # It would be better to perhaps regex this to make sure it contained
    # certain elements? Maybe just testing that it's a non-empty string?
    test "returns uptime_string as human readable text" do
      {:hub_status, res} = Protocol.handle_json(Jason.decode(F.example_hub_status))
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
             }}} = Protocol.handle_json(Jason.decode(F.hub_status_with_reset_flags_and_radio_status("", 3)))

      assert {:hub_status,
              %{radio_stats:
                %{radio_status: "Radio Off",
             }}} = Protocol.handle_json(Jason.decode(F.hub_status_with_reset_flags_and_radio_status("", 0)))

      assert {:hub_status,
              %{radio_stats:
                %{radio_status: "Radio On",
             }}} = Protocol.handle_json(Jason.decode(F.hub_status_with_reset_flags_and_radio_status("", 1)))

      assert {:hub_status,
              %{radio_stats:
                %{radio_status: "BLE Connected",
             }}} = Protocol.handle_json(Jason.decode(F.hub_status_with_reset_flags_and_radio_status("", 7)))
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
             ]}} = Protocol.handle_json(Jason.decode(F.hub_status_with_reset_flags_and_radio_status("BOR,PIN,POR,SFT,WDG,WWD,LPW")))
    end

    test "reset flags field handles unexpected flag" do
      assert {:hub_status,
              %{reset_flags: ["Brownout reset","Unknown reset flag"]
             }} = Protocol.handle_json(Jason.decode(F.hub_status_with_reset_flags_and_radio_status("BOR,BRF")))
    end
  end
end
