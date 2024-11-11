FROM ghcr.io/gleam-lang/gleam:v1.5.1-elixir-alpine

# Install mising dependencies from alpine image
RUN apk add --no-cache build-base bsd-compat-headers
RUN mix local.hex --force

COPY . /build/

RUN cd /build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build

WORKDIR /app

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["run"]