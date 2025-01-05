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
    # Logger.debug("Assigns: #{inspect(assigns, pretty: true)}")
    # 获取模板内容
    content = Utils.read_template(template_path, type)

    # if template_path == "markdown.md" do
    #   Logger.warning("Content: #{inspect(content, pretty: true)}")
    # end

    meta = Utils.parse_meta(content)
    # Logger.info("Meta for template #{template_path}: #{inspect(meta, pretty: true)}")

    # 获取布局链
    layout_chain = layout_chains[Path.dirname(template_path)]

    # Logger.info(
    #   "Layout chain for template #{template_path}: #{inspect(layout_chain, pretty: true)}"
    # )

    layout_chain =
      Layout.rewrite_layout_chain(layout_chain, meta[:layout], layout_chains)
      |> Enum.sort_by(
        fn x ->
          # 按照布局路径从顶到底
          length(Path.split(x))
        end,
        :desc
      )

    # Logger.warning("Layout chain after rewrite: #{inspect(layout_chain, pretty: true)}")

    assigns = Map.put(assigns, :meta, meta)

    # 应用布局
    rendered_content = render_with_layouts(template_path, assigns, layout_chain, type: type)
    write_to_output(output_path, rendered_content)
  end

  defp render_with_layouts(template_path, assigns, layouts_for_template, opts) do
    # Logger.debug(
    #   "Template type for template #{template_path}: #{inspect(opts[:type], pretty: true)}"
    # )

    rendered_content =
      case opts[:type] do
        type when type in [:heex, :html] ->
          Heex.render(template_path |> Utils.remove_extension(opts[:type]), assigns: assigns)

        :markdown ->
          Markdown.render(template_path)

        :unknown ->
          raise "Unknown type: #{opts[:type]}"
      end

    if template_path == "posts/[date.year]/[date.month]/[slug].html.heex" do
      # Logger.error("Rendered content: #{inspect(rendered_content, pretty: true)}")
    end

    # Save to output folder respecting the build config and template path
    # Create the output folder and all child folders if they don't exist
    rendered_content |> apply_layouts_for_content(layouts_for_template, assigns)
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

    # Logger.error("Rendered content: #{inspect(rendered_content)}")
    rendered_content
  end

  defp write_to_output(output_path, content) do
    # Logger.warning("Output path: #{inspect(output_path, pretty: true)}")
    full_path = Path.join(Utils.output_path(), output_path)
    dir = Path.dirname(full_path)
    # If the directory doesn't exist, create it
    unless File.exists?(dir) do
      File.mkdir_p!(dir)
    end

    File.write!(full_path, content)
  end
end
