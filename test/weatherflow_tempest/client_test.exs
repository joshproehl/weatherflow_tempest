defmodule WeatherflowTempest.ClientTest do
  use ExUnit.Case, async: true
  alias WeatherflowTempest.Client
  alias WeatherflowTempest.Client.{State,Hub}
  alias WeatherflowTempest.Protocol
  alias WeatherflowTempest.JSONFixtures, as: F

  # A helper function that will allow us to check the order that
  # messages are received into the process inbox
  # From: https://stackoverflow.com/questions/41543466/how-to-assert-elixir-messages-arrive-in-order
  defmacro assert_next_receive(pattern, timeout \\ 100) do
    quote do
      receive do
        message -> assert unquote(pattern) = message
      after unquote(timeout) ->
        raise "No next message was received after #{unquote(timeout)}ms"
      end
    end
  end

  # Notes:
  # - Should we check that no *other* messages are in the inbox?
  #   refute_receive to check that that the client isn't sending extra data?
  #   Could do this by checking that Process.info(self(), :message_queue_len)
  #   returns {:message_queue_len, 0} at the end of every test?
  # - Do we need to test the no-callback-no-pubsub state?
  # - TODO: We need to test the callback function(s) works.
  #         https://thepugautomatic.com/2015/09/testing-callbacks-in-elixir/

  test "tracks the number of JSON packets recevived that did not contain parsable JSON" do
    {:noreply, new_state} = mock_receive_message("{badpacket:\"malformed JSON\"}")
    assert %{packets_parsed: 0, packet_errors: 1} = new_state
  end

  # Note that this test is testing the return value of Jason.Decode, so if
  # we were to change parsing libraries, or they were to change their outputs,
  # this would break. However this is the easy way to test that the error
  # contains the JSON that was bad, which a client app might want, so...
  test "stores the most recent JSON parsing error into the state" do
    assert {:noreply,
            %{last_error:
              %Jason.DecodeError{position: 13,
                                 token: nil,
                                 data: "{\"badpacket\":malformed JSON\"}"}
           }} = mock_receive_message("{\"badpacket\":malformed JSON\"}")
  end

  # The following tests are designed to ensure that each type of message causes
  # the expected events when it is received by the client.
  # What we want is to make sure that each message updates the state in the
  # expected ways, and that it emits the expected pubsub events.
  # In order to do this we will generate an expected object result from the
  # Protocol module, and compare the resulting state and PubSub messages to
  # this expected state.
  describe "does the expected things for message type" do
    test "evt_precip" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:evt_precip, e} = Protocol.handle_json(Jason.decode(F.example_evt_precip))
      {:noreply, new_state} = mock_receive_message(F.example_evt_precip)
      assert %State{
                packets_parsed: 1,
                packet_errors: 0,
                hubs: %{e.hub_sn =>
                        %Hub{event_precipitation:
                              %{serial_number: e.serial_number,
                                hub_sn: e.hub_sn,
                                timestamp: e.timestamp,
              }}}} == new_state
      assert_receive {{:weatherflow, :event_precipitation}, pubsub_obj}
      assert pubsub_obj == e
    end
    test "evt_strike" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:evt_strike, e} = Protocol.handle_json(Jason.decode(F.example_evt_strike))
      {:noreply, new_state} = mock_receive_message(F.example_evt_strike)
      assert %State{
                packets_parsed: 1,
                packet_errors: 0,
                hubs: %{e.hub_sn =>
                        %Hub{event_strike:
                              %{serial_number: e.serial_number,
                                hub_sn: e.hub_sn,
                                timestamp: e.timestamp,
                                distance_km: e.distance_km,
                                energy: e.energy,
              }}}} == new_state
      assert_receive {{:weatherflow, :event_strike}, pubsub_obj}
      assert pubsub_obj == e
    end
    test "rapid_wind" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:rapid_wind, e} = Protocol.handle_json(Jason.decode(F.example_rapid_wind))
      {:noreply, new_state} = mock_receive_message(F.example_rapid_wind)
      assert %State{
                packets_parsed: 1,
                packet_errors: 0,
                hubs: %{e.hub_sn =>
                        %Hub{rapid_wind:
                              %{serial_number: e.serial_number,
                                hub_sn: e.hub_sn,
                                timestamp: e.timestamp,
                                wind_speed_mps: e.wind_speed_mps,
                                wind_direction_degrees: e.wind_direction_degrees,
              }}}} == new_state
      assert_receive {{:weatherflow, :rapid_wind}, pubsub_obj}
      assert pubsub_obj == e
    end
    test "obs_air" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:obs_air, e} = Protocol.handle_json(Jason.decode(F.example_obs_air))
      {:noreply, new_state} = mock_receive_message(F.example_obs_air)
      assert %State{
                packets_parsed: 1,
                packet_errors: 0,
                hubs: %{e.hub_sn =>
                  %Hub{observation_air: 
                    Map.merge(
                      Enum.at(e.observations, 0),
                      %{serial_number: e.serial_number,
                        hub_sn: e.hub_sn,
                        firmware_revision: e.firmware_revision}),
              }}} == new_state
      expected_flattened_obj = e
                               |> Map.delete(:observations)
                               |> Map.merge(Enum.at(e.observations, 0))
      assert_receive {{:weatherflow, :observation_air}, pubsub_obj}
      assert pubsub_obj == expected_flattened_obj
    end
    test "obs_air with multiple observations" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:noreply, new_state} = mock_receive_message(F.obs_air_with_two_observations)
      assert_next_receive {{:weatherflow, :observation_air}, %{timestamp: ~U[2017-04-26 00:00:35Z]}}
      assert_next_receive {{:weatherflow, :observation_air}, %{timestamp: ~U[2017-04-26 00:01:05Z]}}
      # assert that the most recent observation is in the state
      assert %State{
                packets_parsed: 1,
                hubs: %{"HB-00000001" =>
                  %Hub{observation_air: 
                      %{timestamp: ~U[2017-04-26 00:01:05Z]},
              }}} = new_state
    end
    test "obs_sky" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:obs_sky, e} = Protocol.handle_json(Jason.decode(F.example_obs_sky))
      {:noreply, new_state} = mock_receive_message(F.example_obs_sky)
      assert %State{
                packets_parsed: 1,
                packet_errors: 0,
                hubs: %{e.hub_sn =>
                  %Hub{observation_sky: 
                    Map.merge(
                      Enum.at(e.observations, 0),
                      %{serial_number: e.serial_number,
                        hub_sn: e.hub_sn,
                        firmware_revision: e.firmware_revision}),
              }}} == new_state
      expected_flattened_obj = e
                               |> Map.delete(:observations)
                               |> Map.merge(Enum.at(e.observations, 0))
      assert_receive {{:weatherflow, :observation_sky}, pubsub_obj}
      assert pubsub_obj == expected_flattened_obj
    end
    test "obs_sky with multiple observations" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:noreply, new_state} = mock_receive_message(F.obs_sky_with_multiple_observations)
      assert_next_receive {{:weatherflow, :observation_sky}, %{timestamp: ~U[2017-04-27 19:28:00Z]}}
      assert_next_receive {{:weatherflow, :observation_sky}, %{timestamp: ~U[2017-04-27 19:28:30Z]}}
      assert_next_receive {{:weatherflow, :observation_sky}, %{timestamp: ~U[2017-04-27 19:29:00Z]}}
      assert_next_receive {{:weatherflow, :observation_sky}, %{timestamp: ~U[2017-04-27 19:29:30Z]}}
      # assert that the most recent observation is in the state
      assert %State{
                packets_parsed: 1,
                hubs: %{"HB-00000001" =>
                  %Hub{observation_sky: 
                      %{timestamp: ~U[2017-04-27 19:29:30Z]},
              }}} = new_state
    end
    test "obs_st" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:obs_st, e} = Protocol.handle_json(Jason.decode(F.example_obs_st))
      {:noreply, new_state} = mock_receive_message(F.example_obs_st)
      assert %State{
                packets_parsed: 1,
                packet_errors: 0,
                hubs: %{e.hub_sn =>
                  %Hub{observation_tempest: 
                    Map.merge(
                      Enum.at(e.observations, 0),
                      %{serial_number: e.serial_number,
                        hub_sn: e.hub_sn,
                        firmware_revision: e.firmware_revision}),
              }}} == new_state
      expected_flattened_obj = e
                               |> Map.delete(:observations)
                               |> Map.merge(Enum.at(e.observations, 0))
      assert_receive {{:weatherflow, :observation_tempest}, pubsub_obj}
      assert pubsub_obj == expected_flattened_obj
    end
    test "obs_st with multiple observations" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:noreply, new_state} = mock_receive_message(F.obs_st_with_multiple_observations)
      assert_next_receive {{:weatherflow, :observation_tempest}, %{timestamp: ~U[2020-05-08 14:36:24Z]}}
      assert_next_receive {{:weatherflow, :observation_tempest}, %{timestamp: ~U[2020-05-08 14:36:54Z]}}
      assert_next_receive {{:weatherflow, :observation_tempest}, %{timestamp: ~U[2020-05-08 14:37:24Z]}}
      assert_next_receive {{:weatherflow, :observation_tempest}, %{timestamp: ~U[2020-05-08 14:37:54Z]}}
      # assert that the most recent observation is in the state
      assert %State{
                packets_parsed: 1,
                hubs: %{"HB-00013030" =>
                  %Hub{observation_tempest: 
                      %{timestamp: ~U[2020-05-08 14:37:54Z]},
              }}} = new_state
    end
    test "device_status" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:device_status, e} = Protocol.handle_json(Jason.decode(F.example_device_status))
      {:noreply, new_state} = mock_receive_message(F.example_device_status)
      assert %State{
                packets_parsed: 1,
                packet_errors: 0,
                hubs: %{e.hub_sn =>
                  %Hub{device_statuses:
                    %{e.serial_number =>
                      %{serial_number: e.serial_number,
                        hub_sn: e.hub_sn,
                        timestamp: e.timestamp,
                        uptime: e.uptime,
                        uptime_string: e.uptime_string,
                        voltage: e.voltage,
                        firmware_revision: e.firmware_revision,
                        rssi: e.rssi,
                        hub_rssi: e.hub_rssi,
                        sensor_status: e.sensor_status,
                        debug: e.debug,
              }}}}} == new_state
      assert_receive {{:weatherflow, :device_status}, pubsub_obj}
      assert pubsub_obj == e
    end
    test "hub_status" do
      WeatherflowTempest.PubSub.subscribe_to_udp_events()
      {:hub_status, e} = Protocol.handle_json(Jason.decode(F.example_hub_status))
      {:noreply, new_state} = mock_receive_message(F.example_hub_status)
      assert %State{
                packets_parsed: 1,
                packet_errors: 0,
                hubs: %{e.hub_sn =>
                  %Hub{hub_status: 
                      %{serial_number: e.serial_number,
                        hub_sn: e.hub_sn,
                        firmware_revision: e.firmware_revision,
                        uptime: e.uptime,
                        uptime_string: e.uptime_string,
                        rssi: e.rssi,
                        timestamp: e.timestamp,
                        reset_flags: e.reset_flags,
                        seq: e.seq,
                        fs: e.fs,
                        radio_stats: e.radio_stats,
                        mqtt_stats: e.mqtt_stats,
              }}}} == new_state
      assert_receive {{:weatherflow, :hub_status}, pubsub_obj}
      assert pubsub_obj == e
    end
  end

  test "returns the latest data that it has heard for all hubs" do
      ex = Jason.decode!(F.example_evt_precip)
      ex1 = ex
            |> Map.put("hub_sn", "HB-00009999")
            |> Map.put("serial_number", "SK-00008888")
      ex2 = ex
            |> Map.put("hub_sn", "HB-00007777")
            |> Map.put("serial_number", "SK-00006666")
      {:noreply, first_state} = mock_receive_message(Jason.encode!(ex1))
      {:noreply, second_state} = mock_receive_message(Jason.encode!(ex2), first_state)
      assert {:reply, %{"HB-00009999" =>
                  %Hub{event_precipitation:
                    %{serial_number: "SK-00008888",
                      hub_sn: "HB-00009999"}},
                "HB-00007777" =>
                  %Hub{event_precipitation:
                    %{serial_number: "SK-00006666",
                      hub_sn: "HB-00007777"}}
              }, _final_state} = Client.handle_call({:get_latest}, self(), second_state)
  end

  test "returns the packet stats in the correct map format" do
    {:noreply, state1} = mock_receive_message("{\"badpacket\":malformed JSON\"}")
    {:noreply, state2} = mock_receive_message(F.example_evt_precip, state1)
    {:noreply, state3} = mock_receive_message("NOTJSON", state2)
    {:noreply, state4} = mock_receive_message(F.obs_st_with_multiple_observations, state3)
    {:reply, res, _final_state} = Client.handle_call({:get_packet_stats}, self(), state4)
    assert res == %{packets_parsed: 2, packet_errors: 2}
  end

  test "returns list of serial numbers of all hubs it has heard packets from" do
      ex = Jason.decode!(F.example_evt_precip)
      ex1 = ex
            |> Map.put("hub_sn", "HB-00009999")
            |> Map.put("serial_number", "SK-00008888")
      ex2 = ex
            |> Map.put("hub_sn", "HB-00007777")
            |> Map.put("serial_number", "SK-00006666")
      {:noreply, first_state} = mock_receive_message(Jason.encode!(ex1))
      {:noreply, second_state} = mock_receive_message(Jason.encode!(ex2), first_state)
      {:reply, res, _final_state} = Client.handle_call({:get_hub_serials}, self(), second_state)
      assert Enum.sort(res) == ["HB-00007777", "HB-00009999"]
  end


  #####
  # Helper functions
  #####

  defp mock_receive_message(json_payload, old_state \\ %State{}) do
    Client.handle_info({:udp, nil, nil, nil, json_payload}, old_state)
  end

end
