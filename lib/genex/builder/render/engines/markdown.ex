defmodule Genex.Builder.Render.Engines.Markdown do
  alias Genex.Builder.Utils
  require Logger
  @behaviour Genex.Builder.Render.Engine

  @impl true
  def render(template_path, _opts \\ []) do
    content = Utils.read_template(template_path, :markdown)

    Logger.debug("Rendering Markdown content: #{inspect(template_path, pretty: true)}")
    MDEx.to_html!(content, render: [unsafe_: true])
  end

  def render_content(content) do
    MDEx.to_html!(content, render: [unsafe_: true])
  end

  @impl true
  def type() do
    :markdown
  end
end
