import Config

config :genex, env: Mix.env()
# config :genex, env: :prod

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

import_config "#{Mix.env()}.exs"
