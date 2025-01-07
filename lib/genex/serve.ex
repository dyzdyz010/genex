defmodule Genex.Serve do
  alias Genex.Builder.Render.Utils
  use GenServer

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, 4000)
    ignored_files = Keyword.get(opts, :ignored_files, [])

    case start_services(port) do
      {:ok, cowboy_ref, file_watcher_ref} ->
        Logger.info("Development server started on port #{port}")

        {:ok,
         %{
           cowboy_ref: cowboy_ref,
           port: port,
           file_watcher_ref: file_watcher_ref,
           ignored_files: ignored_files
         }}

      {:error, reason} ->
        Logger.error("Failed to start development server: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call(:stop, _from, state) do
    :ok = stop_cowboy(state.cowboy_ref)
    Logger.info("Development server stopped")
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_info({:file_event, _pid, {path, _events}}, state) do
    unless state.ignored_files
           |> Enum.any?(fn ignored_file -> String.contains?(path, ignored_file) end) do
      Logger.info("Detected file changes: #{path}")
      Logger.info("Detected file changes, rebuilding...")
      # 重新构建项目
      Task.start(fn ->
        Genex.Builder.build()
        Logger.info("Rebuild completed")
      end)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:file_event, _pid, :stop}, state) do
    Logger.warning("File monitor stopped unexpectedly")
    {:noreply, state}
  end

  defp start_services(port) do
    with {:ok, cowboy_ref} <- start_cowboy(port),
         {:ok, file_watcher_ref} <- start_file_watcher() do
      {:ok, cowboy_ref, file_watcher_ref}
    else
      error -> error
    end
  end

  defp start_file_watcher() do
    case FileSystem.start_link(dirs: [Utils.project_root()]) do
      {:ok, pid} ->
        Logger.info("File watcher started")
        FileSystem.subscribe(pid)
        {:ok, pid}

      error ->
        error
    end
  end

  defp start_cowboy(port) do
    output_dir = Utils.output_path()
    Logger.info("Serving files from #{output_dir}")

    dispatch =
      :cowboy_router.compile([
        {:_,
         [
           {
             "/",
             :cowboy_static,
             {
               :file,
               Path.join(output_dir, "index.html")
             }
           },
           {"/[...]", :cowboy_static,
            {
              :dir,
              output_dir,
              [{:mimetypes, :cow_mimetypes, :all}]
            }}
         ]}
      ])

    ref = make_ref()

    case :cowboy.start_clear(
           ref,
           [{:port, port}],
           %{env: %{dispatch: dispatch}}
         ) do
      {:ok, _} -> {:ok, ref}
      error -> error
    end
  end

  defp stop_cowboy(ref) do
    :cowboy.stop_listener(ref)
  end
end
