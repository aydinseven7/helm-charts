# PostGIS

[PostGIS](https://postgis.net) extends [PostgreSQL](https://www.postgresql.org) with support for geographic objects. This chart deploys a single-node PostGIS instance intended for use as a dedicated database backend within a cluster namespace.

## TL;DR

```bash
helm install postgis ./postgis-helm-chart \
  --set postgresql.existingSecret.enabled=true \
  --set postgresql.existingSecret.name=dawarich-postgres-secret
```

## Introduction

This chart deploys PostGIS on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager. It is designed as a lightweight, single-replica database suitable for small self-hosted workloads.

The image used is the official [`postgis/postgis`](https://hub.docker.com/r/postgis/postgis) Docker image, which bundles PostgreSQL and PostGIS together.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- A PersistentVolume provisioner (or an existing claim)
- A Kubernetes secret containing the database password if `postgresql.existingSecret.enabled` is `true`

## Installing the Chart

```bash
helm install postgis ./postgis-helm-chart -f my-values.yaml
```

## Uninstalling the Chart

```bash
helm uninstall postgis
```

Note: PersistentVolumeClaims are **not** deleted automatically. Remove them manually if no longer needed.

---

## Parameters

### Deployment parameters

| Name           | Description              | Value |
|----------------|--------------------------|-------|
| `replicaCount` | Number of pod replicas   | `1`   |

### Image parameters

| Name                | Description            | Value              |
|---------------------|------------------------|--------------------|
| `image.repository`  | PostGIS image repository | `postgis/postgis` |
| `image.pullPolicy`  | Image pull policy        | `IfNotPresent`    |

### PostgreSQL parameters

| Name                                    | Description                                                    | Value                      |
|-----------------------------------------|----------------------------------------------------------------|----------------------------|
| `postgresql.version`                    | PostgreSQL major version (used to select the image tag)        | `17`                       |
| `postgresql.username`                   | Database superuser username                                    | `postgres`                 |
| `postgresql.dbname`                     | Default database created on first boot                         | `dawarich`                 |
| `postgresql.existingSecret.enabled`     | Read the database password from an existing Kubernetes Secret  | `false`                    |
| `postgresql.existingSecret.name`        | Name of the secret                                             | `dawarich-postgres-secret` |
| `postgresql.existingSecret.key`         | Key within the secret                                          | `password`                 |

### PostGIS parameters

| Name              | Description                            | Value  |
|-------------------|----------------------------------------|--------|
| `postgis.enabled` | Enable the PostGIS extension           | `true` |
| `postgis.version` | PostGIS version (used in the image tag) | `3.5` |

### Security parameters

| Name                           | Description                                                     | Value      |
|--------------------------------|-----------------------------------------------------------------|------------|
| `security.password`            | Fallback password used when `existingSecret.enabled` is `false` | `changeme` |
| `security.networkPolicy.enable`| Restrict pod ingress via a NetworkPolicy                        | `false`    |

### Probe parameters

| Name                | Description                          | Value  |
|---------------------|--------------------------------------|--------|
| `liveness.enabled`  | Enable full SQL liveness probe       | `true` |
| `readiness.enabled` | Enable full SQL readiness probe      | `true` |

### Init container parameters

| Name               | Description                                                        | Value                 |
|--------------------|--------------------------------------------------------------------|-----------------------|
| `init.enabled`     | Run an init container before the database starts (e.g. load a dump) | `false`             |
| `init.image`       | Init container image                                               | `curlimages/curl`     |
| `init.command`     | Init container command                                             | `["curl"]`            |
| `init.args`        | Init container arguments                                           | *(see values.yaml)*   |

### Global parameters

| Name                | Description                                         | Value |
|---------------------|-----------------------------------------------------|-------|
| `imagePullSecrets`  | Image pull secrets                                  | `[]`  |
| `nameOverride`      | Override the chart name                             | `""`  |
| `fullnameOverride`  | Override the fully qualified app name               | `""`  |

### Service account parameters

| Name                        | Description                                   | Value  |
|-----------------------------|-----------------------------------------------|--------|
| `serviceAccount.create`     | Create a dedicated ServiceAccount             | `true` |
| `serviceAccount.annotations`| Annotations added to the ServiceAccount       | `{}`   |
| `serviceAccount.name`       | Name of the ServiceAccount (auto-generated if empty) | `""` |

### Network policy parameters

| Name                   | Description          | Value   |
|------------------------|----------------------|---------|
| `networkPolicy.enabled`| Enable NetworkPolicy | `false` |

### Pod parameters

| Name                 | Description                            | Value |
|----------------------|----------------------------------------|-------|
| `podAnnotations`     | Annotations added to the Pod           | `{}`  |
| `podSecurityContext` | Pod-level security context             | `{}`  |
| `securityContext`    | Container-level security context       | `{}`  |

### Service parameters

| Name           | Description        | Value       |
|----------------|--------------------|-------------|
| `service.type` | Service type       | `ClusterIP` |
| `service.port` | PostgreSQL port    | `5432`      |

### Resource parameters

| Name        | Description                        | Value |
|-------------|------------------------------------|-------|
| `resources` | CPU/memory requests and limits     | `{}`  |

### Persistence parameters

| Name                       | Description                                       | Value           |
|----------------------------|---------------------------------------------------|-----------------|
| `persistence.enabled`      | Enable PersistentVolumeClaim for data directory   | `true`          |
| `persistence.storageClass` | Storage class (empty = cluster default)           | `""`            |
| `persistence.accessMode`   | PVC access mode                                   | `ReadWriteOnce` |
| `persistence.size`         | PVC size                                          | `5Gi`           |

### Autoscaling parameters

| Name                                        | Description                            | Value   |
|---------------------------------------------|----------------------------------------|---------|
| `autoscaling.enabled`                       | Enable HorizontalPodAutoscaler         | `false` |
| `autoscaling.minReplicas`                   | Minimum replica count                  | `1`     |
| `autoscaling.maxReplicas`                   | Maximum replica count                  | `100`   |
| `autoscaling.targetCPUUtilizationPercentage`| Target CPU utilisation for scaling     | `80`    |

### Scheduling parameters

| Name           | Description                              | Value |
|----------------|------------------------------------------|-------|
| `nodeSelector` | Node labels for pod assignment           | `{}`  |
| `tolerations`  | Tolerations for pod assignment           | `[]`  |
| `affinity`     | Affinity rules for pod assignment        | `{}`  |

---

## Configuration and installation details

### Database credentials

The recommended approach is to supply the database password via an existing Kubernetes Secret:

```bash
kubectl create secret generic dawarich-postgres-secret \
  --from-literal=password=my-db-password \
  --namespace dawarich
```

Then enable it in your values:

```yaml
postgresql:
  existingSecret:
    enabled: true
    name: dawarich-postgres-secret
    key: password
```

When `existingSecret.enabled` is `false`, the value of `security.password` is used as the `POSTGRES_PASSWORD` environment variable directly. This is only suitable for development or testing.

### Image tagging

The container image tag is assembled from `postgresql.version` and `postgis.version`:

```
postgis/postgis:<postgresql.version>-<postgis.version>
```

For example, the defaults produce the tag `17-3.5`. Refer to the [postgis/postgis tags](https://hub.docker.com/r/postgis/postgis/tags) page for available combinations.

### Liveness and readiness probes

When `liveness.enabled` / `readiness.enabled` is `true`, the probes execute a real SQL query (`SELECT 1`) against the configured database. This is stricter than a simple `pg_isready` check and confirms the database is accepting connections and the target DB exists. If you need a faster startup, set these to `false` to fall back to `pg_isready`.

### Init container (seeding data)

The optional init container runs before the PostgreSQL container starts and can be used to download a SQL dump to `/data`, which is shared with the database via an `emptyDir` volume mounted at `/docker-entrypoint-initdb.d`. Any `.sql` or `.sql.gz` file placed there will be automatically executed by PostgreSQL on first boot.

Example — download and seed a dump from a remote URL:

```yaml
init:
  enabled: true
  image: curlimages/curl
  command: ["curl"]
  args:
    - "https://example.com/seed.sql"
    - "-o"
    - "/data/seed.sql"
```

### Resource requests and limits

`resources` defaults to `{}` (no requests or limits). Recommended starting values for a light workload:

```yaml
resources:
  limits:
    cpu: 300m
    memory: 500Mi
  requests:
    cpu: 10m
    memory: 64Mi
```
