import Config

config :genex,
  project_root: Path.join([File.cwd!(), "priv/content"])

config :logger, :console, format: "[$level] $message\n", level: :debug
