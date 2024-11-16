FROM ghcr.io/gleam-lang/gleam:v1.5.1-elixir-alpine

# Install mising dependencies from alpine image
RUN apk add --no-cache build-base \
                       bsd-compat-headers \
                       openssl \
                       ca-certificates
# Install hex
RUN mix local.hex --force 

# For linux/amd64 compatibility
ENV ERL_FLAGS="+JMsingle true"

COPY . /build/

RUN cd /build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build

WORKDIR /app

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["run"]