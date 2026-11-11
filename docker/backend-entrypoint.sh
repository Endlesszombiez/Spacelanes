#!/bin/sh
set -eu
umask 077

if [ -z "$(printf '%s' "${MANAGEMENT_PASSWORD:-}" | tr -d '[:space:]')" ]; then
  echo 'Set a nonempty MANAGEMENT_PASSWORD on the backend container.' >&2
  exit 1
fi

mkdir -p /data/auths /data/plugins
if [ ! -f /data/config.yaml ]; then
  client_key="$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')"
  sed "s/__GENERATED_CLIENT_KEY__/$client_key/" /etc/spacelanes/config.example.yaml \
    > /data/config.yaml.tmp
  mv /data/config.yaml.tmp /data/config.yaml
fi

exec /usr/local/bin/spacelanes-backend --config /data/config.yaml "$@"
