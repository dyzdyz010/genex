defmodule Genex.Builder.Template do
  alias Genex.Builder.Utils.Content
  alias Genex.Builder.Render.Engines.Markdown
  require Logger

  def render_content(path_id) do
    content = Content.read_content(path_id)
    meta = Content.parse_meta(content)
    Logger.info("Meta: #{inspect(meta, pretty: true)}")

    rendered_content = Markdown.render(content)

    rendered_content
  end
end
