defmodule Genex.Builder.Render.View do
  alias Genex.Builder.Render.CoreComponents
  use Phoenix.View, root: "priv/content/pages", pattern: "**/*", namespace: Genex.Builder.Render

  # import Phoenix.HTML
  import CoreComponents
end
