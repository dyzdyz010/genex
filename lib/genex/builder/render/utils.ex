defmodule Genex.Builder.Render.Utils do
  require Logger

  def project_root() do
    current_dir = File.cwd!()

    project_root = Application.get_env(:genex, :project_root, current_dir)

    project_root
  end

  @doc """
  Read template file

  There are 2 kinds of templates:
  1. heex
  2. markdown
  """
  @spec read_template(String.t()) :: String.t()
  def read_template(template) do
    project_root = project_root()
    pages_folder = Application.get_env(:genex, :project, [])[:build][:pages_folder]
    Logger.info("Project root: #{project_root}")
    Logger.info("Pages folder: #{pages_folder}")
    template_path = Path.join([project_root, pages_folder, template])
    # Find template with path but without .html.heex or .md

    File.read!(template_path <> ".html.heex")
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
end
