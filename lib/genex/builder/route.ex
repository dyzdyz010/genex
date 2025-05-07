defmodule Genex.Builder.Route do
  alias Genex.Builder.Utils.Content
  alias Genex.Builder.Assign
  alias Genex.Builder.Types.PageTemplate

  require Logger

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
      # Logger.debug("Schema: #{inspect(schema, pretty: true)}")

      # 获取模型文件夹名
      model_folder = rel_path |> String.split("/") |> List.first()
      model_items = global_assigns.content[model_folder |> String.to_atom()][:items]

      # Logger.debug("Model folder: #{inspect(model_folder, pretty: true)}")

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

      # Logger.debug("Params values: #{inspect(params_values, pretty: true)}")

      # params_values
      combinations = params_values |> generate_combinations()
      # Logger.debug("Combinations: #{inspect(combinations, pretty: true)}")

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

              # Logger.debug("Param map value: #{inspect(param_map_value, pretty: true)}")
              # Logger.debug("Param value: #{inspect(param_value, pretty: true)}")

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

        # Logger.debug("Specific assigns: #{inspect(specific_assigns, pretty: true)}")

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
    # Logger.debug("Keys: #{inspect(keys, pretty: true)}")
    values = Map.values(params_values)
    # Logger.debug("Values: #{inspect(values, pretty: true)}")

    values
    |> Content.cartesian_product()
    |> Enum.map(fn combo ->
      Enum.zip(keys, combo) |> Enum.into(%{})
    end)
  end

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

  def attr_resolve(data, path) do
    # Logger.debug("Path: #{inspect(path, pretty: true)}")
    # Logger.debug("Data: #{inspect(data, pretty: true)}")

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
