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
  def run(_opts, [project_name] = args) do
    IO.puts("Running new command with args: #{inspect(args, pretty: true)}")

    # 检查项目在当前路径是否存在
    project_path = Path.join(Path.absname("."), project_name)

    if File.exists?(project_path) do
      IO.puts("Project already exists: #{project_path}")
      System.stop()
    end

    # 创建项目
    File.mkdir_p!(project_path)

    # 将priv/standard中的所有内容复制到项目目录
    File.cp_r!(Path.join(:code.priv_dir(:genex), "standard"), project_path)

    true
  end
end
