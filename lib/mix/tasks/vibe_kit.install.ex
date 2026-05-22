Code.ensure_compiled(Igniter)

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.VibeKit.Install do
    use Igniter.Mix.Task

    alias Igniter.Code.Keyword, as: CodeKeyword
    alias Igniter.Project.{Deps, MixProject, TaskAliases}

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

    * `--reach` - add Reach and include `reach.check --arch --smells` in CI
    * `--strict-clones` - run ExDNA as `ex_dna --max-clones 0`
    * `--ex-slop` - add ExSlop as a dev/test dependency
    """

    @impl Igniter.Mix.Task
    def info(argv, _parent) do
      %Igniter.Mix.Task.Info{
        group: :vibe_kit,
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
      |> TaskAliases.add_alias(:ci, ci_steps(options), if_exists: :warn)
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
        Deps.add_dep(igniter, dep, on_exists: :skip)
      end)
    end

    defp deps_for_options(options) do
      [
        latest_dep("credo"),
        latest_dep("dialyxir"),
        latest_dep("ex_dna")
      ]
      |> maybe_add(options[:reach], latest_dep("reach"))
      |> maybe_add(options[:ex_slop], latest_dep("ex_slop"))
    end

    defp parse_options(argv) do
      {options, _, _} =
        OptionParser.parse(argv,
          strict: [reach: :boolean, strict_clones: :boolean, ex_slop: :boolean]
        )

      options
    end

    defp latest_dep(package) do
      package
      |> Deps.determine_dep_type_and_version!()
      |> add_dev_test_opts()
    end

    defp add_dev_test_opts({name, version}) when is_binary(version) do
      {name, version, only: [:dev, :test], runtime: false}
    end

    defp add_dev_test_opts({name, version, opts}) when is_binary(version) do
      {name, version, Keyword.merge(opts, only: [:dev, :test], runtime: false)}
    end

    defp add_dev_test_opts({name, opts}) when is_list(opts) do
      {name, Keyword.merge(opts, only: [:dev, :test], runtime: false)}
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
      MixProject.update(igniter, :cli, [:preferred_envs], fn
        nil ->
          {:ok, {:code, [ci: :test]}}

        zipper ->
          CodeKeyword.set_keyword_key(zipper, :ci, quote(do: :test), nil)
      end)
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
