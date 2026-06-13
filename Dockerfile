FROM elixir:1.20 AS builder

ENV MIX_ENV=prod

WORKDIR /app

COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix release

FROM elixir:1.20-slim

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/kvx ./

RUN apt-get update && \
    apt-get install -y openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 4000

CMD ["bin/kvx", "start"]
