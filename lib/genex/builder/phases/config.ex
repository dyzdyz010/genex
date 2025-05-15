defmodule Genex.Builder.Phases.Config do
  @moduledoc """
  Config phase
  """

  alias Genex.Builder.Utils.Paths

  @doc """
  Read the config file
  """
  def load(context) do
    IO.puts("#{IO.ANSI.blue()}[1/10] Loading config...")

    case Genex.Config.load_project_config(Paths.project_root()) do
      {:ok, config} ->
        context =
          context
          |> Map.put(:config, config)
          |> Map.put(:project_root, Paths.project_root())

        IO.puts("#{IO.ANSI.green()}[1/10] Config loaded")
        context

      {:error, error} ->
        throw(error)
    end
  end
end
