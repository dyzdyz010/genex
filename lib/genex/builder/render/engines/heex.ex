defmodule Genex.Builder.Render.Engines.Heex do
  # alias Genex.Builder.Render.Utils
  @behaviour Genex.Builder.Render.Engine

  require Logger

  # use Phoenix.Template,
  #   root: Utils.pages_path(),
  #   pattern: "**/*",
  #   namespace: Genex.Builder.Render.Engines

  @impl Genex.Builder.Render.Engine
  def render(path, assigns: assigns) do
    Logger.info("View module: #{inspect(Genex.Template.View, pretty: true)}")

    rendered_content =
      Phoenix.Template.render_to_iodata(Genex.Template.View, path, "html", assigns)

    rendered_content
  end

  @impl Genex.Builder.Render.Engine
  def type() do
    :heex
  end
end
