defmodule Genex.Builder do
  require Logger
  alias Genex.Builder.Render.Utils

  def build() do
    IO.puts("#{IO.ANSI.green()}Start building site...")
    clean()
    build_layouts()
    build_posts()
    build_pages()
  end

  defp clean() do
    IO.puts("#{IO.ANSI.green()}Start cleaning site...")
    output_folder = Utils.output_path()
    File.rm_rf!(output_folder)
  end

  defp build_pages() do
    IO.puts("#{IO.ANSI.green()}Start building pages...")
    layouts = build_layouts()
    scan_and_build_pages(Utils.pages_path(), layouts)
  end

  defp build_posts() do
    IO.puts("#{IO.ANSI.green()}Start building posts...")
  end

  defp build_layouts() do
    Logger.debug("Start building layouts...")
    Genex.Builder.Render.Layout.generate_layout_chains()
  end

  defp scan_and_build_pages(dir_path, layouts) do
    case File.ls(dir_path) do
      {:ok, files} ->
        Enum.each(files, fn file ->
          full_path = Path.join(dir_path, file)
          Logger.info("Full path: #{full_path}")

          if File.dir?(full_path) do
            scan_and_build_pages(full_path, layouts)
          else
            if is_actual_page(file) do
              Logger.debug("file: #{file}")
              template = Path.relative_to(full_path, Utils.pages_path())
              Logger.debug("Template: #{template}")

              Genex.Builder.Render.Page.render(
                remove_extension(template, template_type(template)),
                layouts,
                type: template_type(template)
              )
            end
          end
        end)
    end
  end

  defp template_type(filename) do
    cond do
      String.ends_with?(filename, ".html.heex") -> :heex
      String.ends_with?(filename, ".md") -> :markdown
      String.ends_with?(filename, ".html") -> :html
      true -> :unknown
    end
  end

  defp remove_extension(filename, type) do
    String.replace(
      filename,
      case type do
        :heex ->
          ".html.heex"

        :markdown ->
          ".md"

        :html ->
          ".html"

        _ ->
          filename |> String.split(".") |> List.last()
      end,
      ""
    )
  end

  defp is_actual_page(filename) do
    not String.starts_with?(filename, "__") and
      not String.starts_with?(filename, ".") and
      not String.starts_with?(filename, "[")
  end
end
