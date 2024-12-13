defmodule Genex.Cli.Command do
  @callback name() :: String.t()
  @callback description() :: String.t()
  @callback help() :: String.t()
  @callback run(opts :: keyword(), args :: list(String.t())) :: any()
end
