defmodule VibeKitTest do
  use ExUnit.Case
  import Igniter.Test

  test "installer adds base CI conventions" do
    mix_exs =
      test_project()
      |> Igniter.compose_task("vibe_kit.install", [])
      |> apply_igniter!()
      |> file_content("mix.exs")

    assert mix_exs =~ "aliases: aliases()"
    assert mix_exs =~ "def cli do"
    assert mix_exs =~ "preferred_envs: [ci: :test]"
    assert mix_exs =~ ~r/{:credo, "~> \d+\.\d+", only: \[:dev, :test\], runtime: false}/
    assert mix_exs =~ ~r/{:dialyxir, "~> \d+\.\d+", only: \[:dev, :test\], runtime: false}/
    assert mix_exs =~ ~r/{:ex_dna, "~> \d+\.\d+", only: \[:dev, :test\], runtime: false}/
    assert mix_exs =~ "compile --warnings-as-errors"
    assert mix_exs =~ "format --check-formatted"
    assert mix_exs =~ "test"
    assert mix_exs =~ "credo --strict"
    assert mix_exs =~ "dialyzer"
    assert mix_exs =~ "ex_dna"
  end

  test "installer can add Reach and strict clone checks" do
    mix_exs =
      test_project()
      |> Igniter.compose_task("vibe_kit.install", ["--reach", "--strict-clones"])
      |> apply_igniter!()
      |> file_content("mix.exs")

    assert mix_exs =~ ~r/{:reach, "~> \d+\.\d+", only: \[:dev, :test\], runtime: false}/
    assert mix_exs =~ "ex_dna --max-clones 0"
    assert mix_exs =~ "reach.check --arch --smells"
  end

  defp file_content(igniter, path) do
    igniter.rewrite
    |> Rewrite.source!(path)
    |> Rewrite.Source.get(:content)
  end
end
