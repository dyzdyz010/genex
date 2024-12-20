defmodule Genex.Builder.Render.Engine do
  @callback render(String.t(), keyword()) :: String.t()

  @callback type() :: :heex | :markdown | :html
end
