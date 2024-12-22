defmodule Genex.Builder.Render.View do
  # alias Genex.Builder.Render.CoreComponents
  alias Genex.Builder.Render.Utils
  # use Phoenix.View, root: "priv/content/pages", pattern: "**/*", namespace: Genex.Builder.Render

  # # import Phoenix.HTML
  # import CoreComponents

  def gen_view_module() do
    pages_path = Utils.pages_path()

    quote do
      defmodule Genex.Template.View do
        alias Genex.Builder.Render.CoreComponents

        use Phoenix.View,
          root: unquote(pages_path),
          pattern: "**/*",
          namespace: Genex.Template

        import Genex.Builder.Render.CoreComponents
      end
    end
    |> Code.compile_quoted()

    Genex.Template.View
  end
end
