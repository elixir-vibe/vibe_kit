defmodule VibeKitTest do
  use ExUnit.Case
  import Igniter.Test

  alias VibeKit.Install.Templates

  @flat_credo """
  %{
    configs: [
      %{
        name: "default",
        checks: []
      }
    ]
  }
  """

  @grouped_credo """
  %{
    configs: [
      %{
        name: "default",
        checks: %{
          enabled: [
            {Credo.Check.Design.AliasUsage, []},
            {Credo.Check.Warning.Dbg, []}
          ],
          disabled: [
            {Credo.Check.Design.TagTODO, []}
          ]
        }
      }
    ]
  }
  """

  test "installer adds strict CI conventions by default" do
    test_project()
    |> Igniter.compose_task("vibe_kit.install", [])
    |> assert_has_patch("mix.exs", """
    + |      deps: deps(),
    + |      dialyzer: [plt_add_apps: [:ex_unit]],
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
    + |      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
    + |      {:reach, "~> 2.8", only: [:dev, :test], runtime: false},
    + |      {:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false},
    + |      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    + |      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    """)
    |> assert_has_patch("mix.exs", """
    + |      ci: [
    + |        "compile --warnings-as-errors",
    + |        "format --check-formatted",
    + |        "test",
    + |        "credo --strict",
    + |        "dialyzer",
    + |        "ex_dna --max-clones 0",
    + |        "reach.check --arch --smells"
    + |      ]
    """)
    |> assert_creates(".credo.exs", Templates.credo_config())
    |> assert_creates(".reach.exs", "[]\n")
    |> refute_creates("AGENTS.md")
    |> refute_creates("CLAUDE.md")
  end

  test "installed tool requirements match the versions VibeKit is tested against" do
    project_deps = Mix.Project.config()[:deps]

    for {name, requirement} <- VibeKit.Install.tool_deps() do
      assert {^name, ^requirement, _opts} = List.keyfind(project_deps, name, 0)
    end
  end

  test "installer task keeps vibe_kit out of runtime deps" do
    info = Mix.Tasks.VibeKit.Install.info([], nil)

    assert info.only == [:dev, :test]
    assert info.dep_opts == [runtime: false]
  end

  test "installer adds ExSlop to existing credo config in place" do
    test_project(files: %{".credo.exs" => @flat_credo})
    |> Igniter.compose_task("vibe_kit.install", [])
    |> assert_content_equals(".credo.exs", """
    %{
      configs: [
        %{
          name: "default",
          checks: [
            {Credo.Check.Design.AliasUsage, false},
            {ExSlop.Check.Readability.NarratorDoc, false}
          ],
          plugins: [{ExSlop, []}]
        }
      ]
    }
    """)
  end

  test "installer adds ExSlop to grouped Credo checks" do
    test_project(files: %{".credo.exs" => @grouped_credo})
    |> Igniter.compose_task("vibe_kit.install", [])
    |> assert_has_patch(".credo.exs", """
      |      checks: %{
      |        enabled: [
    - |          {Credo.Check.Design.AliasUsage, []},
    - |          {Credo.Check.Warning.Dbg, []}
    + |          {Credo.Check.Warning.Dbg, []},
    + |          {ExSlop.Check.Warning.BlanketRescue, []},
    """)
    |> assert_has_patch(".credo.exs", """
      |        ],
      |        disabled: [
    - |          {Credo.Check.Design.TagTODO, []}
    + |          {Credo.Check.Design.TagTODO, []},
    + |          {Credo.Check.Design.AliasUsage, false},
    + |          {ExSlop.Check.Readability.NarratorDoc, false}
      |        ]
    - |      }
    + |      },
    + |      plugins: [{ExSlop, []}]
    """)
  end

  test "installer can add optional agent instruction files" do
    test_project()
    |> Igniter.compose_task("vibe_kit.install", ["--agents-md", "--claude-md"])
    |> assert_creates("AGENTS.md", Templates.agents_md())
    |> assert_creates("CLAUDE.md", Templates.agents_md())
  end

  test "installer appends VibeKit guidance to existing agent instructions" do
    test_project(files: %{"AGENTS.md" => "# Phoenix Guidelines\n\nUse mix precommit.\n"})
    |> Igniter.compose_task("vibe_kit.install", ["--agents-md"])
    |> assert_content_equals(
      "AGENTS.md",
      "# Phoenix Guidelines\n\nUse mix precommit.\n\n\n" <> Templates.agents_md()
    )
  end

  test "installer is idempotent" do
    argv = ["--agents-md", "--claude-md"]

    test_project(files: %{"AGENTS.md" => "# Phoenix Guidelines\n"})
    |> Igniter.compose_task("vibe_kit.install", argv)
    |> apply_igniter!()
    |> Igniter.compose_task("vibe_kit.install", argv)
    |> assert_unchanged()
  end

  test "installer is idempotent for grouped Credo checks" do
    test_project(files: %{".credo.exs" => @grouped_credo})
    |> Igniter.compose_task("vibe_kit.install", [])
    |> apply_igniter!()
    |> Igniter.compose_task("vibe_kit.install", [])
    |> assert_unchanged()
  end

  test "installer can disable strict optional checks" do
    test_project()
    |> Igniter.compose_task("vibe_kit.install", [
      "--no-reach",
      "--no-strict-clones",
      "--no-ex-slop"
    ])
    |> assert_has_patch("mix.exs", """
    + |      {:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false},
    + |      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
    + |      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    """)
    |> assert_has_patch("mix.exs", """
    + |        "dialyzer",
    + |        "ex_dna"
    + |      ]
    """)
    |> refute_creates(".credo.exs")
    |> refute_creates(".reach.exs")
    |> refute_creates("AGENTS.md")
    |> refute_creates("CLAUDE.md")
  end
end
