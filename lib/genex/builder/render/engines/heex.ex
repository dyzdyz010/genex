defmodule Genex.Builder.Render.Engines.Heex do
  @behaviour Genex.Builder.Render.Engine

  @impl Genex.Builder.Render.Engine
  def render(content, _opts) do
    content
  end

  @impl Genex.Builder.Render.Engine
  def type() do
    :heex
  end
end
