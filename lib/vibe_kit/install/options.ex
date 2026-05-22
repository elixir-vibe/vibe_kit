defmodule VibeKit.Install.Options do
  @moduledoc false

  @schema [
    reach: :boolean,
    strict_clones: :boolean,
    ex_slop: :boolean,
    agents_md: :boolean,
    claude_md: :boolean
  ]

  @defaults [reach: true, strict_clones: true, ex_slop: true, agents_md: false, claude_md: false]

  def schema, do: @schema
  def defaults, do: @defaults

  def parse(argv) do
    {options, _, _} = OptionParser.parse(argv, strict: @schema)
    normalize(options)
  end

  def normalize(options), do: Keyword.merge(@defaults, options)
end
