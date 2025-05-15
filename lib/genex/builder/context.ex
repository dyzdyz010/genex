defmodule Genex.Builder.Context do
  alias Genex.Builder.Types.Route
  alias Genex.Model
  alias Genex.Builder.Scanner
  alias Genex.Builder.Types.PageTemplate

  @type t :: %__MODULE__{
    project_root: binary(),
    config: map(),
    models_map: Scanner.model_map(),
    content_items: [Model.t()],
    rendered_content: [Model.t()],
    templates: [PageTemplate.t()],
    layouts: [binary()],
    routes: [Route.t()],
    global_assigns: map(),
  }

  defstruct [
    :project_root,
    :config,
    :models_map,
    :content_items,
    :rendered_content,
    :templates,
    :layouts,
    :routes,
    :global_assigns,
    :output_dir,
    start_time: nil,
    warnings: [],
    errors: []
  ]
end
