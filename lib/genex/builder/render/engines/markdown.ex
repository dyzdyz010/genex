defmodule Genex.Builder.Render.Engines.Markdown do
  @behaviour Genex.Builder.Render.Engine

  @impl true
  def render(content, _opts \\ []) do
    MDEx.to_html!(content, render: [unsafe_: true])
  end

  @impl true
  def type() do
    :markdown
  end
end
