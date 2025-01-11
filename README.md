# Genex

Genex is a modern static site generator built with Elixir that combines the power of Phoenix's templating with the simplicity of static site generation.

## Key Features

- **HEEx Templating**: Use Phoenix's powerful HEEx templates for dynamic content generation with static output
- **Markdown Support**: Write content in Markdown with front matter for metadata
- **Dynamic Routing**: Support for dynamic routes with parameters (e.g., `[date.year]/[date.month]/[slug]`)
- **Collection System**: Organize content into collections with automatic tag management
- **Flexible Layouts**: Multiple layout support with chainable layouts and opt-out options
- **Built-in Components**: Use Phoenix components for reusable UI elements
- **Asset Pipeline**: Integrated Tailwind CSS support for modern styling
- **Development Server**: Live preview with hot-reload capabilities
- **Cross-Platform**: Available for macOS, Linux, and Windows through binary releases

## Quick Start

```bash
# Install from binary release
# TODO: Add installation instructions

# Create a new site
genex new my-site

# Start development server
genex serve

# Build for production
genex build
```

## Project Structure

```
my-site/
├── assets/          # Static assets (CSS, JS, images)
├── content/         # Your content files (Markdown, data)
├── pages/          # Page templates and layouts
├── components/     # Reusable UI components
├── models/         # Content models and schemas
├── helpers/        # Helper functions
└── .output/        # Generated static site
```

## Configuration

Configure your site in `.genex/config.exs`:

```elixir
import Config

# Site configuration
config :genex, :site,
  title: "Genex",
  description: "Genex is a static site generator for Phoenix."

# Build configuration
config :genex, :build,
  assets_folder: "assets",
  content_folder: "content",
  pages_folder: "pages",
  output_folder: ".output",
  models_folder: "models",
  helpers_folder: "helpers",
  components_folder: "components",
  use_index_file: true

# Hooks configuration
config :genex, :hooks,
  folder: "hooks",
  pre: ["pre.exs"],
  post: ["post.exs"]

# Watch configuration
config :genex, :watch,
  port: 4000,
  ignored_files: ["assets/css/output.css"]

```

## Why Genex?

- **Elixir Ecosystem**: Leverage the power and reliability of Elixir and Phoenix
- **Type-Safe Templates**: HEEx provides compile-time template checking
- **Flexible Content Structure**: Support for both simple pages and complex content hierarchies
- **Developer Experience**: Fast builds, hot reloading, and familiar Phoenix-like development experience
- **Modern Defaults**: Built with modern web development practices in mind

## License

MIT License
