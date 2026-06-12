defmodule VibeKit.Install do
  @moduledoc false

  alias Igniter.Code.Keyword, as: CodeKeyword
  alias Igniter.Project.{Deps, MixProject, TaskAliases}
  alias Rewrite.Source
  alias VibeKit.Install.{Options, Templates}

  def deps(argv) do
    argv
    |> Options.parse()
    |> deps_for_options()
  end

  def run(igniter, options) do
    options = Options.normalize(options)

    igniter
    |> add_dependencies(options)
    |> put_preferred_ci_env()
    |> TaskAliases.add_alias(:ci, ci_steps(options), if_exists: :warn)
    |> configure_ex_slop(options)
    |> configure_reach(options)
    |> configure_agent_docs(options)
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
    maybe_create_or_update(
      igniter,
      options[:ex_slop],
      ".credo.exs",
      Templates.credo_config(),
      fn source ->
        Source.update(source, :content, &patch_credo_config/1)
      end
    )
  end

  defp configure_reach(igniter, options) do
    maybe_create_or_update(
      igniter,
      options[:reach],
      ".reach.exs",
      Templates.reach_config(),
      fn source ->
        source
      end
    )
  end

  defp configure_agent_docs(igniter, options) do
    igniter
    |> maybe_create_or_update(
      options[:agents_md],
      "AGENTS.md",
      Templates.agents_md(),
      fn source ->
        Source.update(source, :content, &merge_agents_md/1)
      end
    )
    |> maybe_create_or_update(
      options[:claude_md],
      "CLAUDE.md",
      Templates.claude_md(),
      fn source ->
        Source.update(source, :content, &merge_agents_md/1)
      end
    )
  end

  defp maybe_create_or_update(igniter, true, path, content, updater) do
    Igniter.create_or_update_file(igniter, path, content, updater)
  end

  defp maybe_create_or_update(igniter, _enabled, _path, _content, _updater), do: igniter

  defp merge_agents_md(content) do
    marker = "## VibeKit quality gate"

    if String.contains?(content, marker) do
      content
    else
      content <> "\n\n" <> Templates.agents_md()
    end
  end

  defp patch_credo_config(content) do
    content
    |> Code.string_to_quoted!()
    |> patch_credo_ast()
    |> Macro.to_string()
    |> Kernel.<>("\n")
  end

  defp patch_credo_ast(ast) do
    case ExAST.Pattern.match(ast, quote(do: %{configs: configs})) do
      {:ok, %{configs: configs}} ->
        ExAST.Patcher.replace_all(
          ast,
          quote(do: %{configs: configs}),
          {:%{}, [], [configs: Enum.map(configs, &put_ex_slop_plugin_ast/1)]}
        )

      :error ->
        Code.string_to_quoted!(Templates.credo_config())
    end
  end

  def put_ex_slop_plugin_ast({:%{}, meta, pairs} = config) do
    if default_credo_config?(pairs), do: {:%{}, meta, upsert_ex_slop_plugins(pairs)}, else: config
  end

  def put_ex_slop_plugin_ast(config), do: config

  defp default_credo_config?(pairs), do: Keyword.get(pairs, :name) == "default"

  defp upsert_ex_slop_plugins(pairs) do
    case Keyword.fetch(pairs, :plugins) do
      {:ok, plugins} -> Keyword.put(pairs, :plugins, prepend_ex_slop_plugin(plugins))
      :error -> pairs ++ [plugins: [ex_slop_plugin_ast()]]
    end
  end

  defp prepend_ex_slop_plugin(plugins) when is_list(plugins) do
    if Enum.any?(plugins, &ex_slop_plugin?/1), do: plugins, else: [ex_slop_plugin_ast() | plugins]
  end

  defp prepend_ex_slop_plugin(plugins), do: plugins

  defp ex_slop_plugin?(ast), do: Macro.to_string(ast) == "{ExSlop, []}"

  defp ex_slop_plugin_ast, do: {:{}, [], [{:__aliases__, [alias: false], [:ExSlop]}, []]}

  defp put_preferred_ci_env(igniter) do
    MixProject.update(igniter, :cli, [:preferred_envs], fn
      nil ->
        {:ok, {:code, [ci: :test]}}

      zipper ->
        CodeKeyword.set_keyword_key(zipper, :ci, quote(do: :test), nil)
    end)
  end
end
