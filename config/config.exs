import Config

config :logger, :console,
  format: "\n$date $time [$level] [Weatherflow_Tempest] $metadata$message"

if File.exists?("config/#{config_env()}.exs"), do: import_config "#{config_env()}.exs"
