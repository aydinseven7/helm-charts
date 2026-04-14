# helm-charts
Public version of some Helm Charts used in my Homelab, where charts were not available. \
Yes, there are some issues such as using Deployments instead of StatefulSets for databases, maybe I'll get to that at a later time

## Charts

### [Dawarich](dawarich/)
Self-hosted location history tracker. Includes a custom chart for the Dawarich Rails app (+ Sidekiq worker) and a custom PostGIS chart, plus a values override for the Bitnami Redis chart.

| Chart | Description |
|-------|-------------|
| [`dawarich/dawarich-helm-chart`](dawarich/dawarich-helm-chart/) | Dawarich server + Sidekiq background worker |
| [`dawarich/postgis-helm-chart`](dawarich/postgis-helm-chart/) | PostgreSQL 17 with PostGIS 3.5 |
| [`dawarich/redis-values.yaml`](dawarich/redis-values.yaml) | Values override for Bitnami Redis |

### [Immich](immich/)
Self-hosted photo and video management. Includes a custom chart for the Immich server (with optional ML sidecar), a custom chart for the Immich-patched PostgreSQL database, and a standalone ML helper chart for offloading inference to a separate node.

| Chart | Description |
|-------|-------------|
| [`immich/immich-server-helm-chart`](immich/immich-server-helm-chart/) | Immich server + optional ML sidecar |
| [`immich/database-helm-chart`](immich/database-helm-chart/) | PostgreSQL 14 with pgvecto.rs + VectorChord |
| [`immich/immich-ml-helper-chart`](immich/immich-ml-helper-chart/) | Standalone ML pod for separate node/cluster deployments |

## Usage

All charts are packaged and published to the GitHub Container Registry as OCI artifacts. No Helm repo add step is needed — install directly with `helm install`:

```bash
helm install <release-name> oci://ghcr.io/aydinseven7/helm-charts/<chart-name> --namespace <namespace>
```

### Available packages

| Chart | OCI reference |
|-------|---------------|
| `dawarich` | `oci://ghcr.io/aydinseven7/helm-charts/dawarich` |
| `postgis` | `oci://ghcr.io/aydinseven7/helm-charts/postgis` |
| `immich` | `oci://ghcr.io/aydinseven7/helm-charts/immich` |
| `immich-database` | `oci://ghcr.io/aydinseven7/helm-charts/immich-database` |
| `immich-ml-helper` | `oci://ghcr.io/aydinseven7/helm-charts/immich-ml-helper` |

To pin a specific version, append `--version <chart-version>`:

```bash
helm install dawarich oci://ghcr.io/aydinseven7/helm-charts/dawarich \
  --version 0.1.0 \
  --namespace dawarich
```

To inspect a chart before installing:

```bash
helm show values oci://ghcr.io/aydinseven7/helm-charts/dawarich
helm show readme  oci://ghcr.io/aydinseven7/helm-charts/dawarich
```

## AI Disclaimer

Parts of this repository were assisted by AI (Claude/Github Copilot). The heaviest use was in sanitizing the charts and their documentation — removing personal details, standardizing comments, and writing the READMEs. AI was also used during the initial creation of some charts, though to a lesser extent, with the actual logic and structure largely written by hand.
