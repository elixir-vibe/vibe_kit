# Agent Guidelines

## Development

```sh
mix deps.get
mix ci
```

## Project conventions

- Use the project Mix aliases; prefer `mix ci` for the full validation suite.
- Keep changes small, tested, and formatted.
- Prefer Igniter APIs for repeatable project setup changes.
- Do not publish, tag, or create releases unless explicitly requested.
