defmodule Mix.Tasks.Genex do
  use Mix.Task

  @shortdoc "Runs the Genex application"
  @moduledoc """
  Runs the Genex application.

  ## Usage

      mix genex
      mix genex [options]

  """

  @impl Mix.Task
  def run(args) do
    # 确保应用程序及其依赖已启动
    Mix.Task.run("app.start")

    # 处理参数
    case args do
      [] -> Genex.start()
      _ -> process_args(args)
    end
  end

  defp process_args(args) do
    # 这里处理命令行参数
    # 例如：help, version等
    case args do
      ["--help"] -> print_help()
      ["--version"] -> print_version()
      _ -> Genex.start(args)
    end
  end

  defp print_help do
    IO.puts """
    Genex - Elixir Application

    Usage:
      mix genex [options]

    Options:
      --help      Show this help message
      --version   Show version information
    """
  end

  defp print_version do
    {:ok, version} = :application.get_key(:genex, :vsn)
    IO.puts "Genex version #{version}"
  end
end
