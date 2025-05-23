defmodule Genex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  defmodule TaskWorker do
    use GenServer

    def start_link(_) do
      GenServer.start_link(__MODULE__, nil)
    end

    @impl true
    def init(_) do
      send(self(), :run_task)
      {:ok, nil}
    end

    @impl true
    def handle_info(:run_task, state) do
      should_stop = Genex.Cli.run()

      Logger.debug("Env: #{Application.get_env(:genex, :env)}")

      # 非开发环境，停止应用
      if Application.get_env(:genex, :env) == :prod and should_stop do
        System.stop()
      end

      {:noreply, state}
    end
  end

  @impl true
  def start(_type, _args) do
    IO.puts("Starting Genex application")
    # Logger.info("Mix env: #{Application.get_env(:genex, :env)}")

    # Logger.info("Pwd: #{File.cwd!()}")

    # Logger.info("Args: #{inspect(Burrito.Util.Args.argv(), pretty: true)}")

    children = [
      {TaskWorker, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Genex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
