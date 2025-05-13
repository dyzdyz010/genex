defmodule Genex do
  @moduledoc """
  Documentation for `Genex`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Genex.hello()
      :world

  """
  def hello do
    :world
  end

  @doc """
  Starts the Genex application.
  """
  def start(args \\ []) do
    IO.puts "Starting Genex..."

    # 启动应用逻辑
    # 可以在这里处理传入的参数并启动相应的功能

    # 如果应用需要长时间运行，可以使用以下方式保持应用运行
    # unless IEx.started? do
    #   :timer.sleep(:infinity)
    # end
  end
end
