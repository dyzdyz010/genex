defmodule Genex.Cli do
  alias Genex.Builder.Render.Utils
  require Logger

  @commands [
    Genex.Cli.Commands.New,
    Genex.Cli.Commands.Build
  ]

  def run() do
    # Detect if we are in a Genex project by checking if the .genex/config.exs file exists
    unless load_project_config() do
      IO.puts("Not in a Genex project")
      # Stop the application gracefully if we are not in a Genex project
      Application.stop(:genex)
    end

    # IO.puts("Running Genex commands with args: #{inspect(args, pretty: true)}")

    IO.inspect(Application.get_env(:genex, :project))

    args = Burrito.Util.Args.argv()

    {command, opts, extra_args} = parse_args(args)

    cond do
      # 没有命令或 `help` 作为命令：显示帮助
      command == nil or (command in ["help", "--help", "-h"] and extra_args == []) ->
        print_all_commands_help()

      command in ["help", "--help", "-h"] and extra_args != [] ->
        # help 某个具体命令
        show_command_help(Enum.join(extra_args, " "))

      true ->
        # 执行具体命令
        run_command(command, opts, extra_args)
    end
  end

  defp parse_args([]), do: {nil, [], []}

  defp parse_args([maybe_command | rest]) do
    {opts, extra, invalid} =
      OptionParser.parse(rest,
        strict: [output_dir: :string, verbose: :boolean, port: :integer, watch_dir: :string],
        aliases: [h: :help, o: :output_dir, v: :verbose, p: :port, w: :watch_dir]
      )

    if invalid != [] do
      IO.puts("Invalid options: #{inspect(invalid)}")
      System.halt(1)
    end

    {maybe_command, opts, extra}
  end

  defp run_command(command_name, opts, args) do
    case Enum.find(@commands, fn cmd -> cmd.name() == command_name end) do
      nil ->
        IO.puts("Unknown command: #{command_name}")
        print_all_commands_help()
        System.halt(1)

      cmd_mod ->
        cmd_mod.run(opts, args)
    end
  end

  defp print_all_commands_help do
    IO.puts("Usage: genex <command> [options]")
    IO.puts("\nCommands:")

    for cmd <- @commands do
      IO.puts("  #{cmd.name()}  - #{cmd.description()}")
    end

    IO.puts("\nRun `genex help <command>` for details on a specific command.")
  end

  defp show_command_help(command_name) do
    case Enum.find(@commands, fn cmd -> cmd.name() == command_name end) do
      nil ->
        IO.puts("No such command: #{command_name}")
        System.halt(1)

      cmd_mod ->
        IO.puts(cmd_mod.help())
    end
  end

  # def is_genex_project() do
  #   project_root = Application.get_env(:genex, :project_root, nil)
  #   Logger.info("Checking if we are in a Genex project with root: #{project_root}")
  #   File.exists?(Path.join([project_root, ".genex/config.exs"]))
  # end

  defp load_project_config() do
    # Get current directory

    case Genex.Config.load_project_config(Utils.project_root()) do
      {:ok, config} ->
        Logger.info("Loaded project config: #{inspect(config, pretty: true)}")
        Application.put_env(:genex, :project, config)
        true

      {:error, error} ->
        Logger.error("Failed to load project config: #{error}")
        false
    end
  end
end
