defmodule Genex.Builder.Scanner do
  require Logger
  alias Genex.Model
  alias Genex.Builder.Utils.Paths
  alias Genex.Builder.Types.PageTemplate
  alias Genex.Builder.Utils.Content

  @type model_map() :: %{String.t() => Model.t()}

  @spec scan_content(binary(), model_map()) :: [Model.t()]
  @doc """
  Scan the content folder and return a list of models.

  The content doesn't need to be organized in a specific folder structure.

  The actual folder structure is determined by the template structure.

  ## Return
  A list of un-rendered models.
  """
  def scan_content(content_path, models_map) do
    # Logger.debug("Path: #{inspect(path, pretty: true)}")

    data =
      Path.wildcard(Path.join(content_path, "**/*.md"))
      |> Enum.map(fn file ->
        filepath = Path.dirname(file)
        rel_folder = Path.relative_to(filepath, Paths.content_path())
        Logger.debug("Relative folder: #{inspect(rel_folder, pretty: true)}")
        [model_folder | _] = String.split(rel_folder, "/")
        # Logger.debug("Model folder: #{inspect(model_folder, pretty: true)}")

        {_model_name, model} =
          models_map |> Enum.find(fn {_, m} -> m.folder() == model_folder end)

        # Logger.debug("Model: #{inspect(model, pretty: true)}")
        post_content = File.read!(file)
        # Logger.debug("Post content: #{inspect(post_content, pretty: true)}")
        meta_map = Content.parse_meta(post_content)

        # rendered_content = Markdown.render_content(post_content)
        # Logger.debug("Meta: #{inspect(meta, pretty: true)}")
        model_map = meta_map |> Map.put(:raw_content, post_content)
        model_data = model.model_from_map(model_map)
        Logger.debug("Model: #{inspect(model_data, pretty: true)}")
        model_data
        # post = Page.render_content(models_map, meta)
      end)

    data
  end

  def scan_templates() do
    pages_dir = Paths.pages_path()

    Path.wildcard(Path.join([pages_dir, "**/*.{heex,md}"]))
    |> Enum.filter(fn abs_path ->
      filename = Path.basename(abs_path)
      # 过滤掉 __*__ 开头的文件（布局模板）
      not String.starts_with?(filename, "__")
    end)
    |> Enum.map(fn abs_path ->
      rel_path = Path.relative_to(abs_path, pages_dir)
      # Logger.debug("Rel path: #{inspect(rel_path, pretty: true)}")
      params = extract_params(rel_path)
      # Logger.debug("Params: #{inspect(params, pretty: true)}")

      type =
        if Path.basename(rel_path) == "[slug].html.heex" do
          :slug
        else
          :static
        end

      %PageTemplate{
        abs_path: abs_path,
        rel_path: rel_path,
        params_schema: params,
        is_index?: Path.basename(rel_path) == "index.heex",
        type: type
      }
    end)
  end

  defp extract_params(rel_path) do
    # Split by "/", 然后找带 "[" 的片段
    segments = String.split(rel_path, "/")

    segments
    |> Enum.flat_map(fn seg ->
      # seg可能是 "[year]" or "[slug].heex" etc
      # 先去掉可能的 ".heex" 后缀
      seg
      |> Content.remove_extension(:heex)
      |> Content.remove_extension(:md)
      |> Content.remove_extension(:html)
      # |> hd()
      |> case do
        "[" <> rest ->
          # Logger.debug("Rest: #{inspect(rest |> String.trim_trailing("]"), pretty: true)}")
          # "[year]" => "year]"
          String.trim_trailing(rest, "]") |> String.to_atom() |> List.wrap()

        _otherwise ->
          []
      end
    end)
  end
end
