Code.ensure_compiled(Igniter)

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.VibeSetup.Install do
    use Igniter.Mix.Task

    @example "mix igniter.install vibe_setup"
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

    * `--reach` - add Reach and include `reach.check --arch --smells` in CI
    * `--strict-clones` - run ExDNA as `ex_dna --max-clones 0`
    * `--ex-slop` - add ExSlop as a dev/test dependency
    """

    @impl Igniter.Mix.Task
    def info(argv, _parent) do
      %Igniter.Mix.Task.Info{
        group: :vibe_setup,
        adds_deps: deps(argv),
        installs: [],
        example: @example,
        positional: [],
        schema: [
          reach: :boolean,
          strict_clones: :boolean,
          ex_slop: :boolean
        ],
        defaults: [
          reach: false,
          strict_clones: false,
          ex_slop: false
        ],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      options = igniter.args.options

      igniter
      |> add_dependencies(options)
      |> put_preferred_ci_env()
      |> Igniter.Project.TaskAliases.add_alias(:ci, ci_steps(options), if_exists: :warn)
    end

    defp deps(argv) do
      argv
      |> parse_options()
      |> deps_for_options()
    end

    defp add_dependencies(igniter, options) do
      options
      |> deps_for_options()
      |> Enum.reduce(igniter, fn dep, igniter ->
        Igniter.Project.Deps.add_dep(igniter, dep, on_exists: :skip)
      end)
    end

    defp deps_for_options(options) do
      [
        {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
        {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
        {:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false}
      ]
      |> maybe_add(options[:reach], {:reach, "~> 2.6", only: [:dev, :test], runtime: false})
      |> maybe_add(options[:ex_slop], {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false})
    end

    defp parse_options(argv) do
      {options, _, _} =
        OptionParser.parse(argv,
          strict: [reach: :boolean, strict_clones: :boolean, ex_slop: :boolean]
        )

      options
    end

    defp maybe_add(deps, true, dep), do: deps ++ [dep]
    defp maybe_add(deps, _, _dep), do: deps

    defp ci_steps(options) do
      [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "test",
        "credo --strict",
        "dialyzer",
        if(options[:strict_clones], do: "ex_dna --max-clones 0", else: "ex_dna"),
        if(options[:reach], do: "reach.check --arch --smells")
      ]
      |> Enum.reject(&is_nil/1)
    end

    defp put_preferred_ci_env(igniter) do
      Igniter.Project.MixProject.update(igniter, :cli, [:preferred_envs], fn
        nil ->
          {:ok, {:code, [ci: :test]}}

        zipper ->
          Igniter.Code.Keyword.set_keyword_key(zipper, :ci, quote(do: :test), nil)
      end)
    end
  end
else
  defmodule Mix.Tasks.VibeSetup.Install do
    @moduledoc "Installs Elixir Vibe project conventions"
    @shortdoc @moduledoc

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'vibe_setup.install' requires igniter.

      Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter
      """)

      exit({:shutdown, 1})
    end
  end
end
