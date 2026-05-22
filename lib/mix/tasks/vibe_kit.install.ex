Code.ensure_compiled(Igniter)

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.VibeKit.Install do
    use Igniter.Mix.Task

    alias Igniter.Code.Keyword, as: CodeKeyword
    alias Igniter.Project.{Deps, MixProject, TaskAliases}
    alias Rewrite.Source

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
        defaults: default_options(),
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      options = Keyword.merge(default_options(), igniter.args.options)

      igniter
      |> add_dependencies(options)
      |> put_preferred_ci_env()
      |> TaskAliases.add_alias(:ci, ci_steps(options), if_exists: :warn)
      |> configure_ex_slop(options)
      |> configure_reach(options)
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
      |> maybe_add_latest(options[:reach], "reach")
      |> maybe_add_latest(options[:ex_slop], "ex_slop")
    end

    defp default_options do
      [reach: true, strict_clones: true, ex_slop: true]
    end

    defp parse_options(argv) do
      {options, _, _} =
        OptionParser.parse(argv,
          strict: [reach: :boolean, strict_clones: :boolean, ex_slop: :boolean]
        )

      Keyword.merge(default_options(), options)
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

    defp maybe_add_latest(deps, true, package), do: deps ++ [latest_dep(package)]
    defp maybe_add_latest(deps, _, _package), do: deps

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

    defp configure_ex_slop(igniter, options) do
      if options[:ex_slop] do
        Igniter.create_or_update_file(igniter, ".credo.exs", credo_config(), fn source ->
          Source.update(source, :content, &patch_credo_config/1)
        end)
      else
        igniter
      end
    end

    defp configure_reach(igniter, options) do
      if options[:reach] do
        Igniter.create_or_update_file(igniter, ".reach.exs", reach_config(), fn source ->
          source
        end)
      else
        igniter
      end
    end

    defp patch_credo_config(content) do
      cond do
        String.contains?(content, "ExSlop") ->
          content

        String.contains?(content, "plugins: [") ->
          String.replace(content, "plugins: [", "plugins: [{ExSlop, []}, ", global: false)

        true ->
          content <> "\n" <> credo_config()
      end
    end

    defp credo_config do
      """
      %{
        configs: [
          %{
            name: "default",
            plugins: [{ExSlop, []}]
          }
        ]
      }
      """
    end

    defp reach_config do
      "[]\n"
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
