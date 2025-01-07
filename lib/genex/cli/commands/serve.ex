defmodule Genex.Cli.Commands.Serve do
  alias Genex.Builder.Render.Utils
  @behaviour Genex.Cli.Command

  require Logger

  @impl Genex.Cli.Command
  def name() do
    "serve"
  end

  @impl Genex.Cli.Command
  def description() do
    "Start the development server"
  end

  @impl Genex.Cli.Command
  def help() do
    """
    Usage:
      genex serve
    """
  end

  @impl Genex.Cli.Command
  def run(_opts, _args) do
    IO.puts("Starting development server")
    port = Application.get_env(:genex, :watch)[:port]

    ignored_files = [
      Utils.output_path()
      | Application.get_env(:genex, :watch)[:ignored_files]
        |> Enum.map(fn path -> Path.join(Utils.project_root(), path) end)
    ]

    Logger.info("Ignored files: #{inspect(ignored_files)}")
    Genex.Serve.start_link(port: port, ignored_files: ignored_files)

    false
  end
end
