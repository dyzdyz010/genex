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
  alias Genex.Builder.Assign
  alias Genex.Builder.Render.Engines.Markdown
  alias Genex.Builder.Render.Layout
  alias Genex.Builder.Render.Page
  alias Genex.Builder.Render.PageTemplate
  alias Genex.Builder.Render.Utils

  require Logger

  def build() do
    Genex.Builder.clean()

    models_map = Genex.Builder.Model.prepare()
    # Logger.debug("Models map: #{inspect(models_map, pretty: true)}")
    # Logger.debug("Content path: #{inspect(Utils.content_path(), pretty: true)}")
    content = prepare_content(Utils.content_path(), models_map)

    # Logger.debug("Content: #{inspect(content, pretty: true)}")
    global_assigns = Genex.Builder.Assign.make_global_assigns(content)
    # Logger.debug("Global assigns: #{inspect(global_assigns, pretty: true)}")
    # # Logger.debug("Content: #{inspect(content, pretty: true)}")
    templates = scan_templates()
    # Logger.debug("Templates: #{inspect(templates, pretty: true)}")

    routes =
      templates
      |> Enum.map(fn template ->
        routes_for_template(template, content, global_assigns)
      end)
      |> List.flatten()

    # Logger.warning("Routes: #{inspect(routes, pretty: true)}")

    {global_assigns, routes} = update_links(global_assigns, routes)
    routes = resolve_single_item(routes)

    Logger.warning(
      "Routes: #{inspect(routes |> Enum.filter(fn x -> x.template_path == "posts/[collection]/index.html.heex" end), pretty: true)}"
    )

    # Logger.debug("Global assigns: #{inspect(global_assigns, pretty: true)}")

    layout_chains = Layout.generate_layout_chains()
    # Logger.debug("Layout chains: #{inspect(layout_chains, pretty: true)}")

    Genex.Builder.Render.View.gen_view_module()

    routes
    |> Enum.map(fn x ->
      assigns = x.assigns

      Page.render_template(
        x |> Map.put(:assigns, assigns |> Map.merge(global_assigns)),
        layout_chains
      )
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
          assigns: %{data: %{items: [], fields: %{}}, params: %{}},
          schema: [],
          type: template_type
        }
      ]
    else
      Logger.debug("Schema: #{inspect(schema, pretty: true)}")

      # 获取模型文件夹名
      model_folder = rel_path |> String.split("/") |> List.first()
      model_items = global_assigns.content[model_folder |> String.to_atom()][:items]

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

        field_values = Assign.collect_field_values(filtered_items)

        specific_assigns = %{
          data: %{
            items: filtered_items,
            fields: field_values
          },
          params: param_map
        }

        Logger.debug("Specific assigns: #{inspect(specific_assigns, pretty: true)}")

        %{
          template_path: rel_path,
          output_path: output_path,
          assigns: specific_assigns,
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
        # URL转义
        String.replace(acc, "[#{param}]", to_string(value |> url_escape()))
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

  def update_links(global_assigns, routes) do
    links_by_slug =
      routes
      |> Enum.filter(fn x -> x.template_path |> String.ends_with?("[slug].html.heex") end)
      |> Enum.reduce(%{}, fn x, acc ->
        output_path = x.output_path
        assigns = x.assigns

        items =
          cond do
            Map.has_key?(assigns, :data) and Map.has_key?(assigns.data, :item) ->
              [assigns.data.item]

            Map.has_key?(assigns, :data) and Map.has_key?(assigns.data, :items) ->
              assigns.data.items

            true ->
              []
          end

        Enum.reduce(items, acc, fn item, acc_inner ->
          Map.put(acc_inner, item.slug, output_path)
        end)
      end)

    Logger.warning("Links by slug: #{inspect(links_by_slug, pretty: true)}")

    # 更新global_assigns中的content
    updated_content =
      Enum.map(global_assigns.content, fn {folder, folder_content} ->
        items = folder_content.items

        updated_items =
          update_content_with_links(items, links_by_slug)

        {folder, Map.put(folder_content, :items, updated_items)}
      end)
      |> Enum.into(%{})

    global_assigns = Map.put(global_assigns, :content, updated_content)

    routes =
      routes
      |> Enum.map(fn route ->
        unless route.assigns.data.items == [] do
          assigns = route.assigns
          # Logger.debug("Assigns: #{inspect(assigns, pretty: true)}")

          items = assigns.data.items |> update_content_with_links(links_by_slug)

          assigns_data = assigns.data |> Map.put(:items, items)

          route
          |> Map.put(:assigns, assigns |> Map.put(:data, assigns_data))
        else
          route
        end
      end)

    {global_assigns, routes}
  end

  def update_content_with_links(items, links_by_slug) do
    items
    |> Enum.map(fn item ->
      case Map.get(links_by_slug, item.slug) do
        nil -> item
        link -> Map.put(item, :link, link)
      end
    end)
  end

  def resolve_single_item(routes) do
    routes
    |> Enum.map(fn route ->
      assigns = route.assigns

      unless assigns == nil do
        specific_assigns =
          if Path.basename(route.template_path) == "[slug].html.heex" do
            %{data: %{item: assigns.data.items |> List.first()}, params: assigns.params}
          else
            %{
              data: %{items: assigns.data.items, fields: assigns.data.fields},
              params: assigns.params
            }
          end

        route |> Map.delete(:assigns) |> Map.put(:assigns, specific_assigns)
      else
        route
      end
    end)
  end

  defp url_escape(value) do
    # 空格变-，小写，其他特殊字符全部去掉
    value =
      value
      |> String.downcase()
      |> String.replace(" ", "-")

    # Use regex
    value = Regex.replace(~r/[^a-z0-9-]+/, value, "")

    value
  end
end
