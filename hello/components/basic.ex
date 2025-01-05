defmodule Genex.Components.Basic do
  use Genex.Components

  def greet(assigns) do
    ~H"""
    <div>
      <h1 class="text-2xl font-bold">Hello World</h1>
    </div>
    """
  end
end
