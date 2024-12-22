defmodule Genex.Builder.Render.Engines.Heex do
  # alias Genex.Builder.Render.Utils
  @behaviour Genex.Builder.Render.Engine

  require Logger

  # use Phoenix.Template,
  #   root: Utils.pages_path(),
  #   pattern: "**/*",
  #   namespace: Genex.Builder.Render.Engines

  @impl Genex.Builder.Render.Engine
  def render(path, opts) do
    view_module = Genex.Builder.Render.View.gen_view_module()
    Logger.info("View module: #{inspect(view_module, pretty: true)}")

    assigns = opts[:assigns]

    rendered_content =
      Phoenix.Template.render_to_iodata(view_module, path, "html", assigns)

    rendered_content
  end

  @impl Genex.Builder.Render.Engine
  def type() do
    :heex
  end
end
