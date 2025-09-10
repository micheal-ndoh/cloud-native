# Build stage
ARG RUST_BASE=registry.local:5000/rust:1.85
ARG RUNTIME_BASE=registry.local:5000/debian:bookworm-slim
FROM ${RUST_BASE} AS builder

WORKDIR /app

# Prepare for offline build with vendored crates
COPY Cargo.toml Cargo.lock ./
COPY .cargo/. ./.cargo/
COPY vendor ./vendor
RUN mkdir -p src \
    && echo "fn main() {}" > src/main.rs \
    && cargo build --release --offline || true

# Copy full sources and assets
COPY src ./src
COPY migrations ./migrations
COPY static ./static

# Build the application
RUN cargo build --release --offline \
    && strip target/release/task-api || true


# Runtime stage
FROM ${RUNTIME_BASE} AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -s /bin/bash appuser

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/target/release/task-api ./task-api
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/static ./static

# Change ownership
RUN chown -R appuser:appuser /app
USER appuser

# Metadata Labels
LABEL org.opencontainers.image.title="Task API"
LABEL org.opencontainers.image.description="A Rust backend API with Swagger docs, Keycloak auth, and logging support"
LABEL org.opencontainers.image.version="v2.0.0"
LABEL org.opencontainers.image.authors="micheal-ndoh <michealndoh@gmail.com>"
LABEL org.opencontainers.image.source="https://github.com/micheal-ndoh/cloud-native.git"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.revision="Added Keycloak authentication and logging"
LABEL org.opencontainers.image.created="2025-09-03"

EXPOSE 3000

# Start the app (migrations run at startup)
CMD ["./task-api"]