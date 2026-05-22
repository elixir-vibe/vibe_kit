# VibeKit

VibeKit bootstraps a strict, ready-to-run quality setup for Elixir projects.

It is an [Igniter](https://hex.pm/packages/igniter) installer that adds a `mix ci` alias, quality-tool dependencies, and baseline config files for Credo, Dialyzer, ExDNA, ExSlop, and Reach.

VibeKit comes from the [Elixir Vibe](https://github.com/elixir-vibe) ecosystem: a set of Elixir-native tools for AI-assisted coding, AST-aware code intelligence, architecture checks, duplicate detection, and generated-code quality. The tools are useful independently; VibeKit wires the quality-focused ones into new or existing projects with one command.

## Quick start

Install VibeKit into an existing Mix project:

```sh
mix igniter.install vibe_kit
```

Or create a new project with VibeKit applied immediately:

```sh
mix igniter.new my_lib --install vibe_kit
```

After installation, run the full check suite with:

```sh
mix ci
```

## What gets added

By default, VibeKit adds this `mix ci` pipeline:

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

It also adds:

- `def cli, do: [preferred_envs: [ci: :test]]`
- latest Hex versions of the quality-tool dependencies
- `.credo.exs` with ExSlop's recommended plugin checks enabled
- `.reach.exs` as a starting point for Reach architecture policy

The generated `.reach.exs` starts as:

```elixir
[]
```

Add project-specific layer, boundary, source, and call policies as the architecture settles.

## Included tools

| Tool | What VibeKit uses it for |
| --- | --- |
| [Credo](https://hex.pm/packages/credo) | General static analysis and style checks |
| [Dialyxir](https://hex.pm/packages/dialyxir) | Dialyzer integration for success typing |
| [ExDNA](https://hex.pm/packages/ex_dna) | AST-aware duplicate-code detection with a zero-clone default |
| [ExSlop](https://hex.pm/packages/ex_slop) | Credo plugin checks for common low-quality generated-code patterns |
| [Reach](https://hex.pm/packages/reach) | Architecture policy and cross-function smell checks |

Other Elixir Vibe packages include [ExAST](https://hex.pm/packages/ex_ast) for AST-aware search/replace and [ProgramFacts](https://hex.pm/packages/program_facts) for analyzer fixtures.

## Options

The strict defaults can be disabled for projects that need a lighter setup:

```sh
mix igniter.install vibe_kit --no-reach
mix igniter.install vibe_kit --no-strict-clones
mix igniter.install vibe_kit --no-ex-slop
```

Optional agent instruction files can be generated too:

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

## Generated ExSlop config

VibeKit enables ExSlop through Credo's plugin mechanism:

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

This enables ExSlop's recommended high-signal checks automatically.

## Keeping the installer available

`mix igniter.install vibe_kit` adds the project conventions and does not require VibeKit to remain as a runtime dependency. If a project should keep the installer task available, add VibeKit explicitly:

```elixir
def deps do
  [
    {:vibe_kit, "~> 0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```
