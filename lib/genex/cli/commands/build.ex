defmodule Genex.Cli.Commands.Build do
  alias Genex.Cli
  @behaviour Genex.Cli.Command

  @impl Genex.Cli.Command
  def name() do
    "build"
  end

  @impl Genex.Cli.Command
  def description() do
    "Build the project"
  end

  @impl Genex.Cli.Command
  def help() do
    """
    Usage:
      genex build


    """
  end

  @impl Genex.Cli.Command
  def run(_opts, _args) do
    IO.puts("Running build command")

    unless Cli.load_project_config() do
      IO.puts("Not in a Genex project")
      # Stop the application gracefully if we are not in a Genex project
      System.stop()
    end

    Genex.Builder.build()
  end
end
