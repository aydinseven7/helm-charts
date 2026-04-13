# Dawarich — Helm chart stack

This folder contains all Helm charts and supporting values files needed to run a full [Dawarich](https://github.com/Freika/dawarich) deployment on Kubernetes.

## Charts

| Chart | Source | Purpose |
|-------|--------|---------|
| [`dawarich-helm-chart/`](dawarich-helm-chart/) | Custom | Dawarich Rails app + Sidekiq worker |
| [`postgis-helm-chart/`](postgis-helm-chart/) | Custom | PostgreSQL 17 with PostGIS 3.5 |
| [`redis-values.yaml`](redis-values.yaml) | Bitnami Redis (external) | Redis — job queue and cache |

## Architecture

```
                    ┌─────────────────────────────┐
                    │       dawarich-helm-chart    │
                    │                             │
                    │  ┌──────────┐ ┌──────────┐  │
                    │  │  Rails   │ │ Sidekiq  │  │
                    │  │  server  │ │ worker   │  │
                    │  └────┬─────┘ └────┬─────┘  │
                    └───────┼────────────┼────────┘
                            │            │
               ┌────────────┘            └────────────┐
               ▼                                      ▼
  ┌────────────────────────┐           ┌──────────────────────┐
  │   postgis-helm-chart   │           │    Bitnami Redis      │
  │                        │           │  (redis-values.yaml)  │
  │  PostgreSQL 17          │           │                      │
  │  + PostGIS 3.5         │           │  Service: redis-master│
  │                        │           └──────────────────────┘
  │  Service: postgis      │
  └────────────────────────┘
```

Both the **web** and **Sidekiq** containers inside `dawarich-helm-chart` connect to the same PostGIS instance and the same Redis instance.

## Chart descriptions

### dawarich-helm-chart

The main application chart. Deploys a single Pod with two containers:

- **web** — Puma/Rails server serving the Dawarich UI and REST API on port 3000.
- **sidekiq** — Background job worker that processes geocoding, import, and export jobs from the Redis queue.

Both containers share three PersistentVolumeClaims (`public`, `storage`, `watched`) and read their configuration from a ConfigMap that is generated from `values.yaml`.

Secrets (database password, SMTP password) are never stored in the ConfigMap — they are injected directly as environment variables sourced from Kubernetes Secrets.

See [`dawarich-helm-chart/README.md`](dawarich-helm-chart/README.md) for the full parameter reference.

### postgis-helm-chart

Deploys a single-replica PostgreSQL 17 instance with the PostGIS 3.5 extension pre-installed. Dawarich requires PostGIS for storing and querying geographic point data.

The chart exposes a `ClusterIP` Service. By default the Service name matches the Helm release name, so installing with `helm install postgis ./postgis-helm-chart` produces a Service named `postgis` — which is why `dawarich-helm-chart` sets `database.host: "postgis"`.

The database password must be provided via a Kubernetes Secret before installing (see [Secrets setup](#secrets-setup) below).

See [`postgis-helm-chart/README.md`](postgis-helm-chart/README.md) for the full parameter reference.

### redis-values.yaml

Not a standalone chart — this is a values override file for the [Bitnami Redis](https://github.com/bitnami/charts/tree/main/bitnami/redis) chart. It pins `fullnameOverride: "redis"`, which causes the Bitnami chart to create a Service named `redis-master`. This is the hostname that `dawarich-helm-chart` uses in `redis.host`.

Redis authentication is disabled by default (`auth.enabled: false`). If your cluster requires it, enable auth in `redis-values.yaml` and update `redis.host` in the dawarich values to include credentials.

## Dependencies

```
dawarich-helm-chart
├── requires: postgis (Service named "postgis", port 5432)
│               └── provided by: postgis-helm-chart (release name "postgis")
└── requires: Redis (Service named "redis-master", port 6379)
                └── provided by: Bitnami Redis chart (redis-values.yaml, fullnameOverride "redis")
```

The `dawarich-helm-chart` does **not** declare Helm chart dependencies (`Chart.yaml` `dependencies:` is empty). PostGIS and Redis must be installed as separate releases before Dawarich, because the app will fail to start if either backend is unreachable.

## Secrets setup

Both secrets must exist in the target namespace before any chart is installed.

**Database credentials** (used by both `postgis-helm-chart` and `dawarich-helm-chart`):

```bash
kubectl create secret generic dawarich-postgres-secret \
  --from-literal=password=changeme \
  --namespace dawarich
```

**SMTP credentials** (used by `dawarich-helm-chart` for outbound email):

```bash
kubectl create secret generic dawarich-secret \
  --from-literal=smtp-password=changeme \
  --namespace dawarich
```

## Installation order

Install in this order so that each dependency is ready before the chart that needs it:

```bash
# 1. Create namespace
kubectl create namespace dawarich

# 2. Create secrets
kubectl create secret generic dawarich-postgres-secret \
  --from-literal=password=changeme --namespace dawarich
kubectl create secret generic dawarich-secret \
  --from-literal=smtp-password=changeme --namespace dawarich

# 3. Install PostGIS
helm install postgis ./postgis-helm-chart --namespace dawarich

# 4. Install Redis (Bitnami chart, values from this repo)
helm install redis bitnami/redis -f redis-values.yaml --namespace dawarich

# 5. Install Dawarich
helm install dawarich ./dawarich-helm-chart --namespace dawarich
```

## Upgrading

Each chart is versioned independently. Upgrade them individually as needed:

```bash
helm upgrade postgis  ./postgis-helm-chart  --namespace dawarich
helm upgrade redis    bitnami/redis -f redis-values.yaml --namespace dawarich
helm upgrade dawarich ./dawarich-helm-chart --namespace dawarich
```

## Uninstalling

```bash
helm uninstall dawarich --namespace dawarich
helm uninstall redis    --namespace dawarich
helm uninstall postgis  --namespace dawarich
```

PersistentVolumeClaims are not removed automatically. Delete them manually when you no longer need the data:

```bash
kubectl delete pvc -l app=dawarich --namespace dawarich
kubectl delete pvc -l app.kubernetes.io/instance=postgis --namespace dawarich
kubectl delete pvc -l app.kubernetes.io/instance=redis --namespace dawarich
```
