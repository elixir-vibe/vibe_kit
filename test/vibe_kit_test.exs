defmodule VibeKitTest do
  use ExUnit.Case
  import Igniter.Test

  test "installer adds strict CI conventions by default" do
    igniter =
      test_project()
      |> Igniter.compose_task("vibe_kit.install", [])

    mix_exs = file_content(igniter, "mix.exs")
    credo_exs = file_content(igniter, ".credo.exs")
    reach_exs = file_content(igniter, ".reach.exs")

    assert mix_exs =~ "aliases: aliases()"
    assert mix_exs =~ "def cli do"
    assert mix_exs =~ "preferred_envs: [ci: :test]"
    assert mix_exs =~ ~r/{:credo, "~> \d+\.\d+", only: \[:dev, :test\], runtime: false}/
    assert mix_exs =~ ~r/{:dialyxir, "~> \d+\.\d+", only: \[:dev, :test\], runtime: false}/
    assert mix_exs =~ ~r/{:ex_dna, "~> \d+\.\d+", only: \[:dev, :test\], runtime: false}/
    assert mix_exs =~ ~r/{:ex_slop, "~> \d+\.\d+", only: \[:dev, :test\], runtime: false}/
    assert mix_exs =~ ~r/{:reach, "~> \d+\.\d+", only: \[:dev, :test\], runtime: false}/
    assert mix_exs =~ "compile --warnings-as-errors"
    assert mix_exs =~ "format --check-formatted"
    assert mix_exs =~ "test"
    assert mix_exs =~ "credo --strict"
    assert mix_exs =~ "dialyzer"
    assert mix_exs =~ "ex_dna --max-clones 0"
    assert mix_exs =~ "reach.check --arch --smells"
    assert credo_exs =~ "plugins: [{ExSlop, []}]"
    assert reach_exs == "[]\n"
  end

  test "installer can add optional agent instruction files" do
    igniter =
      test_project()
      |> Igniter.compose_task("vibe_kit.install", ["--agents-md", "--claude-md"])

    agents_md = file_content(igniter, "AGENTS.md")
    claude_md = file_content(igniter, "CLAUDE.md")

    assert agents_md =~ "# Agent Guidelines"
    assert agents_md =~ "mix ci"
    assert claude_md =~ "# CLAUDE.md"
    assert claude_md =~ "AGENTS.md"
  end

  test "installer can disable strict optional checks" do
    igniter =
      test_project()
      |> Igniter.compose_task("vibe_kit.install", [
        "--no-reach",
        "--no-strict-clones",
        "--no-ex-slop"
      ])

    mix_exs = file_content(igniter, "mix.exs")

    refute mix_exs =~ ":reach"
    refute mix_exs =~ ":ex_slop"
    refute mix_exs =~ "ex_dna --max-clones 0"
    refute mix_exs =~ "reach.check --arch --smells"
    assert mix_exs =~ "ex_dna"
    refute has_file?(igniter, ".credo.exs")
    refute has_file?(igniter, ".reach.exs")
    refute has_file?(igniter, "AGENTS.md")
    refute has_file?(igniter, "CLAUDE.md")
  end

  defp file_content(igniter, path) do
    igniter.rewrite
    |> Rewrite.source!(path)
    |> Rewrite.Source.get(:content)
  end

  defp has_file?(igniter, path) do
    case Rewrite.source(igniter.rewrite, path) do
      {:ok, _source} -> true
      _ -> false
    end
  end
end
