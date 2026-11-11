# Compile the static UI on the builder architecture for every runtime platform.
FROM --platform=$BUILDPLATFORM oven/bun:1.4.3 AS bun

FROM --platform=$BUILDPLATFORM node:24-bookworm-slim AS build

COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY index.html tsconfig.json tsconfig.node.json vite.config.ts ./
COPY src ./src

ARG VERSION=dev
RUN VERSION="${VERSION}" bun run build

FROM nginxinc/nginx-unprivileged:stable-alpine AS runtime

COPY --from=build /app/dist/index.html /usr/share/nginx/html/index.html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --spider http://127.0.0.1:8080/ || exit 1
