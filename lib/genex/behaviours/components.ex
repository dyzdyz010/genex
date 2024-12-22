defmodule Genex.Components do
  defmacro __using__(_) do
    quote do
      use Phoenix.Component
    end
  end
end
