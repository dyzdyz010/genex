defmodule Genex.Cli.Commands.Build do
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
    Genex.Builder.build()
  end
end
