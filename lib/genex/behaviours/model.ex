defmodule Genex.Model do
  defmacro __using__(name: name, fields: fields) do
    quote do
      defstruct unquote(fields)
      def name, do: unquote(name)
      def folder, do: unquote(name |> Atom.to_string())
      def fields, do: unquote(fields)
      def model_from_map(map), do: struct(__MODULE__, map)
    end
  end
end
