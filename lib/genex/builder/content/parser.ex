defmodule Genex.Builder.Content.Parser do
  alias Genex.Builder.Utils.Content

  def parse_meta(content, _model) do
    Content.parse_meta(content)
  end
end
