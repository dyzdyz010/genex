defmodule Genex.Model do
  require Logger

  defmodule Field do
    defstruct name: nil, type: nil
    @type t() :: %__MODULE__{name: String.t(), type: :string | :date | :list}
  end

  defmacro __using__(name: name, folder: folder, fields: fields) do
    quote do
      defstruct(unquote(fields) ++ [:year, :month, :day, :slug])
      def name, do: unquote(name)
      def folder, do: unquote(folder)
      def fields, do: unquote(fields)

      def model_from_map(map) do
        IO.inspect(unquote(fields), label: "fields")

        result = struct(__MODULE__, map)

        # 从field_map中获取slug映射字段，然后处理字符串
        slug_field = Map.get(field_map(), :slug)

        final_slug =
          final_slug =
          case Map.get(map, :slug) do
            nil -> slug_from_name(name())
            user_slug -> user_slug
          end

        result = result |> Map.put(:slug, final_slug)
        # 如果有date字段，则解析date字段
        new_result =
          if :date in unquote(fields) do
            # Logger.debug("Date: #{inspect(map.date, pretty: true)}")
            parsed_date = Date.from_iso8601!(map.date)

            result =
              result
              |> Map.put(:date, parsed_date)
              |> Map.put(:year, parsed_date.year)
              |> Map.put(:month, parsed_date.month)
              |> Map.put(:day, parsed_date.day)

            result
          else
            result
          end

        new_result
      end

      def slug(%__MODULE__{} = model) do
        slug_field = Map.get(field_map(), :slug)
        Map.get(model, slug_field) |> slug_from_name()
      end

      def slug_from_name(nil), do: nil

      def slug_from_name(name) do
        name |> String.downcase() |> String.replace(" ", "-")
      end
    end
  end

  @callback field_map() :: map()
end
