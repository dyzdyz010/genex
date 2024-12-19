defmodule Genex.Builder do
  require Logger

  def build() do
    IO.puts("#{IO.ANSI.green()}Start building site...")
    build_pages()
    build_posts()
  end

  defp build_pages() do
    IO.puts("#{IO.ANSI.green()}Start building pages...")

    # 遍历pages目录下的所有文件
    # 读取文件内容
    # 渲染文件内容
    # 保存渲染后的文件

    project_root = Application.get_env(:genex, :project, [])[:root]
    pages_dir = Path.join([project_root, "pages"])
    IO.puts("Pages dir: #{pages_dir}")
  end

  defp build_posts() do
    IO.puts("#{IO.ANSI.green()}Start building posts...")
  end
end
