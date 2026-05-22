defmodule VibeKitTest do
  use ExUnit.Case
  import Igniter.Test

  test "installer adds base CI conventions" do
    test_project()
    |> Igniter.compose_task("vibe_kit.install", [])
    |> assert_has_patch("mix.exs", """
    + |      aliases: aliases()
    """)
    |> assert_has_patch("mix.exs", """
    + |  def cli do
    + |    [
    + |      preferred_envs: [ci: :test]
    + |    ]
    + |  end
    """)
    |> assert_has_patch("mix.exs", """
    + |      {:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false},
    + |      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    + |      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    """)
    |> assert_has_patch("mix.exs", """
    + |  defp aliases() do
    + |    [
    + |      ci: [
    + |        "compile --warnings-as-errors",
    + |        "format --check-formatted",
    + |        "test",
    + |        "credo --strict",
    + |        "dialyzer",
    + |        "ex_dna"
    + |      ]
    + |    ]
    + |  end
    """)
  end

  test "installer can add Reach and strict clone checks" do
    test_project()
    |> Igniter.compose_task("vibe_kit.install", ["--reach", "--strict-clones"])
    |> assert_has_patch("mix.exs", """
    + |      {:reach, "~> 2.6", only: [:dev, :test], runtime: false},
    """)
    |> assert_has_patch("mix.exs", """
    + |  defp aliases() do
    + |    [
    + |      ci: [
    + |        "compile --warnings-as-errors",
    + |        "format --check-formatted",
    + |        "test",
    + |        "credo --strict",
    + |        "dialyzer",
    + |        "ex_dna --max-clones 0",
    + |        "reach.check --arch --smells"
    + |      ]
    + |    ]
    + |  end
    """)
  end
end
