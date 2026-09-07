#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
chart="$repo_root/charts/connectool"
values="$chart/examples/example-values.yaml"
work="$(mktemp -d)"
mkdir -p "$work/contract" "$work/seed/plugins/platform-tool/skills/stale"

helm template connectool "$chart" --values "$values" \
  --set codex.marketplace.publisher.enabled=true \
  --set codex.marketplace.publisher.repository=https://github.com/example/codex-plugins.git \
  --set codex.marketplace.publisher.image=example.invalid/publisher@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
  --set codex.marketplace.publisher.secretRef.name=publisher-credentials \
  >"$work/rendered.yaml"

ruby -ryaml -e '
  docs = YAML.load_stream(File.read(ARGV[0]))
  contract = docs.find { |d| d.is_a?(Hash) && d["kind"] == "ConfigMap" && d.dig("metadata", "name") == "connectool-codex-plugins" }
  publisher = docs.find { |d| d.is_a?(Hash) && d["kind"] == "ConfigMap" && d.dig("metadata", "name") == "connectool-marketplace-publisher" }
  contract["data"].each { |name, content| File.write(File.join(ARGV[1], name), content) }
  File.write(ARGV[2], publisher.dig("data", "publish.sh"))
' "$work/rendered.yaml" "$work/contract" "$work/publish.sh"
sed "s#/contract#$work/contract#g" "$work/publish.sh" >"$work/publish-local.sh"

printf stale >"$work/seed/plugins/platform-tool/skills/stale/STALE"
git -C "$work/seed" init -q -b main
git -C "$work/seed" config user.name test
git -C "$work/seed" config user.email test@example.com
git -C "$work/seed" add .
git -C "$work/seed" commit -qm seed
git init -q --bare "$work/remote.git"
git -C "$work/seed" remote add origin "$work/remote.git"
git -C "$work/seed" push -q -u origin main

export GIT_REPOSITORY="$work/remote.git"
export GIT_BRANCH=main
export GIT_AUTHOR_NAME=test
export GIT_AUTHOR_EMAIL=test@example.com
export GIT_USERNAME=test
export GIT_TOKEN=test

sh "$work/publish-local.sh" >/dev/null
sh "$work/publish-local.sh" | grep -q 'Marketplace is already current'

git clone -q "$work/remote.git" "$work/check"
test -s "$work/check/plugins/platform-tool/skills/platform/SKILL.md"
test ! -e "$work/check/plugins/platform-tool/skills/stale/STALE"
test -s "$work/check/plugins/platform-tool/.contract.sha256"

printf '\ncontract change without version change\n' >>"$work/contract/platform-tool.skill.0.md"
if sh "$work/publish-local.sh" >"$work/version-guard.log" 2>&1; then
  echo 'publisher accepted a changed contract without a version bump' >&2
  exit 1
fi
grep -q 'contract changed without a version bump' "$work/version-guard.log"

GIT_REPOSITORY="$work/missing/remote.git"
export GIT_REPOSITORY
if sh "$work/publish-local.sh" >"$work/unreachable.log" 2>&1; then
  echo 'publisher treated an unreachable repository as an empty repository' >&2
  exit 1
fi
grep -q 'cannot reach marketplace repository' "$work/unreachable.log"

echo 'Publisher integration tests passed'
