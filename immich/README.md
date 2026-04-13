# Immich — Helm chart stack

This folder contains all Helm charts needed to run a full [Immich](https://immich.app) deployment on Kubernetes.

## Charts

| Chart | Source | Purpose |
|-------|--------|---------|
| [`database-helm-chart/`](database-helm-chart/) | Custom | Immich-patched PostgreSQL with pgvecto.rs + VectorChord |
| [`immich-server-helm-chart/`](immich-server-helm-chart/) | Custom | Immich server + optional ML sidecar |
| [`immich-ml-helper-chart/`](immich-ml-helper-chart/) | Custom | Standalone ML pod (additive or standalone alternative to the built-in sidecar) |

Redis is not included here — install the Bitnami Redis chart separately.

## Architecture

### Default setup (ML runs as a sidecar alongside the server)

```
                    ┌──────────────────────────────────────┐
                    │        immich-server-helm-chart       │
                    │                                      │
                    │  ┌─────────────────┐  ┌───────────┐  │
                    │  │  Immich server  │  │ ML sidecar│  │
                    │  │  (port 2283)    │  │ (port 3003│  │
                    │  └────────┬────────┘  └───────────┘  │
                    └───────────┼──────────────────────────┘
                                │
               ┌────────────────┴──────────────┐
               ▼                               ▼
  ┌────────────────────────┐     ┌──────────────────────┐
  │   database-helm-chart  │     │   Bitnami Redis       │
  │                        │     │                      │
  │  PostgreSQL 14          │     │  Service: redis-master│
  │  + pgvecto.rs          │     └──────────────────────┘
  │  + VectorChord         │
  │                        │
  │  Service: immich-db    │
  └────────────────────────┘
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
  └─────────┼─────────────────────┘  (added as extra ML URL in Immich UI)
            │
    ┌───────┴──────────────┐
    ▼                      ▼
  database             Bitnami Redis
```

## Chart descriptions

### database-helm-chart

Deploys a single-replica PostgreSQL 14 instance using the [official Immich-patched image](https://github.com/immich-app/postgres). This image bundles two extensions that Immich requires:

- **pgvecto.rs** — vector similarity search used by smart search / CLIP embeddings
- **VectorChord** — an alternative vector index backend

A plain `postgres` image will not work — Immich's schema migrations depend on these extensions being present at startup.

The Service name is derived from the Helm release name. Installing as `helm install immich-db ./database-helm-chart` produces a Service named `immich-db`, which is why `immich-server-helm-chart` defaults to `databaseHost: "immich-db"`.

See [`database-helm-chart/README.md`](database-helm-chart/README.md) for the full parameter reference.

### immich-server-helm-chart

The main Immich chart. Deploys the Immich API + web UI server and, optionally, a co-located Machine Learning pod.

**Immich server** handles photo/video uploads, the web UI, the REST API, and background jobs. It connects to PostgreSQL for metadata and to Redis for job queueing.

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

## Dependencies

```
immich-server-helm-chart
├── requires: PostgreSQL (Service "immich-db", port 5432)
│               └── provided by: database-helm-chart (release name "immich-db")
├── requires: Redis (Service "redis-master", port 6379)
│               └── provided by: Bitnami Redis chart
└── ML service (port 3003)
                ├── sidecar (machineLearning.enabled=true)
                │     └── provided by: ML Deployment inside immich-server-helm-chart
                └── immich-ml-helper-chart (optional, independent release)
                      ├── can run alongside the sidecar as an extra ML worker
                      └── can replace the sidecar (machineLearning.enabled=false)
```

No chart declares Helm `dependencies:` — all components are installed as independent releases and must be running before Immich starts.

## Secrets setup

The database credentials must exist before any chart is installed.

```bash
kubectl create secret generic postgres-secret \
  --from-literal=username=immich \
  --from-literal=password=changeme \
  --namespace immich
```

Both `database-helm-chart` and `immich-server-helm-chart` reference this same secret by default (`postgres-secret`).

## Installation order

### Option A — default setup (ML sidecar)

```bash
# 1. Create namespace and secret
kubectl create namespace immich
kubectl create secret generic postgres-secret \
  --from-literal=username=immich \
  --from-literal=password=changeme \
  --namespace immich

# 2. Install PostgreSQL
helm install immich-db ./database-helm-chart --namespace immich

# 3. Install Redis (Bitnami chart)
helm install redis bitnami/redis --namespace immich

# 4. Install Immich (server + ML sidecar)
helm install immich ./immich-server-helm-chart --namespace immich
```

### Option B — ML helper as an additional worker (sidecar stays enabled)

```bash
# Steps 1–4 identical to option A, then:

# 5. Install ML helper on a second cluster / node (e.g. Rancher Desktop)
helm install immich-ml ./immich-ml-helper-chart --namespace immich

# 6. In the Immich admin UI, add the ML helper's reachable domain under
#    Administration > Machine Learning so Immich can offload inference to it.
```

### Option C — ML helper as a full replacement (sidecar disabled)

```bash
# Steps 1–3 identical to option A, then:

# 4. Install Immich server with the ML sidecar disabled
helm install immich ./immich-server-helm-chart \
  --set machineLearning.enabled=false \
  --namespace immich

# 5. Install ML helper on the target node
helm install immich-ml ./immich-ml-helper-chart --namespace immich

# 6. In the Immich admin UI, set the Machine Learning URL to:
#    http://immich-ml-svc:3003
```

## Upgrading

```bash
helm upgrade immich-db ./database-helm-chart  --namespace immich
helm upgrade immich    ./immich-server-helm-chart --namespace immich
# if using the split setup:
helm upgrade immich-ml ./immich-ml-helper-chart --namespace immich
```

## Uninstalling

```bash
helm uninstall immich    --namespace immich
helm uninstall immich-ml --namespace immich  # if installed
helm uninstall immich-db --namespace immich
helm uninstall redis     --namespace immich
```

PersistentVolumeClaims are not removed automatically:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=immich    --namespace immich
kubectl delete pvc -l app.kubernetes.io/instance=immich-db --namespace immich
kubectl delete pvc -l app.kubernetes.io/instance=immich-ml --namespace immich
```
