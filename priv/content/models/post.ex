defmodule Genex.Models.Post do
  use Genex.Model,
    name: :post,
    folder: "posts",
    fields: [:title, :author, :date, :content]
end
