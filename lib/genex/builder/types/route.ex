defmodule Genex.Builder.Types.Route do
  @moduledoc """
  A route is a template that will be rendered to a file in the output folder.
  """

  @type t :: %__MODULE__{
    template_path: String.t(),
    output_path: String.t(),
    params: map(),
    assigns: map(),
    schema: [atom()]
  }

  defstruct [
    :template_path,
    :output_path,
    :params,
    :assigns,
    :schema
  ]
end
