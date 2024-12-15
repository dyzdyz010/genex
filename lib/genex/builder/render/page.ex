defmodule Genex.Builder.Render.Page do
  use Phoenix.Template, root: "priv/content", pattern: "**/*", namespace: Genex.Builder.Render

  require Logger

  def render(template, assigns \\ []) do
    assigns = Map.new(assigns)
    # 添加全局配置，平铺在顶层，不要嵌套
    meta = Application.get_env(:genex, :project, [])[:meta]
    # Turn property list into a map
    meta = Map.new(meta)

    assigns = Map.put(assigns, :meta, meta)
    render_with_layouts(template, assigns)
  end

  defp render_with_layouts(template, assigns) do
    # 获取模板对应的布局链
    layouts = get_template_layouts(template)
    Logger.info("Layouts: #{inspect(layouts)}")

    # 从最内层开始渲染
    content =
      Phoenix.Template.render_to_iodata(
        Genex.Builder.Render.View,
        template,
        "html",
        assigns
      )

    # 逐层应用布局
    rendered_content =
      Enum.reduce(layouts, content, fn layout, inner_content ->
        layout_assigns = Map.put(assigns, :inner_content, inner_content)
        Logger.info("Layout assigns: #{inspect(layout_assigns)}")

        Phoenix.Template.render_to_iodata(
          Genex.Builder.Render.View,
          layout,
          "html",
          layout_assigns
        )
      end)

    # Save to output folder respecting the build config and template path
    # Create the output folder and all child folders if they don't exist
    write_to_output(template, rendered_content)
  end

  defp get_template_layouts(template) do
    # 从配置中获取布局链
    # 例如: pages/docs/guide.html -> ["pages/__layout__", "pages/docs/__layout__"]
    path_parts = Path.split(template)

    path_parts
    |> Enum.reduce({[], []}, fn part, {current_path, layouts} ->
      new_path = current_path ++ [part]
      layout_path = new_path |> Enum.slice(0..-2//1) |> Kernel.++(["__layout__"])
      {new_path, layouts ++ [layout_path |> Path.join()]}
    end)
    |> elem(1)
    |> Enum.filter(&layout_exists?/1)
    |> Enum.reverse()
  end

  defp layout_exists?(layout_path) do
    project_root = Application.get_env(:genex, :project_root)
    layout_file = Path.join([project_root, layout_path <> ".html.heex"])
    File.exists?(layout_file)
  end

  defp write_to_output(template, content) do
    output_folder = Application.get_env(:genex, :project, [])[:build][:output_folder]
    path = Path.join([output_folder, template]) <> ".html"
    dir = Path.dirname(path)
    # If the directory doesn't exist, create it
    unless File.exists?(dir) do
      File.mkdir_p!(dir)
    end

    File.write!(path, content)
  end
end
