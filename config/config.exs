use Mix.Config

config :logger, :console,
  format: "\n$date $time [$level] [Weatherflow_Tempest] $metadata$message"

if File.exists?("config/#{Mix.env}.exs"), do: import_config "#{Mix.env}.exs"
