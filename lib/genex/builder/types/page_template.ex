defmodule Genex.Builder.Types.PageTemplate do
  defstruct [
    # 文件在文件系统中的绝对路径
    :abs_path,
    # 相对于 pages/ 的相对路径，比如 "posts/[year]/[month]/[day]/[slug].heex"
    :rel_path,
    # [:year, :month, :day, :slug]  这个模板需要哪些占位符
    :params_schema,
    # 是否是 index.heex
    :is_index?,
    # 模板类型（slug, 列表或固定页面)
    :type
  ]

  @type t() :: %__MODULE__{
          abs_path: String.t(),
          rel_path: String.t(),
          params_schema: [atom()],
          is_index?: boolean(),
          # 只区分是否是详情页
          type: :slug | :static
        }
end
