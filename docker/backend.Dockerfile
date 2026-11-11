# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.26.10-bookworm AS build
ARG TARGETARCH
WORKDIR /src
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc-aarch64-linux-gnu gcc-x86-64-linux-gnu \
    libc6-dev-arm64-cross libc6-dev-amd64-cross git \
    && rm -rf /var/lib/apt/lists/*
COPY backend/go.mod backend/go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY backend/ ./
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    go test ./internal/auth/antigravity && \
    case "$TARGETARCH" in \
      amd64) export CC=x86_64-linux-gnu-gcc ;; \
      arm64) export CC=aarch64-linux-gnu-gcc ;; \
      *) echo "Unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    VERSION=$(sed -n 's/.*"version": "\([^"]*\)".*/\1/p' UPSTREAM.json) && \
    COMMIT=$(sed -n 's/.*"commit": "\([^"]*\)".*/\1/p' UPSTREAM.json) && \
    CGO_ENABLED=1 GOOS=linux GOARCH=$TARGETARCH go build -buildvcs=false \
      -ldflags="-s -w -X main.Version=$VERSION -X main.Commit=$COMMIT" \
      -o /out/spacelanes-backend ./cmd/server

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tzdata libstdc++6 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 spacelanes \
    && useradd --uid 10001 --gid 10001 --home-dir /data --no-create-home spacelanes \
    && install -d -o 10001 -g 10001 /data /data/auths /data/plugins
COPY --from=build /out/spacelanes-backend /usr/local/bin/spacelanes-backend
COPY backend/LICENSE /usr/share/doc/spacelanes-backend/LICENSE
COPY backend/UPSTREAM.json /usr/share/doc/spacelanes-backend/UPSTREAM.json
COPY docker/backend-config.yaml /etc/spacelanes/config.example.yaml
COPY docker/backend-entrypoint.sh /usr/local/bin/spacelanes-entrypoint
# Source files retain the repository's CRLF convention; Linux executes LF scripts.
RUN sed -i 's/\r$//' /usr/local/bin/spacelanes-entrypoint \
    && chmod 755 /usr/local/bin/spacelanes-entrypoint
ENV HOME=/data WRITABLE_PATH=/data
WORKDIR /data
USER 10001:10001
VOLUME ["/data"]
EXPOSE 8317
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD curl --fail --silent http://127.0.0.1:8317/healthz > /dev/null || exit 1
ENTRYPOINT ["/usr/local/bin/spacelanes-entrypoint"]
