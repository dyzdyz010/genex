defmodule Genex.Cli.Commands.New do
  @behaviour Genex.Cli.Command

  @impl Genex.Cli.Command
  def name() do
    "new"
  end

  @impl Genex.Cli.Command
  def description() do
    "Create a new Genex project"
  end

  @impl Genex.Cli.Command
  def help() do
    """
    Usage:
      genex new <project_name>

    Options:
      --help, -h  Show help
    """
  end

  @impl Genex.Cli.Command
  def run(_opts, args) do
    IO.puts("Running new command with args: #{inspect(args, pretty: true)}")
  end
end
