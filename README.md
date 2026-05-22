# VibeKit

Igniter installer for Elixir Vibe project conventions.

It patches new or existing Mix projects with the strict shared `mix ci` shape used across Elixir Vibe packages:

```elixir
ci: [
  "compile --warnings-as-errors",
  "format --check-formatted",
  "test",
  "credo --strict",
  "dialyzer",
  "ex_dna --max-clones 0",
  "reach.check --arch --smells"
]
```

It also adds `def cli, do: [preferred_envs: [ci: :test]]`, quality-tool dependencies, a baseline `.reach.exs`, and a `.credo.exs` that enables the ExSlop recommended plugin checks:

```elixir
%{
  configs: [
    %{
      name: "default",
      plugins: [{ExSlop, []}]
    }
  ]
}
```

Dependency versions are resolved through Igniter from the latest Hex releases at install time. The generated `.reach.exs` starts as `[]`; add project-specific layer and boundary policies as the project architecture settles.

## Usage

Create a new project with the conventions installed immediately:

```sh
mix igniter.new my_lib --install vibe_kit
```

For local development before the package is published:

```sh
mix igniter.new my_lib --install vibe_kit@path:/Users/dannote/Development/vibe_kit
```

Install into an existing project:

```sh
mix igniter.install vibe_kit
```

## Options

The strict defaults can be disabled when a project needs a lighter setup:

```sh
mix igniter.install vibe_kit --no-reach
mix igniter.install vibe_kit --no-strict-clones
mix igniter.install vibe_kit --no-ex-slop
```

Optionally add agent instruction files:

```sh
mix igniter.install vibe_kit --agents-md
mix igniter.install vibe_kit --claude-md
```

Options can be combined:

```sh
mix igniter.new my_lib \
  --install vibe_kit \
  --no-reach \
  --no-ex-slop \
  --agents-md
```

## Installation

Add the package to projects that should expose the installer task:

```elixir
def deps do
  [
    {:vibe_kit, "~> 0.1.0"}
  ]
end
```
