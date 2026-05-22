# VibeKit

Igniter installer for Elixir Vibe project conventions.

It patches new or existing Mix projects with the shared `mix ci` shape used across Elixir Vibe packages:

```elixir
ci: [
  "compile --warnings-as-errors",
  "format --check-formatted",
  "test",
  "credo --strict",
  "dialyzer",
  "ex_dna"
]
```

It also adds `def cli, do: [preferred_envs: [ci: :test]]` and the required quality-tool dependencies.

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

Add Reach architecture checks:

```sh
mix igniter.install vibe_kit --reach
```

Use strict clone detection:

```sh
mix igniter.install vibe_kit --strict-clones
```

Add ExSlop as a dev/test dependency:

```sh
mix igniter.install vibe_kit --ex-slop
```

Options can be combined:

```sh
mix igniter.new my_lib \
  --install vibe_kit \
  --reach \
  --strict-clones
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
