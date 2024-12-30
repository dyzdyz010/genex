defmodule Genex.Builder.Model do
  alias Genex.Builder.Render.Utils

  require Logger

  def prepare() do
    # Unload all models
    # current_models()
    # |> Enum.each(fn mod ->
    #   Logger.info("Unloading model: #{inspect(mod, pretty: true)}")
    #   :code.purge(mod)
    # end)

    models_path = Utils.models_path()
    load_model_files(models_path)

    models_map = build_models_map()
    Logger.info("Models map: #{inspect(models_map, pretty: true)}")
    load_content(models_map)
    models_map
  end

  defp load_content(models_map) do
    content_path = Utils.content_path()

    File.ls!(content_path)
    |> Enum.map(fn file ->
      Logger.debug("File: #{inspect(file, pretty: true)}")
      path_id = Path.join(content_path, file)
      Genex.Builder.Content.Parser.parse_meta(path_id, models_map)
    end)
  end

  defp load_model_files(path) do
    # 扫描models目录下的所有文件
    # 如果是文件夹，则递归搜索
    File.ls!(path)
    |> Enum.map(fn file ->
      Logger.info("File: #{inspect(file, pretty: true)}")

      if File.dir?(file) do
        load_model_files(Path.join(path, file))
      else
        if String.ends_with?(file, ".ex") do
          module_path = Path.join(path, file)
          Logger.info("Module path: #{inspect(module_path, pretty: true)}")
          result = Code.compile_file(module_path)
          Logger.info("Result: #{inspect(result, pretty: true)}")
          result
        end
      end
    end)
  end

  def current_models() do
    :code.all_loaded()
    |> Enum.map(fn {mod, _beamfile} -> mod end)
    |> Enum.filter(fn mod ->
      module_in_models? = mod |> Atom.to_string() |> String.starts_with?("Elixir.Genex.Models")
      module_in_models? and function_exported?(mod, :name, 0)
    end)
  end

  def build_models_map() do
    models_map =
      :code.all_loaded()
      |> Enum.map(fn {mod, _beamfile} -> mod end)
      |> Enum.filter(fn mod ->
        if mod == Genex.Models.Post do
          Logger.debug("Mod: #{inspect(mod |> Atom.to_string(), pretty: true)}")
        end

        module_in_models? = mod |> Atom.to_string() |> String.starts_with?("Elixir.Genex.Models")
        module_in_models? and function_exported?(mod, :name, 0)
      end)
      |> Enum.map(fn mod ->
        # 从模块中获取模型名称
        model_name = mod.name()
        {model_name, mod}
      end)
      |> Enum.into(%{})

    models_map
  end
end
