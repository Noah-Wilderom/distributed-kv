# distributed-kv

A distributed key-value store written in **Elixir** (`app: kvx`), with support for local development, testing, formatting checks, and Dockerized production-style runs.

## Tech Stack

- **Language:** Elixir (`~> 1.15`)
- **Build tool:** Mix
- **Task runner:** Taskfile (`Taskfile.yaml`)
- **Containerization:** Docker
- **Runtime app name:** `kvx`

## Repository Structure

- `lib/` — application source code
- `config/` — configuration files
- `test/` — automated tests
- `mix.exs` — project definition and application config
- `Taskfile.yaml` — common development/CI tasks
- `Dockerfile` — multi-stage image build for production release

## Prerequisites

### Local development

- Elixir `~> 1.15`
- Erlang/OTP compatible with your Elixir version

### Optional tooling

- [Task](https://taskfile.dev/) (to use predefined tasks)
- Docker (for container build/run)

## Getting Started (Local)

Install dependencies:

```bash
mix deps.get
```

Run tests:

```bash
mix test --cover --trace
```

Check formatting:

```bash
mix format --check-formatted
```

Fix formatting:

```bash
mix format
```

## Using Taskfile Commands

If you have `task` installed, you can run:

```bash
task test
task format:check
task format:fix
task docker:build
task docker:run
```

## Docker

This project includes a multi-stage Docker build:

1. **Builder image** (`elixir:1.20`)
   - installs Hex/Rebar
   - fetches deps
   - builds a Mix release
2. **Runtime image** (`elixir:1.20-slim`)
   - copies the release from builder
   - installs `openssl`
   - exposes port `4000`
   - starts with `bin/kvx start`

Build image:

```bash
docker build -t distributed-kv . --no-cache
```

Run container:

```bash
docker run -p 4000:4000 distributed-kv
```

## Production Release

The Docker release command builds and runs the OTP release for `kvx`:

```bash
bin/kvx start
```

Use this as the base for deployment workflows in container platforms.

## Development Notes

- The app starts through `Kvx.Application` (see `mix.exs` application config).
- Currently, no external Mix dependencies are declared (`deps: []`), keeping the project minimal and lightweight.
- Add your architecture details (clustering, replication, consistency model, API protocol) here as the implementation evolves.

## License

No license is currently specified in this repository.
Consider adding a `LICENSE` file if you plan to share or distribute this project.
