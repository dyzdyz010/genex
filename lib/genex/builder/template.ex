defmodule Genex.Builder.Template do
  alias Genex.Builder.Render.Utils
  alias Genex.Builder.Render.Engines.Markdown
  require Logger

  def render_content(path_id) do
    content = Utils.read_content(path_id)
    meta = Utils.parse_meta(content)
    Logger.info("Meta: #{inspect(meta, pretty: true)}")

    rendered_content = Markdown.render(content)

    rendered_content
  end
end
