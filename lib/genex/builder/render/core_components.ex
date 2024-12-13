defmodule Genex.Builder.Render.CoreComponents do
  use Phoenix.Component

  embed_templates("templates/*")

  attr(:title, :string, required: true)
  slot(:inner)

  def card(assigns) do
    ~H"""
    <div class="card">
      <h1>{@title}</h1>
      <%= render_slot(@inner) %>
    </div>
    """
  end
end
