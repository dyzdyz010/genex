import Config

# 特定路径的布局配置
config :genex, :meta,
  title: "Genex",
  description: "Genex is a static site generator for Phoenix."

config :genex, :build,
  default_layout: "default",
  content_folder: "posts",
  pages_folder: "pages",
  output_folder: ".output"
