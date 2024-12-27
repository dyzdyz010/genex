defmodule Genex.Builder.Assign do
  require Logger

  def make_global_assigns(full_content) do
    site_config = make_site_assigns()
    content_config = make_content_assigns(full_content)
    Logger.debug("Content config: #{inspect(content_config, pretty: true)}")

    %{
      site: site_config,
      content: content_config
    }
  end

  defp make_site_assigns() do
    # 获取配置
    config = Application.get_env(:genex, :project, %{})
    site_config = config[:site]

    site_config |> Enum.into(%{})
  end

  defp make_content_assigns(full_content) do
    # 分Model，对每个字段进行取值遍历
    full_content
    |> Enum.group_by(fn item -> item.__struct__.folder end)
    |> Enum.map(fn {folder, items} ->
      # 获取Model的所有字段
      model_fields = items |> Enum.map(fn item -> item.__struct__.fields end)
      {folder, model_fields}
    end)
  end
end
