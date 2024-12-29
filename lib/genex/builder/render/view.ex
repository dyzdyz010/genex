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
        # import Genex.Helper.General

        use Phoenix.View,
          root: unquote(pages_path),
          pattern: "**/*",
          namespace: Genex.Template

        import Genex.Builder.Render.CoreComponents

        def title(site, meta) do
          base = site.title
          title = meta[:title]

          if title != nil do
            "#{base} | #{title}"
          else
            base
          end
        end
      end
    end
    |> Code.compile_quoted()

    Genex.Template.View
  end
end
