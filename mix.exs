defmodule VibeKit.MixProject do
  use Mix.Project

  @version "0.1.5"
  @source_url "https://github.com/elixir-vibe/vibe_kit"

  def project do
    [
      app: :vibe_kit,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: "Igniter installer for Elixir Vibe project conventions",
      aliases: aliases(),
      elixirc_options: [
        no_warn_undefined: [
          {ExAST.Patcher, :replace_all, 3},
          {ExAST.Pattern, :match, 2},
          {Igniter, :create_or_update_file, 4},
          {Igniter.Code.Keyword, :set_keyword_key, 4},
          {Igniter.Code.List, :append_to_list, 2},
          {Igniter.Project.Deps, :add_dep, 3},
          {Igniter.Project.Deps, :determine_dep_type_and_version!, 1},
          {Igniter.Project.MixProject, :update, 4},
          {Igniter.Project.TaskAliases, :add_alias, 4},
          {Rewrite.Source, :update, 3}
        ]
      ],
      dialyzer: [
        plt_file: {:no_warn, "_build/dev/dialyxir_plt.plt"},
        plt_add_apps: [:mix]
      ],
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  def cli do
    [preferred_envs: [ci: :test]]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp aliases do
    [
      ci: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "test",
        "credo --strict",
        "dialyzer",
        "ex_dna --max-clones 0",
        "reach.check --arch --smells"
      ]
    ]
  end

  defp deps do
    [
      {:igniter, "~> 0.7", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
      {:reach, "~> 2.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
