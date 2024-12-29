defmodule Genex.Builder.Render.Layout do
  require Logger
  alias Genex.Builder.Render.Utils

  @spec generate_layout_chains() :: map()
  @doc """
  Scan pages directory and generate layout chains mapping.

  **Return format:**

      %{
        "pages" => ["pages/__layout__"],
        "pages/docs" => ["pages/__layout__", "pages/docs/__layout__"],
        "pages/docs/api" => ["pages/__layout__", "pages/docs/__layout__"]
      }
  """
  def generate_layout_chains() do
    Utils.pages_path()
    |> scan_layouts(%{})
  end

  @spec rewrite_layout_chain(list(), nil | false | String.t() | list(), map()) :: list()
  def rewrite_layout_chain(default_chain, layout_config, layouts) do
    Logger.debug("layout_config: #{inspect(layout_config)}")

    case layout_config do
      nil ->
        default_chain

      false ->
        default_chain

      conf when is_binary(conf) ->
        new_chain = layouts[layout_config]
        # Logger.debug("new_chain: #{inspect(new_chain)}")

        if layouts_exist?(new_chain) do
          new_chain
        else
          raise "Layout #{layout_config} not found"
        end

      conf when is_list(conf) ->
        # 如果meta中layout为列表，则布局链重设为该列表
        # 检查列表中的布局是否存在，如果有不存在的布局则报错
        if layouts_exist?(conf) do
          conf
        else
          raise "Layout #{conf} not found"
        end
    end
  end

  defp scan_layouts(dir_path, acc) do
    rel_path = Path.relative_to(dir_path, Utils.pages_path())
    # Logger.debug("rel_path: #{rel_path}")

    # 构建当前目录的布局链并更新accumulator
    acc =
      case build_layout_chain(rel_path) do
        [] -> acc
        chain -> Map.put(acc, rel_path, chain)
      end

    # 递归处理子目录
    case File.ls(dir_path) do
      {:ok, files} ->
        Enum.reduce(files, acc, fn file, chain_acc ->
          full_path = Path.join(dir_path, file)
          if File.dir?(full_path), do: scan_layouts(full_path, chain_acc), else: chain_acc
        end)

      {:error, _} ->
        acc
    end
  end

  defp build_layout_chain(rel_path) do
    parts = Path.split(rel_path)
    # Logger.debug("parts: #{inspect(parts)}")

    root_layout = "__layout__"
    base_chain = if layout_exists?(root_layout), do: [root_layout], else: []

    case parts do
      ["."] -> base_chain
      _ -> build_path_chain(parts, base_chain)
    end
  end

  defp build_path_chain(parts, base_chain) do
    Enum.reduce(1..length(parts), base_chain, fn i, acc ->
      path_segment = Enum.take(parts, i)
      # Logger.debug("path_segment: #{inspect(path_segment)}")

      layout_path = Path.join(path_segment ++ ["__layout__"])
      if layout_exists?(layout_path), do: acc ++ [layout_path], else: acc
    end)
  end

  defp layouts_exist?(layouts) do
    Enum.all?(layouts, &layout_exists?/1)
  end

  defp layout_exists?(layout_path) do
    [Utils.pages_path(), layout_path <> ".html.heex"]
    |> Path.join()
    |> File.exists?()
  end
end
