defmodule Genex.Builder.Render.Page do
  alias Genex.Builder.Render.Layout
  alias Genex.Builder.Render.Engines.Markdown
  alias Genex.Builder.Render.Engines.Heex
  alias Genex.Builder.Render.Utils

  # @renderers [Genex.Builder.Render.Engines.Heex]

  # use Phoenix.Template,
  #   root: "priv/content/pages",
  #   pattern: "**/*",
  #   namespace: Genex.Builder.Render

  require Logger

  def render_template(
        %{assigns: assigns, output_path: output_path, template_path: template_path, type: type},
        layout_chains
      ) do
    Logger.debug("Assigns: #{inspect(assigns, pretty: true)}")
    # 获取模板内容
    content = Utils.read_template(template_path, type)
    meta = Utils.parse_meta(content)
    Logger.info("Meta for template #{template_path}: #{inspect(meta, pretty: true)}")

    # 获取布局链
    layout_chain = layout_chains[Path.dirname(template_path)]

    Logger.info(
      "Layout chain for template #{template_path}: #{inspect(layout_chain, pretty: true)}"
    )

    layout_chain = Layout.rewrite_layout_chain(layout_chain, meta[:layout], layout_chains)
    Logger.info("Layout chain after rewrite: #{inspect(layout_chain, pretty: true)}")

    # 应用布局
    rendered_content = render_with_layouts(template_path, assigns, layout_chain, type: type)
    write_to_output(output_path, rendered_content, type: type)
  end

  def render(path, models: models, type: type, format: format, layouts: layouts) do
    site = Application.get_env(:genex, :site, [])
    site = Map.new(site)
    content = Utils.read_content(path)
    meta = Utils.parse_meta(content)
    Logger.info("Meta: #{inspect(meta, pretty: true)}")

    # 将meta添加到assigns中
    assigns =
      %{}
      |> Map.put(:meta, meta)
      |> Map.put(:site, site)

    rendered_content =
      case type do
        :content -> render_content(path, models: models, format: format, assigns: assigns)
        :page -> render_page(path, layouts, models: models, format: format, assigns: assigns)
      end

    dir = Path.dirname(path)
    layouts_for_template = layouts[dir] |> Enum.reverse()
    Logger.debug("Layouts for template: #{inspect(layouts_for_template)}")
    # assigns = Map.put(assigns, :site, site)
    layout_chain =
      Genex.Builder.Render.Layout.rewrite_layout_chain(
        layouts_for_template,
        meta[:layout],
        layouts
      )

    Logger.debug("Layout chain for template #{path}: #{inspect(layout_chain)}")

    rendered_content = apply_layouts_for_content(rendered_content, layout_chain, assigns)

    rendered_content
  end

  def render_content(content_path, models: models, assigns: assigns) do
    Logger.debug("Models: #{inspect(models, pretty: true)}")
    content = Utils.read_content(content_path)
    meta = Utils.parse_meta(content)
    Logger.debug("Meta: #{inspect(meta, pretty: true)}")
    rendered_content = Markdown.render(content)

    rendered_content
  end

  @spec render_page(binary(), map()) :: iodata()
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
  def render_page(template_path, layouts, [format: format] \\ [format: :heex]) do
    # Logger.info("Template: #{template}")
    # assigns = Map.new(assigns)
    # 添加全局配置，平铺在顶层，不要嵌套
    site = Application.get_env(:genex, :site, [])
    # Logger.info("Site: #{inspect(site, pretty: true)}")
    # Turn property list into a map
    site = Map.new(site)

    template_content = Genex.Builder.Render.Utils.read_template(template_path, format)
    meta = Genex.Builder.Render.Utils.parse_meta(template_content)
    Logger.info("Meta: #{inspect(meta, pretty: true)}")

    # 将meta添加到assigns中
    assigns =
      %{}
      |> Map.put(:meta, meta)
      |> Map.put(:site, site)

    rendered_content = Heex.render(template_path, assigns: assigns)

    dir = Path.dirname(template_path)
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

    Logger.debug("Layout chain for template #{template_path}: #{inspect(layout_chain)}")

    rendered_content = apply_layouts_for_content(rendered_content, layout_chain, assigns)

    rendered_content
  end

  defp render_with_layouts(template_path, assigns, layouts_for_template, opts) do
    # Logger.debug("Assigns: #{inspect(assigns, pretty: true)}")
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
              Genex.Template.View,
              template_path |> remove_extension(opts[:type]),
              "html",
              assigns
            )

          apply_layouts_for_content(content, layouts_for_template, assigns)

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
    rendered_content
  end

  def apply_layouts_for_content(content, layouts, assigns) do
    safe_content = {:safe, content}
    # 逐层应用布局
    {:safe, rendered_content} =
      Enum.reduce(layouts, safe_content, fn layout, inner_content ->
        layout_assigns = Map.put(assigns, :inner_content, inner_content)
        # Logger.info("Layout assigns: #{inspect(layout_assigns)}")

        result =
          Phoenix.Template.render_to_iodata(
            Genex.Template.View,
            layout,
            "html",
            layout_assigns
          )

        # Logger.info("Result: #{inspect(result)}")

        {:safe, result}
      end)

    # Logger.info("Rendered content: #{inspect(rendered_content)}")
    rendered_content
  end

  defp write_to_output(output_path, content, type: type) do
    Logger.error("Output path: #{inspect(output_path, pretty: true)}")
    full_path = Path.join(Utils.output_path(), output_path)
    dir = Path.dirname(full_path)
    # If the directory doesn't exist, create it
    unless File.exists?(dir) do
      File.mkdir_p!(dir)
    end

    File.write!(full_path, content)
  end

  defp remove_extension(path, type) do
    path |> String.replace(".#{type}", "")
  end
end
