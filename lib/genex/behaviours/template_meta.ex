defmodule Genex.TemplateMeta do
  defstruct [:title, :description, :layout]

  @type t() :: %__MODULE__{
          title: String.t(),
          description: String.t(),
          layout: String.t() | list(String.t()) | false
        }

  def parse(map) do
    result = struct(__MODULE__, map)
    result
  end
end
