defmodule Genex.Builder.Render.Page do
  alias Genex.Builder.Render.Utils

  # @renderers [Genex.Builder.Render.Engines.Heex]

  use Phoenix.Template,
    root: "priv/content/pages",
    pattern: "**/*",
    namespace: Genex.Builder.Render

  require Logger

  @doc """
  Render a page with the given template and assigns.

  ## Parameters
  - `template`: The path to the page template, relative to the pages folder.
  - `opts`: A list of `keyword` options to be passed to the template.

  ### Options
  - `type`: The type of the template, can be `:heex`, `:markdown`, or `:html`.

  ## Example
      iex> Genex.Builder.Render.Page.render("docs/guide", layouts, type: :heex)F
  """
  def render(template, layouts, opts \\ []) do
    # Logger.info("Template: #{template}")
    # assigns = Map.new(assigns)
    # 添加全局配置，平铺在顶层，不要嵌套
    site = Application.get_env(:genex, :project, [])[:site]
    # Logger.info("Site: #{inspect(site, pretty: true)}")
    # Turn property list into a map
    site = Map.new(site)

    template_content = Genex.Builder.Render.Utils.read_template(template, opts[:type])
    meta = Genex.Builder.Render.Utils.parse_meta(template_content)
    Logger.info("Meta: #{inspect(meta, pretty: true)}")

    # 将meta添加到assigns中
    assigns =
      %{}
      |> Map.put(:meta, meta)
      |> Map.put(:site, site)

    dir = Path.dirname(template)
    # Logger.debug("Dir: #{dir}")
    layouts_for_template = layouts[dir] |> Enum.reverse()
    Logger.debug("Layouts for template: #{inspect(layouts_for_template)}")
    # assigns = Map.put(assigns, :site, site)
    layout_chain =
      Genex.Builder.Render.Layout.rewrite_layout_chain(
        layouts_for_template,
        meta[:layout],
        layouts
      )

    Logger.debug("Layout chain for template #{template}: #{inspect(layout_chain)}")

    render_with_layouts(template, assigns, layout_chain, opts)
  end

  defp render_with_layouts(template, assigns, layouts_for_template, opts) do
    # pages_folder = Application.get_env(:genex, :project, [])[:build][:pages_folder]
    # template = Path.join([pages_folder, template])
    # Logger.debug("Template: #{template}")
    # Get dir path of the template
    # Get the layouts for the template
    # Logger.info("Layouts: #{inspect(layouts_for_template)}")

    rendered_content =
      case opts[:type] do
        :heex ->
          # 从最内层开始渲染
          content =
            Phoenix.Template.render_to_iodata(
              Genex.Builder.Render.View,
              template,
              "html",
              assigns
            )

          safe_content = {:safe, content}

          # 逐层应用布局
          {:safe, rendered_content} =
            Enum.reduce(layouts_for_template, safe_content, fn layout, inner_content ->
              layout_assigns = Map.put(assigns, :inner_content, inner_content)
              # Logger.info("Layout assigns: #{inspect(layout_assigns)}")

              result =
                Phoenix.Template.render_to_iodata(
                  Genex.Builder.Render.View,
                  layout,
                  "html",
                  layout_assigns
                )

              # Logger.info("Result: #{inspect(result)}")

              {:safe, result}
            end)

          # Logger.info("Rendered content: #{inspect(rendered_content)}")
          rendered_content

        :markdown ->
          Logger.info("Markdown")
          "Markdown is not supported yet"

        :html ->
          Logger.info("HTML")
          "HTML is not supported yet"

        :unknown ->
          Logger.info("Unknown")
          "Unknown is not supported yet"
      end

    # Save to output folder respecting the build config and template path
    # Create the output folder and all child folders if they don't exist
    write_to_output(template, rendered_content)
  end

  defp write_to_output(template, content) do
    # Logger.debug("Write to output: #{template}")
    # Logger.debug("Content: #{inspect(content)}")
    path = Path.join([Utils.output_path(), template]) <> ".html"
    # Logger.debug("Path: #{path}")
    dir = Path.dirname(path)
    # If the directory doesn't exist, create it
    unless File.exists?(dir) do
      File.mkdir_p!(dir)
    end

    File.write!(path, content)
  end
end
