IO.puts("========== Post hooks")

defmodule Genex.Hooks.Post do
  def greet do
    IO.puts("Hello from post hooks")
  end
end

Genex.Hooks.Post.greet()

# Use Tailwind to build css

alias Genex.Builder.Render.Utils

assets_folder = Utils.assets_path()

# command =
#   "tailwindcss -i #{Path.join([assets_folder, "css", "app.css"])} -o #{Path.join([assets_folder, "css", "output.css"])}"

# IO.puts("Running command: #{command}")

System.cmd("tailwindcss", [
  "-c",
  Path.join([assets_folder, "tailwind.config.js"]),
  "-i",
  Path.join([assets_folder, "css", "app.css"]),
  "-o",
  Path.join([assets_folder, "css", "output.css"])
])
