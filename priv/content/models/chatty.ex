defmodule Genex.Models.Chatty do
  use Genex.Model,
    name: "Chatty",
    folder: "chatty",
    fields: [:title, :content, :date, :mood]

  def field_map() do
    %{
      slug: :title
    }
  end
end
