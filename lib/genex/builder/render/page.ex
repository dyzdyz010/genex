defmodule Genex.Builder.Render.Page do
  use Phoenix.Template, root: "lib/templates", pattern: "**/*", namespace: Genex.Builder.Render

  def render(template, assigns \\ []) do
    Phoenix.Template.render_to_string(Genex.Builder.Render.View, template, "html", assigns)
  end
end
