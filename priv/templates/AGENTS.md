# VibeKit quality gate

## Development

```sh
mix deps.get
mix ci
```

## Conventions

- Use `mix ci` for the full validation suite before finishing changes.
- For Phoenix/web apps, keep Phoenix's generated guidance, but treat this VibeKit section as the final quality gate.
- For non-web Elixir projects, VibeKit is the default project baseline.
- Treat active rules in `.reach.exs` as project architecture policy. Change them only when the module boundaries intentionally change.
- Keep changes small, tested, and formatted.
