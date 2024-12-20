import Config
import IO, only: [puts: 1]

config :genex,
  project_root: Path.join([File.cwd!(), "priv/content"])

config :logger, :console, format: "[$level] $message\n", level: :debug

puts("Config: ")
