defmodule Genex.Builder.Render.Utils do
  require Logger

  def project_root() do
    current_dir = File.cwd!()

    project_root = Application.get_env(:genex, :project_root, current_dir)

    project_root
  end

  def assets_path() do
    project_root = project_root()
    assets_folder = Application.get_env(:genex, :build)[:assets_folder]
    Path.join([project_root, assets_folder])
  end

  def pages_path() do
    project_root = project_root()
    pages_folder = Application.get_env(:genex, :build)[:pages_folder]
    Path.join([project_root, pages_folder])
  end

  def content_path() do
    project_root = project_root()
    content_folder = Application.get_env(:genex, :build)[:content_folder]
    Path.join([project_root, content_folder])
  end

  def output_path() do
    project_root = project_root()
    output_folder = Application.get_env(:genex, :build)[:output_folder]
    Path.join([project_root, output_folder])
  end

  def output_pages_path() do
    output_path = output_path()
    pages_folder = Application.get_env(:genex, :build)[:pages_folder]
    Path.join([output_path, pages_folder])
  end

  def models_path() do
    project_root = project_root()
    models_folder = Application.get_env(:genex, :build)[:models_folder]
    Path.join([project_root, models_folder])
  end

  @doc """
  Read template file

  There are 2 kinds of templates:
  1. heex
  2. markdown
  """
  @spec read_template(String.t(), :heex | :markdown | :html | :unknown) :: String.t()
  def read_template(template, type) do
    # Logger.info("Project root: #{project_root}")
    # Logger.info("Pages folder: #{pages_folder}")
    template_path = Path.join([pages_path(), template])
    # Find template with path but without .html.heex or .md

    File.read!(template_path)
  end

  @doc """
  Read content file

  ## Parameters
  - path_id: the path relative to the content folder, like "2024/12/20/index.md"
  """
  def read_content(path_id) do
    content_path = Path.join(content_path(), path_id)
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
end
