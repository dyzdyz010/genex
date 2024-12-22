defmodule Genex.Builder.Render.Post do
  alias Genex.Builder.Render.Page
  alias Genex.Builder.Render.Utils

  def build() do
    models_map = Genex.Builder.Posts.prepare()
    prepare_posts(Utils.content_path(), models_map)
  end

  defp prepare_posts(path, models_map, posts \\ []) do
    posts =
      File.ls!(path)
      |> Enum.map(fn file ->
        if File.dir?(file) do
          prepare_posts(Path.join(path, file), models_map, posts)
        else
          if String.ends_with?(file, ".md") do
            post_content = File.read!(Path.join(path, file))
            meta = Utils.parse_meta(post_content)
            post = Page.render_content(models_map, meta)
          end
        end
      end)
  end
end
