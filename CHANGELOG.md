# Changelog

## 1.0.0

* Update Elixir dependency to 1.10 or greater
* Documentation and code formatting updates
* Update for changes in Weatherflow API v171

### Enhancements

* Added :hub_sn key to the hub_status event. (Duplicates the :serial_number key
  as a convenience to allow matching against :hub_sn on all event types.)
* Added ability to pass callback functions to the client that will be used
  to handle parsed weatherflow events. (No longer strictly depends on pubsub)

### Breaking Changes

Version 1.0.0 has changed the API and will very likely break *any* existing uses
of the library. (This is why it's being released as 1.0.0, rather than 0.2.0)

  * The structs returned by library have changed. Keys are standardized to use
    atoms for all protocol keys, and only use strings for device serial numbers.
    For example:

    ```elixir
    device_statuses: %{
        "AR-00000001" => %{
            firmware_revision: 23
        }
    }
    ```

  * Returned :uptime key to being integer second (String description that was
    previously here is now in the :uptime_string field.)
  * Renamed WeatherflowTempest.PubSub.subscribe_udp_events/0 to
    `WeatherflowTempest.PubSub.subscribe_to_udp_events/0` for linguistic clarity.
  * Renamed the :windspeed_mps in a rapid_wind event to :wind_speed_mps for
    consistency with other field names.
  * Events are now emitted via the Phoenix.PubSub.broadcast method as
    {{:weatherflow, event_name}, object} tuples, rather than using
    %Phoenix.Socket.Broadcast{} struct, allowing the library to work correctly
    outside of a Phoenix app.
  * No longer automatically starts a Phoenix.PubSub if one is not defined
    via config.
  * No longer has Phoenix.PubSub as a :prod dependency, must be required by the
    parent app if the PubSub is going to be used.

## 0.1.0

* Initial Release
