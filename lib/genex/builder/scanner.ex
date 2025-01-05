defmodule Genex.Builder.Scanner do
  require Logger
  alias Genex.Builder.Render.Utils
  alias Genex.Builder.Render.Engines.Markdown
  alias Genex.Builder.Types.PageTemplate

  def scan_content(path, models_map) do
    # Logger.debug("Path: #{inspect(path, pretty: true)}")

    data =
      Path.wildcard(Path.join(path, "**/*.md"))
      |> Enum.map(fn file ->
        filepath = Path.dirname(file)
        rel_folder = Path.relative_to(filepath, Utils.content_path())
        # Logger.debug("Relative folder: #{inspect(rel_folder, pretty: true)}")
        [model_folder | _] = String.split(rel_folder, "/")
        # Logger.debug("Model folder: #{inspect(model_folder, pretty: true)}")

        {_model_name, model} =
          models_map |> Enum.find(fn {_, v} -> v.folder() == model_folder end)

        # Logger.debug("Model: #{inspect(model, pretty: true)}")
        post_content = File.read!(file)
        # Logger.debug("Post content: #{inspect(post_content, pretty: true)}")
        meta_map = Utils.parse_meta(post_content)

        rendered_content = Markdown.render_content(post_content)
        # Logger.debug("Meta: #{inspect(meta, pretty: true)}")
        meta_map = meta_map |> Map.put(:content, {:safe, rendered_content})
        data = model.model_from_map(meta_map)
        data
        # Logger.debug("Data: #{inspect(data, pretty: true)}")
        # post = Page.render_content(models_map, meta)
      end)

    data
  end

  def scan_templates() do
    pages_dir = Utils.pages_path()

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
      |> Utils.remove_extension(:heex)
      |> Utils.remove_extension(:md)
      |> Utils.remove_extension(:html)
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
