defmodule Mix.Tasks.Genex.Archive.Build do
  use Mix.Task

  @shortdoc "Builds a Genex archive file"
  @moduledoc """
  Builds a Genex archive file.

  ## Usage

      mix genex.archive.build
      mix genex.archive.build [options]

  ## Options

      * `--output` or `-o` - the output file
      * `--no-deps` - do not include dependencies

  """

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [output: :string, no_deps: :boolean], aliases: [o: :output])

    # 确保项目已编译
    Mix.Task.run("compile")

    # 设置默认输出文件名
    output = opts[:output] || "genex-#{Genex.MixProject.project()[:version]}.ez"

    # 构建归档文件
    extra_args = if opts[:no_deps], do: ["--no-deps"], else: []
    Mix.Tasks.Archive.Build.run(["--output", output] ++ extra_args)

    Mix.shell().info([:green, "* creating ", :reset, Path.relative_to_cwd(output)])
  end
end

defmodule Mix.Tasks.Genex.Archive.Install do
  use Mix.Task

  @shortdoc "Installs Genex archive file"
  @moduledoc """
  Installs Genex archive file locally.

  ## Usage

      mix genex.archive.install

  This will build and install the archive file.
  """

  @impl Mix.Task
  def run(args) do
    # 先构建归档文件
    Mix.Task.run("genex.archive.build", args)

    # 获取归档文件名
    output = "genex-#{Genex.MixProject.project()[:version]}.ez"

    # 安装归档文件
    Mix.Tasks.Archive.Install.run(["--force", output])
  end
end
