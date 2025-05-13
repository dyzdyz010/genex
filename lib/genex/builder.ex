defmodule Genex.Builder do
  require Logger
  alias Genex.Builder.Render.Page
  alias Genex.Builder.Content
  alias Genex.Builder.Route
  alias Genex.Builder.Scanner
  alias Genex.Builder.Utils.Paths

  def build() do
    start_time = System.monotonic_time(:millisecond)
    context = %Genex.Builder.Context{start_time: start_time}
    context
  end

  @spec initialize(Genex.Builder.Context.t()) :: :ok
  @doc """
  Initialize the context
  """
  def initialize(context) do
    IO.puts("#{IO.ANSI.blue()}[1/10] Initializing context...")
    clean_output_folder()
  end

  def build() do
    IO.puts("#{IO.ANSI.yellow()}Start building site...")
    # Logger.debug("Project root: #{Utils.project_root()}")
    clean_output_folder()
    Genex.Hook.run_pre_hooks()
    models_map = Genex.Builder.Model.prepare()
    Logger.debug("Models map: #{inspect(models_map, pretty: true)}")

    unrendered_models = Scanner.scan_content(Paths.content_path(), models_map)

    rendered_models =
      unrendered_models
      |> Enum.map(fn model -> Genex.Builder.Utils.Content.render_model(model) end)

    global_assigns = Genex.Builder.Assign.make_global_assigns(rendered_models)
    templates = Scanner.scan_templates()

    routes = make_routes(templates, rendered_models, global_assigns)

    {global_assigns, routes} = Content.update_links(global_assigns, routes)
    # Logger.debug("Routes: #{inspect(routes, pretty: true)}")
    routes = resolve_single_item(routes)

    layouts = build_layouts()

    render_routes(routes, global_assigns, layouts)

    Genex.Hook.run_post_hooks()
    copy_assets()

    IO.puts("#{IO.ANSI.green()}Build site finished")
  end

  @doc """
  Clean the output folder
  """
  def clean_output_folder() do
    IO.puts("#{IO.ANSI.green()}Start cleaning site...")
    output_folder = Paths.output_path()
    Logger.debug("Output folder: #{output_folder}")

    if File.exists?(output_folder) do
      # Empty the output folder
      for file <- File.ls!(output_folder) do
        File.rm_rf!(Path.join(output_folder, file))
      end
    end

    File.mkdir_p!(output_folder)
  end

  defp make_routes(templates, full_content, global_assigns) do
    routes =
      templates
      |> Enum.map(fn template ->
        Route.routes_for_template(template, full_content, global_assigns)
      end)
      |> List.flatten()

    # Logger.debug("Routes: #{inspect(routes, pretty: true)}")

    routes
  end

  def resolve_single_item(routes) do
    routes
    |> Enum.map(fn route ->
      assigns = route.assigns

      unless assigns == nil do
        specific_assigns =
          if Path.basename(route.template_path) == "[slug].html.heex" do
            %{data: %{item: assigns.data.items |> List.first()}, params: assigns.params}
          else
            %{
              data: %{items: assigns.data.items, fields: assigns.data.fields},
              params: assigns.params
            }
          end

        route |> Map.delete(:assigns) |> Map.put(:assigns, specific_assigns)
      else
        route
      end
    end)
  end

  defp build_layouts() do
    Logger.debug("Start building layouts...")
    Genex.Builder.Render.Layout.generate_layout_chains()
  end

  defp copy_assets() do
    output_path = Paths.output_path()
    assets_folder = Application.get_env(:genex, :build)[:assets_folder]

    unless assets_folder == nil do
      assets_path = Path.join([output_path, assets_folder])
      Logger.debug("Assets path: #{assets_path}")
      File.mkdir_p!(assets_path)
      File.cp_r!(Paths.assets_path(), assets_path)
    end
  end

  defp render_routes(routes, global_assigns, layout_chains) do
    Genex.Builder.Render.View.gen_view_module()

    routes
    |> Enum.each(fn x ->
      assigns = x.assigns

      Page.render_template(
        x |> Map.put(:assigns, assigns |> Map.merge(global_assigns)),
        layout_chains
      )
    end)
  end
end
