defmodule Genex.Builder.Utils.Paths do
  require Logger

  @doc """
  Get the project root
  """
  def project_root() do
    current_dir = File.cwd!()

    project_root = Application.get_env(:genex, :project_root, current_dir)

    project_root
  end

  @doc """
  Get the path to the assets folder
  """
  def assets_path() do
    project_root = project_root()
    assets_folder = Application.get_env(:genex, :build)[:assets_folder]
    Path.join([project_root, assets_folder])
  end

  @doc """
  Get the path to the pages folder
  """
  def pages_path() do
    project_root = project_root()
    pages_folder = Application.get_env(:genex, :build)[:pages_folder]
    Path.join([project_root, pages_folder])
  end

  @doc """
  Get the path to the content folder
  """
  def content_path() do
    project_root = project_root()
    content_folder = Application.get_env(:genex, :build)[:content_folder]
    Path.join([project_root, content_folder])
  end

  @doc """
  Get the path to the output folder
  """
  def output_path() do
    project_root = project_root()
    Logger.debug("Project root: #{project_root}")
    output_folder = Application.get_env(:genex, :build)[:output_folder]
    Logger.debug("Output folder: #{output_folder}")
    Path.join([project_root, output_folder])
  end

  @doc """
  Get the path to the pages folder in the output folder
  """
  def output_pages_path() do
    output_path = output_path()
    pages_folder = Application.get_env(:genex, :build)[:pages_folder]
    Path.join([output_path, pages_folder])
  end

  def models_path() do
    project_root = project_root()
    models_folder = Application.get_env(:genex, :build)[:models_folder]
    Path.join([project_root, models_folder])
  end

  def helpers_path() do
    project_root = project_root()
    helpers_folder = Application.get_env(:genex, :build)[:helpers_folder]
    Path.join([project_root, helpers_folder])
  end

  def components_path() do
    project_root = project_root()
    components_folder = Application.get_env(:genex, :build)[:components_folder]
    Path.join([project_root, components_folder])
  end

  def hooks_path() do
    project_root = project_root()
    hooks_folder = Application.get_env(:genex, :hooks)[:folder]
    Path.join([project_root, hooks_folder])
  end
end
