defmodule VibeKit.Install.Templates do
  @moduledoc false

  def credo_config, do: read_template("credo.exs")
  def reach_config, do: read_template("reach.exs")
  def agents_md, do: read_template("AGENTS.md")
  def claude_md, do: agents_md()

  defp read_template(name) do
    :vibe_kit
    |> Application.app_dir(Path.join("priv/templates", name))
    |> File.read!()
  end
end
