defmodule Genex.Models.Article do
  @behaviour Genex.Model

  use Genex.Model,
    name: "Article",
    folder: "articles",
    fields: [
      :title,
      :author,
      :date,
      :tags
    ]

  @impl Genex.Model
  def field_map() do
    %{
      slug: :title,
      tag: :tags
    }
  end
end
