#!/usr/bin/env bash
set -euo pipefail

# Exercise the actual Portainer stack with locally built images and a fresh volume.
export MANAGEMENT_PASSWORD
MANAGEMENT_PASSWORD="$(openssl rand -base64 32)"
if [ "${GITHUB_ACTIONS:-}" = true ]; then
  echo "::add-mask::$MANAGEMENT_PASSWORD"
fi
export SPACELANES_PORT=18080
smoke_dir="$(mktemp -d)"
cat > "$smoke_dir/override.yaml" <<'YAML'
services:
  backend:
    image: spacelanes-backend:smoke
    pull_policy: never
    command: ["--local-model"]
  spacelanes:
    image: spacelanes-proxy:smoke
    pull_policy: never
YAML
compose=(docker compose --project-name spacelanes-smoke \
  --file compose.portainer.yaml --file "$smoke_dir/override.yaml")
cleanup() {
  "${compose[@]}" logs --no-color
  "${compose[@]}" down --volumes --remove-orphans
  rm -rf "$smoke_dir"
}
trap cleanup EXIT

# A missing password must fail startup instead of leaving login routes disabled.
if docker run --rm spacelanes-backend:smoke; then
  echo 'Backend unexpectedly started without MANAGEMENT_PASSWORD' >&2
  exit 1
fi

"${compose[@]}" up --detach --wait --wait-timeout 120
base=http://127.0.0.1:18080
curl --fail --silent --show-error "$base/" > "$smoke_dir/index.html"
grep -q '<title>Spacelanes Proxy</title>' "$smoke_dir/index.html"
grep -q '<div id="root">' "$smoke_dir/index.html"
curl --fail --silent --show-error "$base/management.html" > "$smoke_dir/management.html"
cmp "$smoke_dir/index.html" "$smoke_dir/management.html"
curl --fail --silent --show-error "$base/healthz"
for service in backend spacelanes; do
  test "$("${compose[@]}" exec -T "$service" id -u)" -ne 0
done

# Management authentication and proxy-client authentication are independent.
test "$(curl --silent --output /dev/null --write-out '%{http_code}' \
  "$base/v8/management/config")" = 401
test "$(curl --silent --output /dev/null --write-out '%{http_code}' \
  --header 'Authorization: Bearer incorrect-test-password' "$base/v8/management/config")" = 401
curl --fail --silent --show-error --header "Authorization: Bearer $MANAGEMENT_PASSWORD" \
  "$base/v8/management/config" > "$smoke_dir/config.json"
python3 - "$smoke_dir/config.json" <<'PY'
import json, sys
config = json.load(open(sys.argv[1]))
assert config['server']['port'] == 8317
assert config['oauth']['auth-dir'] == '/data/auths'
assert config['management']['disable-control-panel'] is True
keys = config['access']['api-keys']
assert len(keys) == 1 and len(keys[0]) == 64
assert keys[0] != '__GENERATED_CLIENT_KEY__'
PY
client_key="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["access"]["api-keys"][0])' "$smoke_dir/config.json")"
if [ "${GITHUB_ACTIONS:-}" = true ]; then
  echo "::add-mask::$client_key"
fi
test "$(curl --silent --output /dev/null --write-out '%{http_code}' "$base/v1/models")" = 401
curl --fail --silent --show-error --header "Authorization: Bearer $client_key" \
  "$base/v1/models" > /dev/null

# A v8 write and auth files must survive replacing the backend container.
curl --fail --silent --show-error --request PUT \
  --header "Authorization: Bearer $MANAGEMENT_PASSWORD" --header 'Content-Type: application/json' \
  --data '123' "$base/v8/management/config/observability/logs/logs-max-total-size-mb" > /dev/null
"${compose[@]}" exec -T backend sh -c 'printf persistent > /data/auths/smoke-marker'
"${compose[@]}" up --detach --force-recreate --wait --wait-timeout 120 backend
curl --fail --silent --show-error --retry 15 --retry-delay 1 --retry-all-errors \
  --header "Authorization: Bearer $MANAGEMENT_PASSWORD" \
  "$base/v8/management/config" > "$smoke_dir/recreated.json"
python3 - "$smoke_dir/config.json" "$smoke_dir/recreated.json" <<'PY'
import json, sys
before, after = (json.load(open(path)) for path in sys.argv[1:])
assert after['observability']['logs']['logs-max-total-size-mb'] == 123
assert after['access']['api-keys'] == before['access']['api-keys']
PY
test "$("${compose[@]}" exec -T backend cat /data/auths/smoke-marker)" = persistent
echo 'UI, v8 login, client authentication, non-root users, and persistence passed.'
