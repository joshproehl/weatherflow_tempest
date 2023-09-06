use Mix.Config

# For testing we'll use a random ephemeral port to "listen" on,
# which will work fine since we won't actually be doing any listening.
# This prevents collisions, either with async, or if we're developing
# both the library and a client using it at the same time.
config :weatherflow_tempest, listen_port: 0
