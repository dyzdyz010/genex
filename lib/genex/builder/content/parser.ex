defmodule Genex.Builder.Content.Parser do
  alias Genex.Builder.Utils

  def parse_meta(content, _model) do
    Utils.parse_meta(content)
  end
end
