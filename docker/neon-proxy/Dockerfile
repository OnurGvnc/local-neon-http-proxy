ARG NEON_RELEASE_TAG=release-9129

FROM rust:bookworm AS rust-builder
ARG NEON_RELEASE_TAG

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]


# get and build the proxy
RUN git clone --depth=1 --branch $NEON_RELEASE_TAG https://github.com/neondatabase/neon.git
WORKDIR /neon
RUN cargo build --bin proxy --release --features "testing"


FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# install apt dependencies
RUN \
  apt-get update -qq \
  && apt-get install -qq --no-install-recommends -o DPkg::Options::=--force-confold -o DPkg::Options::=--force-confdef \
  curl \
  postgresql-client \
  && apt-get clean -qq && rm -rf /var/lib/apt/lists/*

WORKDIR /app


COPY --from=rust-builder /neon/target/release/proxy ./neon-proxy
COPY ./start.sh start.sh

RUN chmod +x start.sh

EXPOSE 4444
ENTRYPOINT ["./start.sh"]
