defmodule Genex.Config do
  @moduledoc """
  Handles configuration loading and management for Genex projects.
  """

  @doc """
  Loads the configuration from the project's .genex/config.exs file.
  Returns the loaded configuration or an error tuple.
  """
  def load_project_config(project_path) do
    config_path = Path.join([project_path, ".genex", "config.exs"])

    if File.exists?(config_path) do
      try do
        config_path
        |> Config.Reader.read!()
        |> Enum.into(%{})
        |> Map.get(:genex, %{})
      rescue
        e ->
          {:error, "Failed to load config: #{Exception.message(e)}"}
      end
    else
      {:error, "Config file not found at #{config_path}"}
    end
  end

  @doc """
  Gets a value from the configuration using a key path.

  ## Examples
      iex> config = %{layouts: %{"posts/*" => "post_layout"}}
      iex> Genex.Config.get_in_config(config, [:layouts, "posts/*"])
      "post_layout"
  """
  def get_in_config(config, keys) when is_list(keys) do
    get_in(config, keys)
  end
end
