defmodule Genex.Builder.Render.PageTemplate do
  defstruct [
    # 文件在文件系统中的绝对路径
    :abs_path,
    # 相对于 pages/ 的相对路径，比如 "posts/[year]/[month]/[day]/[slug].heex"
    :rel_path,
    # [:year, :month, :day, :slug]  这个模板需要哪些占位符
    :params_schema,
    # 是否是 index.heex
    :is_index?,
    # 模板内容
    :layouts
  ]
end

defmodule Genex.Builder.Render.Post do
  alias Genex.Builder.Render.PageTemplate
  alias Genex.Builder.Render.Utils

  require Logger

  def build() do
    models_map = Genex.Builder.Posts.prepare()
    # Logger.debug("Models map: #{inspect(models_map, pretty: true)}")
    # Logger.debug("Content path: #{inspect(Utils.content_path(), pretty: true)}")
    content = prepare_content(Utils.content_path(), models_map)
    # Logger.debug("Content: #{inspect(content, pretty: true)}")
    templates = scan_templates()
    # Logger.debug("Templates: #{inspect(templates, pretty: true)}")

    templates
    |> Enum.each(fn template ->
      result = routes_for_template(template, content)
      Logger.debug("Result: #{inspect(result, pretty: true)}")
    end)
  end

  defp prepare_content(path, models_map) do
    Logger.debug("Path: #{inspect(path, pretty: true)}")

    data =
      Path.wildcard(Path.join(path, "**/*.md"))
      |> Enum.map(fn file ->
        filepath = Path.dirname(file)
        rel_folder = Path.relative_to(filepath, Utils.content_path())
        Logger.debug("Relative folder: #{inspect(rel_folder, pretty: true)}")
        [model_folder | _] = String.split(rel_folder, "/")

        {_model_name, model} =
          models_map |> Enum.find(fn {_, v} -> v.folder() == model_folder end)

        Logger.debug("Model: #{inspect(model, pretty: true)}")
        post_content = File.read!(file)
        Logger.debug("Post content: #{inspect(post_content, pretty: true)}")
        meta = Utils.parse_meta(post_content)
        # Logger.debug("Meta: #{inspect(meta, pretty: true)}")
        meta = meta |> Map.put(:content, post_content)
        data = model.model_from_map(meta)
        data
        # Logger.debug("Data: #{inspect(data, pretty: true)}")
        # post = Page.render_content(models_map, meta)
      end)

    # |> Enum.group_by(fn item ->
    #   item.__struct__.folder()
    # end)

    Logger.debug("Data: #{inspect(data, pretty: true)}")
    data
  end

  def scan_templates() do
    pages_dir = Utils.pages_path()

    Path.wildcard(Path.join([pages_dir, "**/*.heex"]))
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

      %PageTemplate{
        abs_path: abs_path,
        rel_path: rel_path,
        params_schema: params,
        is_index?: Path.basename(rel_path) == "index.heex"
      }
    end)
  end

  def routes_for_template(%PageTemplate{params_schema: schema, rel_path: rel_path}, items) do
    Logger.debug("Schema: #{inspect(schema, pretty: true)}")

    params_values =
      Enum.reduce(schema, %{}, fn param, acc ->
        Logger.debug("Param: #{inspect(param, pretty: true)}")

        values =
          items
          # 提取所有 param 值
          |> Enum.map(fn item ->
            # Logger.debug("Item: #{inspect(item, pretty: true)}")
            # 先从field_map中找到对应的字段，如果不存在则直接当作字段名
            # 如果字段类型为列表，则取列表中所有元素
            field_map = item.__struct__.field_map()

            field_name =
              case param do
                :slug -> param
                _ -> field_map[param] || param
              end

            value =
              case field_name do
                :slug -> item.__struct__.slug(item)
                _ -> Map.get(item, field_name)
              end

            # value = "#{value}"

            value =
              if is_list(value) do
                value |> List.flatten()
              else
                "#{value}"
              end

            # Logger.debug("Field name: #{inspect(field_name, pretty: true)}")
            # Logger.debug("Value: #{inspect(value, pretty: true)}")

            value
          end)
          # 将列表展开（处理 list 类型，如 tags）
          |> List.flatten()
          # 去重
          |> Enum.uniq()

        # Logger.debug("Values: #{inspect(values |> Enum.uniq(), pretty: true)}")

        Map.put(acc, param, values)
      end)

    Logger.debug("Params values: #{inspect(params_values, pretty: true)}")
    # params_values
    combinations = params_values |> generate_combinations()
    Logger.debug("Combinations: #{inspect(combinations, pretty: true)}")

    combinations
    |> Enum.map(fn param_map ->
      output_path = build_output_path(rel_path, param_map)

      # 过滤符合条件的数据项
      filtered_items =
        items
        |> Enum.filter(fn item ->
          Enum.all?(schema, fn param ->
            # 从 item 中获取 param 的值, 如果 param 是 list 类型，则检查 param_map_value 是否在 param_value 中

            param_value = Map.get(item, param)

            param_map_value = Map.get(param_map, param)

            cond do
              is_list(param_value) -> param_map_value in param_value
              true -> param_map_value == param_value
            end
          end)
        end)

      assigns = %{items: filtered_items, params: param_map}

      %{
        page_template: rel_path,
        output_path: output_path,
        assigns: assigns
      }
    end)
  end

  defp generate_combinations(pv) when map_size(pv) == 0, do: []

  defp generate_combinations(params_values) do
    keys = Map.keys(params_values)
    Logger.debug("Keys: #{inspect(keys, pretty: true)}")
    values = Map.values(params_values)
    Logger.debug("Values: #{inspect(values, pretty: true)}")

    values
    |> cartesian_product()
    |> Enum.map(fn combo ->
      Enum.zip(keys, combo) |> Enum.into(%{})
    end)
  end

  defp cartesian_product([]), do: [[]]

  defp cartesian_product([h | t]) do
    for x <- h,
        y <- cartesian_product(t),
        do: [x | y]
  end

  defp build_output_path(rel_path, param_map) do
    Enum.reduce(param_map, rel_path, fn {param, value}, acc ->
      String.replace(acc, "[#{param}]", to_string(value))
    end)
  end

  defp all_params_present?(param_map) do
    Enum.all?(param_map, fn {_k, v} -> not is_nil(v) end)
  end

  defp build_output_path(rel_path, param_map) do
    # 根据模板内容，生成路由
    rel_path
  end

  def extract_params(rel_path) do
    # Split by "/", 然后找带 "[" 的片段
    segments = String.split(rel_path, "/")

    segments
    |> Enum.flat_map(fn seg ->
      # seg可能是 "[year]" or "[slug].heex" etc
      # 先去掉可能的 ".heex" 后缀
      seg
      |> String.split(".")
      |> hd()
      |> case do
        "[" <> rest ->
          # "[year]" => "year]"
          String.trim_trailing(rest, "]") |> String.to_atom() |> List.wrap()

        _otherwise ->
          []
      end
    end)
  end
end
