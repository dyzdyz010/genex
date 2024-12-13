defmodule Genex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    IO.puts("Starting Genex application")

    Logger.info("Args: #{inspect(Burrito.Util.Args.argv(), pretty: true)}")

    children = [
      # Starts a worker by calling: Genex.Worker.start_link(arg)
      # {Genex.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Genex.Supervisor]
    Supervisor.start_link(children, opts)

    Genex.Cli.Runner.run()

    # Stop the application gracefully
    System.halt(0)
  end
end
