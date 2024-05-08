ExUnit.start()

# Start the PubSub for testing
children = [
  {Phoenix.PubSub, [name: WeatherflowTempestTestPubSub]}
]

opts = [strategy: :one_for_one, name: WeatherflowTempestTest]
Supervisor.start_link(children, opts)
