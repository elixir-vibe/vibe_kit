defmodule VibeSetup.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/elixir-vibe/vibe_setup"

  def project do
    [
      app: :vibe_setup,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: "Igniter installer for Elixir Vibe project conventions",
      aliases: aliases(),
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
        "test"
      ]
    ]
  end

  defp deps do
    [
      {:igniter, "~> 0.7", optional: true},
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
