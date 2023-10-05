defmodule WeatherflowTempest.ClientAPITest do
  use ExUnit.Case, async: false
  alias WeatherflowTempest.Client
  alias WeatherflowTempest.Client.Hub
  alias WeatherflowTempest.JSONFixtures, as: F

  # These tests are broken out into their own module because they can't be run
  # async, since they each start a supervised fresh client (to ensure it has no
  # data from previous tests). 
  # We don't want to run all the OTHER tests as async: false, so these live on
  # their own.
  #
  # Note that these tests are redundant, because the previous tests of the
  # handle_* functions are successfully testing the functionality.
  # These are here **simply** to ensure that we don't break the Client.function
  # API.
  # If any of the previous three tests are changed these should be changed
  # to match. This could be DRY'd up, but it's probably not worth it now.
  describe "front-end API function:" do
    test "get_latest" do
      {:ok, client} = start_supervised(Client)
      ex = Jason.decode!(F.example_evt_precip)
      ex1 = ex
            |> Map.put("hub_sn", "HB-00009999")
            |> Map.put("serial_number", "SK-00008888")
      ex2 = ex
            |> Map.put("hub_sn", "HB-00007777")
            |> Map.put("serial_number", "SK-00006666")
      send(client, {:udp, nil, nil, nil, Jason.encode!(ex1)})
      send(client, {:udp, nil, nil, nil, Jason.encode!(ex2)})
      assert %{"HB-00009999" =>
                  %Hub{event_precipitation:
                    %{serial_number: "SK-00008888",
                      hub_sn: "HB-00009999"}},
                "HB-00007777" =>
                  %Hub{event_precipitation:
                    %{serial_number: "SK-00006666",
                      hub_sn: "HB-00007777"}}
              } = Client.get_latest
    end

    test "get_packet_stats" do
      {:ok, client} = start_supervised(Client)
      send(client, {:udp, nil, nil, nil, "{\"badpacket\":malformed JSON\"}"})
      send(client, {:udp, nil, nil, nil, F.example_evt_precip})
      send(client, {:udp, nil, nil, nil, "NOTJSON"})
      send(client, {:udp, nil, nil, nil, F.obs_st_with_multiple_observations})
      assert Client.get_packet_stats == %{packets_parsed: 2, packet_errors: 2}
    end

    test "get_hub_serials" do
      {:ok, client} = start_supervised(Client)
      ex = Jason.decode!(F.example_evt_precip)
      ex1 = ex
            |> Map.put("hub_sn", "HB-00009999")
            |> Map.put("serial_number", "SK-00008888")
      ex2 = ex
            |> Map.put("hub_sn", "HB-00007777")
            |> Map.put("serial_number", "SK-00006666")
      send(client, {:udp, nil, nil, nil, Jason.encode!(ex1)})
      send(client, {:udp, nil, nil, nil, Jason.encode!(ex2)})
      assert Enum.sort(Client.get_hub_serials()) == ["HB-00007777", "HB-00009999"]
    end
  end
end
