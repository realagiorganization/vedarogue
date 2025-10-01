FROM rust:1-bullseye AS builder
RUN apt-get update -y && apt-get install -y --no-install-recommends make ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# Cache deps
COPY Cargo.toml Cargo.lock* ./
RUN mkdir src && echo "fn main(){}" > src/main.rs && cargo build --release || true

# Build actual app
COPY src ./src
RUN cargo build --release

FROM debian:bullseye-slim
RUN apt-get update -y && apt-get install -y --no-install-recommends make bash ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/make-runner /usr/local/bin/make-runner
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/make-runner"]
CMD ["list"]

