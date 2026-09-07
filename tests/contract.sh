#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
chart="$repo_root/charts/connectool"
values="$chart/examples/example-values.yaml"
rendered="$(mktemp)"
trap 'rm -f "$rendered"' EXIT

helm lint "$chart" --values "$values"
helm template connectool "$chart" --values "$values" >"$rendered"

grep -q 'platform-tool.skill.0.md:' "$rendered"
grep -q $'platform-tool\tplatform-tool.skill.0.md\tskills/platform/SKILL.md' "$rendered"
grep -q '"authentication": "ON_INSTALL"' "$rendered"
grep -q '"clientId":"platform-tools"' "$rendered"
grep -q 'version":"1.0.0"' "$rendered"

helm template connectool "$chart" --values "$values" \
  --set codex.marketplace.publisher.enabled=true \
  --set codex.marketplace.publisher.repository=https://github.com/example/codex-plugins.git \
  --set codex.marketplace.publisher.image=example.invalid/publisher@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
  --set codex.marketplace.publisher.secretRef.name=publisher-credentials \
  >"$rendered"
grep -q 'rm -rf "$repository/plugins/$plugin"' "$rendered"
grep -q 'jq -e --arg plugin' "$rendered"
grep -q 'git -C "$repository" diff --cached --check' "$rendered"
grep -q 'test "$remote_head" = "$(git -C "$repository" rev-parse HEAD)"' "$rendered"
grep -q 'contract changed without a version bump' "$rendered"

echo "ConnecTool contract tests passed"
