defmodule Genex.Model do
  defmacro __using__(name: name, folder: folder, fields: fields) do
    quote do
      defstruct unquote(fields)
      def name, do: unquote(name)
      def folder, do: unquote(folder)
      def fields, do: unquote(fields)
      def model_from_map(map), do: struct(__MODULE__, map)
    end
  end
end
