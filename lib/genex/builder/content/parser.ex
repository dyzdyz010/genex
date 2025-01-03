defmodule Genex.Builder.Content.Parser do
  alias Genex.Builder.Render.Utils

  def parse_meta(content, _model) do
    Utils.parse_meta(content)
  end
end
