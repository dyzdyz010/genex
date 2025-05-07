defmodule Genex.Serve do
  alias Genex.Builder.Utils.Paths
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
  def handle_info({:file_event, _pid, {path, events}}, state) do
    if(
      state.ignored_files
      |> Enum.all?(fn ignored_file -> not String.contains?(path, ignored_file) end) and
        (events != [:modified] and events != [:created])
    ) do
      try do
        Logger.info("Detected file changes: #{path}")
        Logger.debug("Detected file changes: #{inspect(events, pretty: true)}")
        Logger.info("Detected file changes, rebuilding...")
        Genex.Builder.build()
        Logger.info("Rebuild completed")
      rescue
        e ->
          Logger.error("Error rebuilding: #{inspect(e, pretty: true)}")
      end
    end

    # unless state.ignored_files
    #        |> Enum.any?(fn ignored_file -> String.contains?(path, ignored_file) end) and
    #          (events == [:modified] or events == [:created]) do
    #   Logger.info("Detected file changes: #{path}")
    #   Logger.debug("Detected file changes: #{inspect(events, pretty: true)}")
    #   Logger.info("Detected file changes, rebuilding...")
    #   # 重新构建项目
    #   # Task.start(fn ->
    #   #   Genex.Builder.build()
    #   #   Logger.info("Rebuild completed")
    #   # end)
    # end

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
    case FileSystem.start_link(dirs: [Paths.project_root()]) do
      {:ok, pid} ->
        Logger.info("File watcher started")
        FileSystem.subscribe(pid)
        {:ok, pid}

      error ->
        error
    end
  end

  defp start_cowboy(port) do
    output_dir = Paths.output_path()
    Logger.info("Serving files from #{output_dir}")

    dispatch =
      :cowboy_router.compile([
        {:_,
         [
           {
             "/[...]",
             :cowboy_static,
             {
               :dir,
               output_dir,
               [
                 {:mimetypes, :cow_mimetypes, :all},
                 {:dir_handler, :cowboy_static, {:dir, output_dir, [{:index_file, "index.html"}]}}
               ]
             }
           }
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
