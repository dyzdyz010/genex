defmodule Mix.Tasks.Genex do
  alias Genex.Cli
  use Mix.Task

  @shortdoc "Create a new Genex project"
  def run(args) do
    {command, opts, extra_args} = Cli.parse_args(args)

    cond do
      # 没有命令或 `help` 作为命令：显示帮助
      command == nil or (command in ["help", "--help", "-h"] and extra_args == []) ->
        Cli.print_all_commands_help()

      command in ["help", "--help", "-h"] and extra_args != [] ->
        # help 某个具体命令
        Cli.show_command_help(Enum.join(extra_args, " "))

      true ->
        # 执行具体命令
        Cli.run_command(command, opts, extra_args)
    end

    IO.puts("Running Genex commands with opts: #{inspect(opts, pretty: true)}")
    IO.puts("Running Genex commands with args: #{inspect(args, pretty: true)}")
  end
end
