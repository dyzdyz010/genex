defmodule Genex.Models.Post do
  use Genex.Model,
    name: "Post",
    folder: "posts",
    fields: [:title, :author, :collection, :tags, :date, :content]

  def field_map() do
    %{
      tag: :tags,
      slug: :title
    }
  end
end
