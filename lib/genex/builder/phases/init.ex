defmodule Genex.Builder.Phases.Init do
  @moduledoc """
  Initialize the build directory
  """

  @spec run(Genex.Builder.Context.t()) :: Genex.Builder.Context.t()
  def run(context) do
    IO.puts("#{IO.ANSI.blue()}[3/10] Initializing build directory...")
    output_path = Path.join(context.project_root, context.config[:build][:output_folder])
    # Clean the output directory
    File.rm_rf!(output_path)
    File.mkdir_p!(output_path)
    File.mkdir_p!(Path.join(output_path, "assets"))

    IO.puts("#{IO.ANSI.green()}[3/10] Build directory initialized")

    context
  end
end
