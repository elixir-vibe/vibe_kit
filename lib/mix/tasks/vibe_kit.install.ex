Code.ensure_compiled(Igniter)

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.VibeKit.Install do
    use Igniter.Mix.Task

    alias VibeKit.Install
    alias VibeKit.Install.Options

    @example "mix igniter.install vibe_kit"
    @shortdoc "Installs Elixir Vibe project conventions"

    @moduledoc """
    #{@shortdoc}

    Adds the shared `mix ci` alias, preferred Mix CLI environment, and quality
    tooling dependencies used across Elixir Vibe projects.

    ## Example

    ```sh
    #{@example}
    ```

    ## Options

    * `--no-reach` - skip Reach and `reach.check --arch --smells`
    * `--no-strict-clones` - run ExDNA as `ex_dna` instead of `ex_dna --max-clones 0`
    * `--no-ex-slop` - skip ExSlop and `.credo.exs` plugin setup
    * `--agents-md` - create `AGENTS.md` with project instructions
    * `--claude-md` - create `CLAUDE.md` with project instructions
    """

    @impl Igniter.Mix.Task
    def info(argv, _parent) do
      %Igniter.Mix.Task.Info{
        group: :vibe_kit,
        adds_deps: Install.deps(argv),
        installs: [],
        example: @example,
        positional: [],
        schema: Options.schema(),
        defaults: Options.defaults(),
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      Install.run(igniter, igniter.args.options)
    end
  end
else
  defmodule Mix.Tasks.VibeKit.Install do
    @moduledoc "Installs Elixir Vibe project conventions"
    @shortdoc @moduledoc

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'vibe_kit.install' requires igniter.

      Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter
      """)

      exit({:shutdown, 1})
    end
  end
end
