ExUnit.start()


# Start the PubSub for testing here
children = [
  {Phoenix.PubSub, [name: WeatherflowTempestTest]}
]
opts = [strategy: :one_for_one, name: WeatherflowTempestTest]
Supervisor.start_link(children, opts)
