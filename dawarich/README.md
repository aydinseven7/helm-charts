# Dawarich — Helm chart stack

This folder contains all Helm charts needed to run a full [Dawarich](https://github.com/Freika/dawarich) deployment on Kubernetes.

## Charts

| Chart | Source | Purpose |
|-------|--------|---------|
| [`dawarich-helm-chart/`](dawarich-helm-chart/) | Custom | Dawarich Rails app + Sidekiq worker, plus a bundled CloudNativePG PostGIS `Cluster` and Valkey |
| [`postgis-helm-chart/`](postgis-helm-chart/) | Custom (legacy) | Plain PostgreSQL 17 + PostGIS Deployment, superseded by the bundled CNPG Cluster |

## Architecture

```
  ┌──────────────────────────────────────────────┐
  │              dawarich-helm-chart             │
  │                                              │
  │  ┌──────────┐ ┌──────────┐                   │
  │  │  Rails   │ │ Sidekiq  │                   │
  │  │  server  │ │ worker   │                   │
  │  └────┬─────┘ └────┬─────┘                   │
  │       ├────────────┴──────────┐              │
  │       ▼                       ▼              │
  │  ┌────────────────────────┐ ┌─────────────┐  │
  │  │ CNPG Cluster (cnpg.*)  │ │   Valkey    │  │
  │  │ PostgreSQL 17          │ │ (valkey.*)  │  │
  │  │ + PostGIS 3.6          │ │ Service:    │  │
  │  │ Service: <cluster>-rw  │ │ <rel>-valkey│  │
  │  └────────────────────────┘ └─────────────┘  │
  └──────────────────────────────────────────────┘
```

Both the **web** and **Sidekiq** containers inside `dawarich-helm-chart` connect to the same CNPG Cluster and the same Valkey instance.

## Chart descriptions

### dawarich-helm-chart

The main application chart. Deploys a single Pod with two containers:

- **web** — Puma/Rails server serving the Dawarich UI and REST API on port 3000.
- **sidekiq** — Background job worker that processes geocoding, import, and export jobs from the Valkey (Redis-compatible) queue.

Both containers share three PersistentVolumeClaims (`public`, `storage`, `watched`) and read their configuration from a ConfigMap that is generated from `values.yaml`.

The database is a [CloudNativePG](https://cloudnative-pg.io) `Cluster` deployed through the cloudnative-pg [`cluster` chart](https://github.com/cloudnative-pg/charts/tree/main/charts/cluster), imported as a dependency under the `cnpg` key. It bootstraps the `dawarich` database with the PostGIS extensions, and the app is wired to its `<cluster>-rw` Service and `<cluster>-app` credentials automatically. Set `cnpg.enabled: false` to use an external PostgreSQL instead.

The job queue and cache run on [Valkey](https://valkey.io), deployed through the official [valkey chart](https://github.com/valkey-io/valkey-helm) under the `valkey` key (no auth, no persistence by default) and wired into `REDIS_URL` automatically. Set `valkey.enabled: false` and `redis.host` to use an external Redis/Valkey instead.

Secrets (database password, SMTP password) are never stored in the ConfigMap — they are injected directly as environment variables sourced from Kubernetes Secrets.

See [`dawarich-helm-chart/README.md`](dawarich-helm-chart/README.md) for the full parameter reference.

### postgis-helm-chart (legacy)

Deploys a single-replica PostgreSQL 17 instance with PostGIS as a plain Deployment. It is kept for existing installs; new installs should use the CNPG Cluster bundled in `dawarich-helm-chart`. To move an existing install over, import from this instance's Service with the cluster chart's recovery mode (`cnpg.mode: recovery`, `cnpg.recovery.method: import`), switch over, then remove this release.

See [`postgis-helm-chart/README.md`](postgis-helm-chart/README.md) for its parameter reference.

## Dependencies

```
dawarich-helm-chart
├── requires: CloudNativePG operator (cluster-wide, installed separately)
├── bundles:  CNPG Cluster (cloudnative-pg "cluster" chart, alias cnpg)
└── bundles:  Valkey (valkey chart)
```

## Secrets setup

**SMTP credentials** (used by `dawarich-helm-chart` for outbound email) must exist before installing:

```bash
kubectl create secret generic dawarich-secret \
  --from-literal=smtp-password=changeme \
  --namespace dawarich
```

No database secret is needed: CNPG generates `<cluster>-app`. To set the password yourself, create a `kubernetes.io/basic-auth` secret and set `cnpg.cluster.initdb.secret.name` (see the chart README).

## Installation order

```bash
# 1. Create namespace
kubectl create namespace dawarich

# 2. Create secrets
kubectl create secret generic dawarich-secret \
  --from-literal=smtp-password=changeme --namespace dawarich

# 3. Install Dawarich (with its CNPG Cluster and Valkey)
helm install dawarich ./dawarich-helm-chart --namespace dawarich
```

## Upgrading

Upgrade the release as needed:

```bash
helm upgrade dawarich ./dawarich-helm-chart --namespace dawarich
```

## Uninstalling

```bash
helm uninstall dawarich --namespace dawarich
```

> **Note:** uninstalling `dawarich` also deletes its CNPG `Cluster`, and CNPG garbage-collects the Cluster's PVCs with it — the database is gone unless you have backups (`cnpg.backups`).

The app's PersistentVolumeClaims are not removed automatically. Delete them manually when you no longer need the data:

```bash
kubectl delete pvc -l app=dawarich --namespace dawarich
```
