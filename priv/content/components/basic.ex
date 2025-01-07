defmodule Genex.Components.Basic do
  use Genex.Components


  attr(:label, :string, required: true)
  attr(:link, :string, required: true)

  def button(assigns) do
    ~H"""
    <a href={@link} class="p-2 bg-blue-500 text-white rounded-md">{@label}</a>
    """
  end
end
