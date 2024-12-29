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
    # 模板类型（slug, 列表或固定页面)
    :type
  ]

  @type t() :: %__MODULE__{
          abs_path: String.t(),
          rel_path: String.t(),
          params_schema: [atom()],
          is_index?: boolean(),
          # 只区分是否是详情页
          type: :slug | :static
        }
end

defmodule Genex.Builder.Render.Post do
  alias Genex.Builder.Render.Engines.Markdown
  alias Genex.Builder.Render.Engine
  alias Genex.Builder.Render.Layout
  alias Genex.Builder.Render.Page
  alias Genex.Builder.Render.PageTemplate
  alias Genex.Builder.Render.Utils

  require Logger

  def build() do
    Genex.Builder.clean()

    models_map = Genex.Builder.Posts.prepare()
    Logger.debug("Models map: #{inspect(models_map, pretty: true)}")
    # Logger.debug("Content path: #{inspect(Utils.content_path(), pretty: true)}")
    content = prepare_content(Utils.content_path(), models_map)

    field_values = collect_field_values(content)
    Logger.debug("Field values: #{inspect(field_values, pretty: true)}")

    # Logger.debug("Content: #{inspect(content, pretty: true)}")
    global_assigns = Genex.Builder.Assign.make_global_assigns(content)
    Logger.debug("Global assigns: #{inspect(global_assigns, pretty: true)}")
    # Logger.debug("Content: #{inspect(content, pretty: true)}")
    templates = scan_templates()
    # Logger.debug("Templates: #{inspect(templates, pretty: true)}")

    result =
      templates
      |> Enum.map(fn template ->
        routes_for_template(template, content, global_assigns)
      end)
      |> List.flatten()

    # Logger.warning("Result: #{inspect(result, pretty: true)}")

    Logger.warning(
      "Result: #{inspect(result |> Enum.filter(fn x -> x.template_path == "posts/[date.year]/[date.month]/[slug].html.heex" end), pretty: true)}"
    )

    layout_chains = Layout.generate_layout_chains()
    # Logger.debug("Layout chains: #{inspect(layout_chains, pretty: true)}")

    Genex.Builder.Render.View.gen_view_module()

    result
    |> Enum.map(fn x ->
      Page.render_template(x, layout_chains)
    end)

    :ok
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
        Logger.debug("Model folder: #{inspect(model_folder, pretty: true)}")

        {_model_name, model} =
          models_map |> Enum.find(fn {_, v} -> v.folder() == model_folder end)

        Logger.debug("Model: #{inspect(model, pretty: true)}")
        post_content = File.read!(file)
        # Logger.debug("Post content: #{inspect(post_content, pretty: true)}")
        meta = Utils.parse_meta(post_content)

        rendered_content = Markdown.render_content(post_content)
        # Logger.debug("Meta: #{inspect(meta, pretty: true)}")
        meta = meta |> Map.put(:content, {:safe, rendered_content})
        data = model.model_from_map(meta)
        data
        # Logger.debug("Data: #{inspect(data, pretty: true)}")
        # post = Page.render_content(models_map, meta)
      end)

    # |> Enum.group_by(fn item ->
    #   item.__struct__.folder()
    # end)

    # Logger.debug("Data: #{inspect(data, pretty: true)}")
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

  def routes_for_template(
        %PageTemplate{params_schema: schema, rel_path: rel_path},
        _items,
        global_assigns
      ) do
    template_type =
      case String.split(rel_path, ".") |> List.last() do
        "heex" -> :heex
        "md" -> :markdown
        "html" -> :html
        _ -> :unknown
      end

    # 如果没有参数schema，说明是静态模板
    if Enum.empty?(schema) do
      [
        %{
          template_path: rel_path,
          output_path: build_output_path(rel_path, %{}),
          assigns: global_assigns,
          schema: [],
          type: template_type
        }
      ]
    else
      Logger.debug("Schema: #{inspect(schema, pretty: true)}")

      # 获取模型文件夹名
      model_folder = rel_path |> String.split("/") |> List.first()
      model_items = global_assigns.content[model_folder |> String.to_atom()]

      Logger.debug("Model folder: #{inspect(model_folder, pretty: true)}")

      params_values =
        Enum.reduce(schema, %{}, fn param, acc ->
          # Logger.debug("Param: #{inspect(param, pretty: true)}")

          values =
            model_items
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
                  _ -> attr_resolve(item, field_name)
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
      |> Enum.flat_map(fn param_map ->
        filtered_items =
          model_items
          |> Enum.filter(fn item ->
            Enum.all?(schema, fn param ->
              field_map = item.__struct__.field_map()

              # 获取实际的字段名
              {field_name, is_mapped} =
                case param do
                  # slug 是特殊处理
                  :slug ->
                    {:slug, true}

                  _ ->
                    mapped = Map.get(field_map, param)
                    if mapped, do: {mapped, true}, else: {param, false}
                end

              # Logger.debug("Field name: #{inspect(field_name, pretty: true)}")

              # 获取参数值
              param_value =
                case field_name do
                  :slug -> item.__struct__.slug(item)
                  _ -> attr_resolve(item, field_name)
                end

              param_map_value = attr_resolve(param_map, param)

              Logger.debug("Param map value: #{inspect(param_map_value, pretty: true)}")
              Logger.debug("Param value: #{inspect(param_value, pretty: true)}")

              cond do
                # 如果是映射字段且值为列表，检查是否包含
                is_mapped and is_list(param_value) ->
                  param_map_value in List.flatten(param_value)

                # 如果是映射字段，直接比较值
                is_mapped ->
                  param_map_value == param_value

                # 非映射字段，转换为字符串后比较
                true ->
                  "#{param_map_value}" == "#{param_value}"
              end
            end)
          end)

        # 只有filtered_items长度大于0时，才返回
        case length(filtered_items) > 0 do
          true ->
            [%{items: filtered_items, params: param_map}]

          false ->
            []
        end
      end)
      |> Enum.map(fn %{items: filtered_items, params: param_map} ->
        # Logger.debug("Param map: #{inspect(param_map, pretty: true)}")
        output_path = build_output_path(rel_path, param_map)

        # 过滤符合条件的数据项

        # Logger.debug("Filtered items: #{inspect(filtered_items, pretty: true)}")

        # 如果是[slug]模板，则为item，否则为items
        specific_assigns =
          if Path.basename(rel_path) == "[slug].html.heex" do
            %{item: filtered_items |> List.first(), params: param_map}
          else
            %{items: filtered_items, params: param_map}
          end

        assigns =
          global_assigns
          |> Map.merge(specific_assigns)

        %{
          template_path: rel_path,
          output_path: output_path,
          assigns: assigns,
          schema: schema,
          type: template_type
        }
      end)
      |> Enum.filter(fn x ->
        # Logger.debug(
        #   "Filter for #{inspect(params_values, pretty: true)}: #{inspect(x.assigns[:item] != nil or (x.assigns[:items] != [] and x.assigns[:params] != nil), pretty: true)}"
        # )

        x.assigns[:item] != nil or (x.assigns[:items] != [] and x.assigns[:params] != nil)
      end)
    end
  end

  defp generate_combinations(pv) when map_size(pv) == 0, do: []

  defp generate_combinations(params_values) do
    keys = Map.keys(params_values)
    Logger.debug("Keys: #{inspect(keys, pretty: true)}")
    values = Map.values(params_values)
    Logger.debug("Values: #{inspect(values, pretty: true)}")

    values
    |> Utils.cartesian_product()
    |> Enum.map(fn combo ->
      Enum.zip(keys, combo) |> Enum.into(%{})
    end)
  end

  # defp cartesian_product([]), do: [[]]

  # defp cartesian_product([h | t]) do
  #   for x <- h,
  #       y <- cartesian_product(t),
  #       do: [x | y]
  # end

  # 根据模板内容，生成路由
  # ## Parameters
  # - `rel_path`: 模板相对路径，如：
  #     "posts/[year]/[month]/[day]/[slug].html.heex" 或
  #     "docs/about.md"
  # - `param_map`: 参数值，如 `%{year: "2024", month: "12", day: "25", slug: "hello-world"}`
  # ## Returns
  # - 路由，如 "posts/2024/12/25/hello-world.html"
  defp build_output_path(rel_path, param_map) do
    output_path =
      Enum.reduce(param_map, rel_path, fn {param, value}, acc ->
        String.replace(acc, "[#{param}]", to_string(value))
      end)

    output_path =
      if String.ends_with?(output_path, ".heex") do
        String.replace(output_path, ".heex", "")
      else
        # If markdown, replace ".md" with ".html"
        if String.ends_with?(output_path, ".md") do
          String.replace(output_path, ".md", ".html")
        else
          output_path
        end
      end

    use_index_file = Application.get_env(:genex, :build)[:use_index_file]

    if use_index_file and not String.ends_with?(output_path, "index.html") do
      (output_path |> String.trim_trailing(".html")) <> "/index.html"
    else
      output_path
    end
  end

  def extract_params(rel_path) do
    # Split by "/", 然后找带 "[" 的片段
    segments = String.split(rel_path, "/")

    segments
    |> Enum.flat_map(fn seg ->
      # seg可能是 "[year]" or "[slug].heex" etc
      # 先去掉可能的 ".heex" 后缀
      seg
      |> Page.remove_extension(:heex)
      |> Page.remove_extension(:md)
      |> Page.remove_extension(:html)
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

  def collect_field_values(items) do
    items
    |> Enum.group_by(fn item -> item.__struct__.folder |> String.to_atom() end)
    |> Enum.map(fn {model, items} ->
      field_values =
        Enum.reduce(items, %{}, fn item, acc ->
          item_fields = Map.from_struct(item)

          Enum.reduce(item_fields, acc, fn {field, value}, acc_inner ->
            if field in [:__struct__, :__meta__] do
              acc_inner
            else
              values = Map.get(acc_inner, field, [])

              updated_values =
                case value do
                  # 处理列表值
                  v when is_list(v) -> values ++ v
                  v -> [v | values]
                end
                |> Enum.uniq()

              Map.put(acc_inner, field, updated_values)
            end
          end)
        end)

      {model, field_values}
    end)
    |> Enum.into(%{})
  end

  def attr_resolve(data, path) do
    Logger.debug("Path: #{inspect(path, pretty: true)}")
    Logger.debug("Data: #{inspect(data, pretty: true)}")

    if data |> Map.has_key?(path) do
      data |> Map.get(path)
    else
      path
      |> Atom.to_string()
      |> String.split(".")
      |> Enum.map(&String.to_existing_atom/1)
      |> Enum.reduce(data, &Map.get(&2, &1))
    end
  end
end
