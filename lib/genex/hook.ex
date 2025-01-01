defmodule Genex.Hook do
  require Logger

  def run_pre_hooks() do
    IO.puts("========== Pre hooks")
    pre_hook_path = Application.get_env(:genex, :hooks)[:pre]
    Logger.debug("Pre hook path: #{inspect(pre_hook_path, pretty: true)}")
    pre_hook_path |> run_hook()
  end

  def run_post_hooks() do
    IO.puts("========== Post hooks")
    post_hook_path = Application.get_env(:genex, :hooks)[:post]
    post_hook_path |> run_hook()
  end

  defp run_hook(script_name) do
    script_path = Path.join([Genex.Builder.Render.Utils.hooks_path(), script_name])
    IO.puts("Running hook: #{script_path}")
    Code.eval_file(script_path)
  end
end
