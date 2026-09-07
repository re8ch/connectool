# ConnecTool

ConnecTool is a provider-neutral control contract for distributing AI tools
through OIDC, ToolHive MCP workloads, and Codex-compatible plugin marketplaces.
It turns the full chain into reviewable, values-controlled Kubernetes resources
without embedding one organization's endpoints, policies, identities, or registry.

## Install

```sh
helm install connectool \
  oci://ghcr.io/re8ch/charts/connectool \
  --version 0.4.0 \
  --namespace connectool \
  --create-namespace \
  --values my-values.yaml
```

Start with [`charts/connectool/examples/example-values.yaml`](charts/connectool/examples/example-values.yaml).

## What it standardizes

- public PKCE client contracts for an OIDC provider;
- ToolHive Registry sources and optional registry-server release settings;
- MCP groups, OIDC configuration, virtual MCP aggregation, and authorization;
- Codex marketplace metadata, MCP ownership, and reusable skill-only plugins;
- an optional Git publisher for generated marketplace, plugin, MCP, and Skill files;
- validation that each publication has exactly one MCP-owning plugin.

ConnecTool stores no OAuth tokens or identity-provider secrets and installs no
desktop plugins. The publisher reads credentials from a pre-existing Kubernetes
Secret and completely regenerates managed plugin directories from the values
contract, preventing stale Skill and manifest combinations. See
[the architecture boundary](docs/architecture.md).
