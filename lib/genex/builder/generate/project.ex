defmodule Genex.Builder.Generate.Project do
  @moduledoc """
  Generate a new project.

  # Project structure

  ```
  project_name/
    .genex/
      config.exs
    posts/
      post_1.md
      post_2.md
    pages/
      page_1.md
      page_2.html.heex
  ```
  """
  @doc """
  Generate a new project, can specify the project name and the project path

  ## Available options

  - `:path`: The path to the project, defaults to the current working directory
  - `:posts_name`: The name of the posts folder, defaults to `posts`
  - `:pages_name`: The name of the pages folder, defaults to `pages`
  """
  def generate(project_name, opts \\ []) do
    IO.puts("Generating project #{project_name}")

    if opts[:path] do
      IO.puts("Project path: #{opts[:path]}")
    end

    # Create folder structure
    File.mkdir_p!(Path.join(opts[:path], project_name))

    # Create .genex folder
    File.mkdir_p!(Path.join(Path.join(opts[:path], project_name), ".genex"))

    # Create posts folder
    File.mkdir_p!(Path.join(Path.join(opts[:path], project_name), "posts"))

    # Create pages folder
    File.mkdir_p!(Path.join(Path.join(opts[:path], project_name), "pages"))
  end
end
