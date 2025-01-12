defmodule Genex.Builder.Assign do
  require Logger

  def make_global_assigns(full_content) do
    site_config = make_site_assigns()
    content_config = make_content_assigns(full_content)
    # Logger.debug("Content config: #{inspect(content_config, pretty: true)}")

    %{
      site: site_config,
      content: content_config
    }
  end

  defp make_site_assigns() do
    # 获取配置
    site_config = Application.get_env(:genex, :site, %{})
    # site_config = config[:site]

    site_config |> Enum.into(%{})
  end

  defp make_content_assigns(full_content) do
    # 分Model，对每个字段进行取值遍历
    full_content
    |> Enum.group_by(fn item -> item.__struct__.folder() |> String.to_atom() end)
    |> Enum.map(fn {folder, items} ->
      field_values = collect_field_values(items)
      {folder, %{items: items, fields: field_values}}
    end)
    |> Enum.into(%{})

    # |> Enum.map(fn {folder, items} ->
    #   # 获取Model的所有字段
    #   model_fields = items |> Enum.map(fn item -> item.__struct__.fields end)
    #   {folder, model_fields}
    # end)
  end

  def collect_field_values(items) do
    items
    |> Enum.reduce(%{}, fn item, acc ->
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
  end
end
