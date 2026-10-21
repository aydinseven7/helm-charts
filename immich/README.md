# Immich — Helm chart stack

This folder contains all Helm charts needed to run a full [Immich](https://immich.app) deployment on Kubernetes.

## Charts

| Chart | Source | Purpose |
|-------|--------|---------|
| [`immich-server-helm-chart/`](immich-server-helm-chart/) | Custom | Immich server + optional ML sidecar, plus a bundled CloudNativePG `Cluster` (VectorChord + pgvector) and Valkey |
| [`immich-ml-helper-chart/`](immich-ml-helper-chart/) | Custom | Standalone ML pod (additive or standalone alternative to the built-in sidecar) |
| [`database-helm-chart/`](database-helm-chart/) | Custom (legacy) | Plain Immich-patched PostgreSQL Deployment, superseded by the bundled CNPG Cluster |

## Architecture

### Default setup (ML runs as a sidecar alongside the server)

```
  ┌──────────────────────────────────────────────┐
  │            immich-server-helm-chart          │
  │                                              │
  │  ┌─────────────────┐  ┌────────────┐         │
  │  │  Immich server  │  │ ML sidecar │         │
  │  │  (port 2283)    │  │ (port 3003)│         │
  │  └────────┬────────┘  └────────────┘         │
  │           ├──────────────────┐               │
  │           ▼                  ▼               │
  │  ┌────────────────────────┐ ┌─────────────┐  │
  │  │ CNPG Cluster (cnpg.*)  │ │   Valkey    │  │
  │  │ PostgreSQL 18          │ │ (valkey.*)  │  │
  │  │ + VectorChord/pgvector │ │ Service:    │  │
  │  │ Service: <cluster>-rw  │ │ <rel>-valkey│  │
  │  └────────────────────────┘ └─────────────┘  │
  └──────────────────────────────────────────────┘
```

### Extended setup (ML helper running alongside the sidecar, e.g. on a second cluster)

```
  cluster A (k3s)                         cluster B (Rancher Desktop / other)
  ┌───────────────────────────────┐        ┌─────────────────────────────┐
  │   immich-server-helm-chart    │        │   immich-ml-helper-chart     │
  │                               │        │                             │
  │  ┌──────────────┐ ┌────────┐  │        │   ML pod (port 3003)        │
  │  │ Immich server│ │ML side-│  │        │   exposed via domain/IP     │
  │  │              │ │  car   │  │──────▶ │                             │
  │  └──────┬───────┘ └────────┘  │  HTTP  └─────────────────────────────┘
  │         ▼                     │  (added as extra ML URL in Immich UI)
  │   CNPG Cluster + Valkey       │
  └───────────────────────────────┘
```

## Chart descriptions

### immich-server-helm-chart

The main Immich chart. Deploys the Immich API + web UI server, optionally a co-located Machine Learning pod, and the database.

**Immich server** handles photo/video uploads, the web UI, the REST API, and background jobs. It connects to PostgreSQL for metadata and to Valkey (Redis-compatible) for job queueing.

**Database** is a [CloudNativePG](https://cloudnative-pg.io) `Cluster` deployed through the cloudnative-pg [`cluster` chart](https://github.com/cloudnative-pg/charts/tree/main/charts/cluster), imported as a dependency under the `cnpg` key. It runs the [Immich-patched PostgreSQL image](https://github.com/immich-app/postgres), preloads VectorChord, creates the `vchord` and `earthdistance` extensions on bootstrap, and the server is wired to its `<cluster>-rw` Service and `<cluster>-app` credentials automatically. Set `cnpg.enabled: false` to use an external PostgreSQL instead.

**Valkey** is deployed through the official [valkey chart](https://github.com/valkey-io/valkey-helm) under the `valkey` key (no auth, no persistence by default) and wired into `REDIS_HOSTNAME`/`REDIS_PORT` automatically. Set `valkey.enabled: false` and `redisHost` to use an external Redis/Valkey instead.

**ML sidecar** (`machineLearning.enabled: true`, the default) deploys a second container in its own Deployment within the same chart release. It handles:
- CLIP smart search (text and image similarity)
- Facial recognition

When enabled, the ML pod is exposed as a ClusterIP Service named `<release>-ml-svc` on port 3003, and Immich is configured to reach it at that address. No additional chart is needed.

Set `machineLearning.enabled: false` if you want to run the ML workload on a separate node using the `immich-ml-helper-chart` instead (see below).

See [`immich-server-helm-chart/README.md`](immich-server-helm-chart/README.md) for the full parameter reference.

### immich-ml-helper-chart

A standalone deployment of the same Immich Machine Learning container. It can be used in two ways:

**As an addition to the sidecar** — keep `machineLearning.enabled: true` in `immich-server-helm-chart` and deploy this chart as an extra ML worker on a separate node or cluster (e.g. a Mac Mini running Rancher Desktop). Register its reachable domain in the Immich admin UI under *Machine Learning* so Immich can offload inference to it alongside the sidecar.

**As a full replacement for the sidecar** — set `machineLearning.enabled: false` in `immich-server-helm-chart`, deploy this chart on the target node, and point Immich at it via the admin UI. Useful when you want ML isolated on a dedicated machine or GPU node and do not want a co-located sidecar at all.

In both cases, the ML helper's Service is reachable at `http://<release>-svc:3003` within the same cluster, or via an externally reachable domain when deployed on a separate cluster.

If you do not need any of this, ignore this chart entirely — the sidecar in `immich-server-helm-chart` is sufficient.

See [`immich-ml-helper-chart/README.md`](immich-ml-helper-chart/README.md) for the full parameter reference.

### database-helm-chart (legacy)

Deploys a single-replica PostgreSQL 14 instance with pgvecto.rs + VectorChord as a plain Deployment. It is kept for existing installs; new installs should use the CNPG Cluster bundled in `immich-server-helm-chart`. To move an existing install over, import from this instance's Service with the cluster chart's recovery mode (`cnpg.mode: recovery`, `cnpg.recovery.method: import`), switch over, then remove this release.

See [`database-helm-chart/README.md`](database-helm-chart/README.md) for its parameter reference.

## Dependencies

```
immich-server-helm-chart
├── requires: CloudNativePG operator (cluster-wide, installed separately)
├── bundles:  CNPG Cluster (cloudnative-pg "cluster" chart, alias cnpg)
├── bundles:  Valkey (valkey chart)
└── ML service (port 3003)
                ├── sidecar (machineLearning.enabled=true)
                │     └── provided by: ML Deployment inside immich-server-helm-chart
                └── immich-ml-helper-chart (optional, independent release)
                      ├── can run alongside the sidecar as an extra ML worker
                      └── can replace the sidecar (machineLearning.enabled=false)
```

## Secrets setup

No database secret is needed: CNPG generates `<cluster>-app`. To set the password yourself, create a `kubernetes.io/basic-auth` secret and set `cnpg.cluster.initdb.secret.name` (see the chart README).

## Installation order

### Option A — default setup (ML sidecar)

```bash
# 1. Create namespace
kubectl create namespace immich

# 2. Install Immich (server + ML sidecar + CNPG Cluster + Valkey)
helm install immich ./immich-server-helm-chart --namespace immich
```

### Option B — ML helper as an additional worker (sidecar stays enabled)

```bash
# Steps 1–2 identical to option A, then:

# 3. Install ML helper on a second cluster / node (e.g. Rancher Desktop)
helm install immich-ml ./immich-ml-helper-chart --namespace immich

# 4. In the Immich admin UI, add the ML helper's reachable domain under
#    Administration > Machine Learning so Immich can offload inference to it.
```

### Option C — ML helper as a full replacement (sidecar disabled)

```bash
# Step 1 identical to option A, then:

# 2. Install Immich server with the ML sidecar disabled
helm install immich ./immich-server-helm-chart \
  --set machineLearning.enabled=false \
  --namespace immich

# 3. Install ML helper on the target node
helm install immich-ml ./immich-ml-helper-chart --namespace immich

# 4. In the Immich admin UI, set the Machine Learning URL to:
#    http://immich-ml-svc:3003
```

## Upgrading

```bash
helm upgrade immich    ./immich-server-helm-chart --namespace immich
# if using the split setup:
helm upgrade immich-ml ./immich-ml-helper-chart --namespace immich
```

## Uninstalling

```bash
helm uninstall immich    --namespace immich
helm uninstall immich-ml --namespace immich  # if installed
```

> **Note:** uninstalling `immich` also deletes its CNPG `Cluster`, and CNPG garbage-collects the Cluster's PVCs with it — the database is gone unless you have backups (`cnpg.backups`).

The app's PersistentVolumeClaims are not removed automatically:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=immich    --namespace immich
kubectl delete pvc -l app.kubernetes.io/instance=immich-ml --namespace immich
```
