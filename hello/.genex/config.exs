import Config

# 特定路径的布局配置
config :genex, :site,
  title: "Genex",
  description: "A static site generator for Elixir."

config :genex, :build,
  assets_folder: "assets",
  content_folder: "content",
  pages_folder: "pages",
  output_folder: ".output",
  models_folder: "models",
  helpers_folder: "helpers",
  components_folder: "components",
  use_index_file: false

config :genex, :hooks,
  folder: "hooks",
  pre: ["pre.exs"],
  post: ["post.exs"]
