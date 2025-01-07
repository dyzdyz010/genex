defmodule Genex.Builder.Render.View do
  require Logger

  # alias Genex.Builder.Render.CoreComponents
  alias Genex.Builder.Render.Utils
  # use Phoenix.View, root: "priv/content/pages", pattern: "**/*", namespace: Genex.Builder.Render

  # # import Phoenix.HTML
  # import CoreComponents

  def gen_view_module() do
    if Code.ensure_loaded?(Genex.Template.View) do
      :code.delete(Genex.Template.View)
      :code.purge(Genex.Template.View)
    end

    pages_path = Utils.pages_path()

    quote do
      defmodule Genex.Template.View do
        alias Genex.Builder.Render.CoreComponents
        # import Genex.Helper.General

        use Phoenix.View,
          root: unquote(pages_path),
          pattern: "**/*",
          namespace: Genex.Template

        import Phoenix.HTML
        import Genex.Builder.Render.CoreComponents

        unquote(load_components_module())

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

  def load_components_module() do
    components_path = Utils.components_path()

    :code.all_loaded()
    |> Enum.map(fn {mod, _} -> mod end)
    |> Enum.filter(fn mod ->
      mod_str = Atom.to_string(mod)
      String.starts_with?(mod_str, "Elixir.Genex.Components")
    end)
    |> Enum.each(fn mod ->
      Logger.debug("Purging component module: #{inspect(mod)}")
      :code.delete(mod)
      :code.purge(mod)
    end)

    for file <- File.ls!(components_path) do
      file_path = Path.join(components_path, file)
      IO.inspect(file_path)

      # Load file
      Code.compile_file(file_path)
    end

    :code.all_loaded()
    |> Enum.map(fn {mod, _beamfile} -> mod end)
    |> Enum.filter(fn mod ->
      mod_str = mod |> Atom.to_string()

      if mod_str |> String.starts_with?("Elixir.Genex.Components") and
           not (mod_str |> String.ends_with?("Elixir.Genex.Components")) do
        Logger.debug("Mod: #{inspect(mod_str, pretty: true)}")
      end

      module_in_models? =
        mod_str |> String.starts_with?("Elixir.Genex.Components") and
          not (mod_str |> String.ends_with?("Elixir.Genex.Components"))

      module_in_models?
    end)
    |> Enum.map(fn mod ->
      Logger.debug("ComponentMod: #{inspect(mod |> Atom.to_string(), pretty: true)}")

      quote do
        import unquote(mod)
      end
    end)
  end
end
