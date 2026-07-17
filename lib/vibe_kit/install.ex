defmodule VibeKit.Install do
  @moduledoc false

  alias Igniter.Code.Keyword, as: CodeKeyword
  alias Igniter.Code.List, as: CodeList
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
    |> put_test_plt_apps()
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
    if default_credo_config?(pairs),
      do: {:%{}, meta, patch_default_credo_config(pairs)},
      else: config
  end

  def put_ex_slop_plugin_ast(config), do: config

  defp default_credo_config?(pairs), do: Keyword.get(pairs, :name) == "default"

  defp patch_default_credo_config(pairs) do
    pairs
    |> upsert_ex_slop_plugins()
    |> upsert_relaxed_generated_checks()
  end

  defp upsert_ex_slop_plugins(pairs) do
    case Keyword.fetch(pairs, :plugins) do
      {:ok, plugins} ->
        put_keyword_if_changed(pairs, :plugins, plugins, prepend_ex_slop_plugin(plugins))

      :error ->
        pairs ++ [plugins: [ex_slop_plugin_ast()]]
    end
  end

  defp prepend_ex_slop_plugin(plugins) when is_list(plugins) do
    if Enum.any?(plugins, &ex_slop_plugin?/1), do: plugins, else: [ex_slop_plugin_ast() | plugins]
  end

  defp prepend_ex_slop_plugin(plugins), do: plugins

  defp ex_slop_plugin?(ast), do: Macro.to_string(ast) == "{ExSlop, []}"

  defp ex_slop_plugin_ast, do: {:{}, [], [{:__aliases__, [alias: false], [:ExSlop]}, []]}

  defp upsert_relaxed_generated_checks(pairs) do
    checks = Keyword.get(pairs, :checks, [])

    updated_checks =
      case checks do
        {:%{}, meta, check_groups} -> {:%{}, meta, relax_grouped_checks(check_groups)}
        checks when is_list(checks) -> append_missing_relaxed_checks(checks)
        _other -> checks
      end

    put_keyword_if_changed(pairs, :checks, checks, updated_checks)
  end

  defp relax_grouped_checks(check_groups) do
    relaxed_names = MapSet.new(relaxed_generated_checks(), &check_name/1)
    original_enabled = Keyword.get(check_groups, :enabled, [])
    original_disabled = Keyword.get(check_groups, :disabled, [])

    enabled =
      original_enabled
      |> reject_checks(relaxed_names)
      |> append_missing_ex_slop_checks()

    disabled = append_missing_relaxed_checks(original_disabled)

    check_groups
    |> put_keyword_if_changed(:enabled, original_enabled, enabled)
    |> put_keyword_if_changed(:disabled, original_disabled, disabled)
  end

  defp put_keyword_if_changed(keyword, _key, value, value), do: keyword

  defp put_keyword_if_changed(keyword, key, _current, updated),
    do: Keyword.put(keyword, key, updated)

  defp reject_checks(checks, names) do
    Enum.reject(checks, &MapSet.member?(names, check_name(&1)))
  end

  defp append_missing_relaxed_checks(checks) do
    append_missing_checks(checks, relaxed_generated_checks())
  end

  defp append_missing_ex_slop_checks(checks) do
    relaxed_names = MapSet.new(relaxed_generated_checks(), &check_name/1)

    desired =
      ExSlop.recommended_checks()
      |> Enum.map(fn module -> {Code.string_to_quoted!(inspect(module)), []} end)
      |> Enum.reject(&MapSet.member?(relaxed_names, check_name(&1)))

    append_missing_checks(checks, desired)
  end

  defp append_missing_checks(checks, desired) do
    existing_names = MapSet.new(checks, &check_name/1)
    missing = Enum.reject(desired, &MapSet.member?(existing_names, check_name(&1)))

    checks ++ missing
  end

  defp check_name({:{}, _meta, [module | _rest]}), do: Macro.to_string(module)
  defp check_name({module, _opts}), do: Macro.to_string(module)
  defp check_name(check), do: Macro.to_string(check)

  defp relaxed_generated_checks do
    [
      {{:__aliases__, [alias: false], [:Credo, :Check, :Design, :AliasUsage]}, false},
      {{:__aliases__, [alias: false], [:ExSlop, :Check, :Readability, :NarratorDoc]}, false}
    ]
  end

  defp put_preferred_ci_env(igniter) do
    MixProject.update(igniter, :cli, [:preferred_envs], fn
      nil ->
        {:ok, {:code, [ci: :test]}}

      zipper ->
        CodeKeyword.set_keyword_key(zipper, :ci, quote(do: :test), nil)
    end)
  end

  defp put_test_plt_apps(igniter) do
    MixProject.update(igniter, :project, [:dialyzer, :plt_add_apps], fn
      nil ->
        {:ok, {:code, [:ex_unit]}}

      zipper ->
        if literal_list_member?(zipper.node, :ex_unit) do
          {:ok, zipper}
        else
          CodeList.append_to_list(zipper, :ex_unit)
        end
    end)
  end

  defp literal_list_member?({:__block__, _meta, [value]}, item),
    do: literal_list_member?(value, item)

  defp literal_list_member?(values, item) when is_list(values) do
    Enum.any?(values, fn
      {:__block__, _meta, [value]} -> value == item
      value -> value == item
    end)
  end

  defp literal_list_member?(_value, _item), do: false
end
