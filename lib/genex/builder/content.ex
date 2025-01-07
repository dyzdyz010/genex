defmodule Genex.Builder.Content do
  require Logger

  def update_links(global_assigns, routes) do
    # Logger.debug("Routes: #{inspect(routes, pretty: true)}")

    links_by_slug =
      routes
      |> Enum.filter(fn x -> x.template_path |> String.ends_with?("[slug].html.heex") end)
      |> Enum.reduce(%{}, fn x, acc ->
        output_path = x.output_path
        assigns = x.assigns

        items =
          cond do
            Map.has_key?(assigns, :data) and Map.has_key?(assigns.data, :item) ->
              [assigns.data.item]

            Map.has_key?(assigns, :data) and Map.has_key?(assigns.data, :items) ->
              assigns.data.items

            true ->
              []
          end

        Enum.reduce(items, acc, fn item, acc_inner ->
          Map.put(acc_inner, item.slug, output_path)
        end)
      end)

    Logger.warning("Links by slug: #{inspect(links_by_slug, pretty: true)}")

    # 更新global_assigns中的content
    updated_content =
      Enum.map(global_assigns.content, fn {folder, folder_content} ->
        items = folder_content.items

        updated_items =
          update_content_with_links(items, links_by_slug)

        {folder, Map.put(folder_content, :items, updated_items)}
      end)
      |> Enum.into(%{})

    global_assigns = Map.put(global_assigns, :content, updated_content)

    routes =
      routes
      |> Enum.map(fn route ->
        unless route.assigns.data.items == [] do
          assigns = route.assigns
          # Logger.debug("Assigns: #{inspect(assigns, pretty: true)}")

          items = assigns.data.items |> update_content_with_links(links_by_slug)

          assigns_data = assigns.data |> Map.put(:items, items)

          route
          |> Map.put(:assigns, assigns |> Map.put(:data, assigns_data))
        else
          route
        end
      end)

    {global_assigns, routes}
  end

  def update_content_with_links(items, links_by_slug) do
    items
    |> Enum.map(fn item ->
      case Map.get(links_by_slug, item.slug) do
        nil -> item
        link -> Map.put(item, :link, link)
      end
    end)
  end
end
