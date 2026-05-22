# VibeKit Agent Guidelines

VibeKit is an Igniter installer for bootstrapping Elixir Vibe project conventions.

## Development

```sh
mix deps.get
mix ci
```

## Scope

- Keep the package focused on reusable project setup conventions.
- Prefer Igniter APIs over raw text edits.
- Keep installers idempotent and safe for existing projects.
- Do not publish, tag, or create the GitHub repository unless explicitly requested.
