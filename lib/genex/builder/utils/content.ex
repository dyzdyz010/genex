defmodule Genex.Builder.Utils.Content do
  @moduledoc """
  Content utils
  """
  alias Genex.Builder.Render.Engines.Markdown
  alias Genex.Builder.Utils.Paths

  @doc """
  Read template file

  There are 2 kinds of templates:
  1. heex
  2. markdown
  """
  @spec read_template(String.t(), :heex | :markdown | :html | :unknown) :: String.t()
  def read_template(template, _type) do
    # Logger.info("Project root: #{project_root}")
    # Logger.info("Pages folder: #{pages_folder}")
    template_path = Path.join([Paths.pages_path(), template])
    # Find template with path but without .html.heex or .md

    File.read!(template_path)
  end

  @doc """
  Read content file

  ## Parameters
  - path_id: the path relative to the content folder, like "2024/12/20/index.md"
  """
  def read_content(path_id) do
    content_path = Path.join(Paths.content_path(), path_id)
    File.read!(content_path)
  end

  def parse_meta(content) do
    # Let the regex match:
    # <!--
    # @meta: %{
    #   layout: "pages/__layout__",
    #   title: "Guide Page",
    #   description: "This is the guide page"
    # }
    # -->
    regex = ~r/<!--\s*@meta:\s*(%\{.*?\})\s*-->/s

    case Regex.run(regex, content) do
      [_, meta] ->
        {meta, _} = Code.eval_string(meta)
        meta

      _ ->
        nil
    end
  end

  @doc """
  Render a model item
  """
  def render_model(model_item) do
    if Map.has_key?(model_item, :content) do
      # 已渲染过，直接返回
      model_item
    else
      raw_content = Map.get(model_item, :raw_content)
      rendered_content = Markdown.render_content(raw_content)
      Map.put(model_item, :content, {:safe, rendered_content})
    end
  end

  def remove_meta(content) do
    regex = ~r/<!--\s*@meta:\s*(%\{.*?\})\s*-->/s

    Regex.replace(regex, content, "")
    |> String.trim()
  end

  def cartesian_product([]), do: [[]]

  def cartesian_product([h | t]) do
    for x <- h,
        y <- cartesian_product(t),
        do: [x | y]
  end

  def remove_extension(path, type) do
    path |> String.replace(".#{type}", "")
  end
end
