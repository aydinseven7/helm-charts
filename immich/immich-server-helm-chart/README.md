# Immich Server Helm Chart

A Helm chart for deploying the Immich photo and video management server on Kubernetes.

## TL;DR

```bash
helm install immich ./immich-server-helm-chart
```

## Introduction

This chart bootstraps an [Immich](https://immich.app) server deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

The chart deploys the **Immich server** (API + web UI) and optionally co-deploys the **Machine Learning** sidecar (CLIP smart search and facial recognition) in the same release.

By default it also deploys a [CloudNativePG](https://cloudnative-pg.io) `Cluster` on the Immich-patched PostgreSQL image (VectorChord + pgvector) through the [cloudnative-pg `cluster` chart](https://github.com/cloudnative-pg/charts/tree/main/charts/cluster), pulled in as a dependency under the `cnpg` key. It also deploys a [Valkey](https://valkey.io) instance (Redis-compatible, used for job queueing) through the official [valkey chart](https://github.com/valkey-io/valkey-helm) under the `valkey` key. Immich connects to both automatically.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure
- The [CloudNativePG operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) installed in the cluster (or `cnpg.enabled: false` and an existing PostgreSQL, see [Using an external database](#using-an-external-database))

## Installing the Chart

```bash
helm install my-release ./immich-server-helm-chart
```

The command deploys Immich on the Kubernetes cluster with the default configuration. See the [Parameters](#parameters) section for customisation options.

## Uninstalling the Chart

```bash
helm uninstall my-release
```

> **Note:** PersistentVolumeClaims created by the chart are **not** deleted automatically. To remove them:
> ```bash
> kubectl delete pvc my-release-pvc my-release-ml-pvc
> ```

## Parameters

### Image parameters

| Name               | Description                    | Value                                  |
|--------------------|--------------------------------|----------------------------------------|
| `image.repository` | Immich server image repository | `ghcr.io/immich-app/immich-server`     |
| `image.tag`        | Immich server image tag        | `v2.6.3`                               |

### External dependency parameters

| Name           | Description                                                                 | Value          |
|----------------|-----------------------------------------------------------------------------|----------------|
| `databaseHost` | PostgreSQL Service DNS name. Defaults to `<cluster>-rw` when `cnpg.enabled` | `""`           |
| `redisHost`    | Redis Service DNS name. Defaults to `<release>-valkey` when `valkey.enabled` | `""`           |
| `databaseName` | PostgreSQL database name. Keep in sync with `cnpg.cluster.initdb.database`  | `immich`       |

### PostgreSQL credential parameters

Credentials are sourced from a Kubernetes Secret. The fields below tell the chart which Secret and key to read. When a `secretName` is empty and `cnpg.enabled`, the CNPG Cluster's app secret is used.

| Name                          | Description                                           | Value      |
|-------------------------------|-------------------------------------------------------|------------|
| `postgresUser.secretName`     | Name of the Secret containing the PostgreSQL username | `""`       |
| `postgresUser.key`            | Key within the Secret for the username value          | `username` |
| `postgresPassword.secretName` | Name of the Secret containing the PostgreSQL password | `""`       |
| `postgresPassword.key`        | Key within the Secret for the password value          | `password` |

### Valkey parameters

Everything under `valkey` except `enabled` is passed to the [valkey chart](https://github.com/valkey-io/valkey-helm/blob/main/valkey/values.yaml); any of its values can be set here. The defaults this chart sets:

| Name                         | Description                                      | Value   |
|------------------------------|--------------------------------------------------|---------|
| `valkey.enabled`             | Deploy Valkey                                    | `true`  |
| `valkey.fullnameOverride`    | Service/workload name. Defaults to `<release>-valkey` | `""` |
| `valkey.auth.enabled`        | Require authentication                           | `false` |
| `valkey.dataStorage.enabled` | Persist data to a PVC                            | `false` |
| `valkey.resources`           | Resource requests and limits for the Valkey pod  | `{}`    |

### CloudNativePG parameters

Everything under `cnpg` except `enabled` is passed to the [cloudnative-pg `cluster` chart](https://github.com/cloudnative-pg/charts/blob/main/charts/cluster/values.yaml); any of its values can be set here. The defaults this chart sets:

| Name                                            | Description                                                  | Value                                                            |
|-------------------------------------------------|--------------------------------------------------------------|------------------------------------------------------------------|
| `cnpg.enabled`                                  | Deploy the CNPG Cluster                                      | `true`                                                           |
| `cnpg.fullnameOverride`                         | Cluster name. Defaults to `<release>-cnpg`                   | `""`                                                             |
| `cnpg.version.postgresql`                       | PostgreSQL major version (must match the image)              | `18`                                                             |
| `cnpg.cluster.instances`                        | Number of PostgreSQL instances                               | `1`                                                              |
| `cnpg.cluster.imageName`                        | Immich-patched PostgreSQL image                              | `ghcr.io/immich-app/postgres:18-vectorchord1.1.1-pgvector0.8.5`  |
| `cnpg.cluster.postgresUID` / `postgresGID`      | UID/GID postgres runs as in that image                       | `999`                                                            |
| `cnpg.cluster.storage.size`                     | PVC size                                                     | `10Gi`                                                           |
| `cnpg.cluster.storage.storageClass`             | Storage class (empty uses the cluster default)               | `""`                                                             |
| `cnpg.cluster.postgresql.shared_preload_libraries` | Libraries preloaded by PostgreSQL                         | `[vchord.so]`                                                    |
| `cnpg.cluster.resources`                        | Resource requests and limits for the PostgreSQL pods         | `{}`                                                             |
| `cnpg.cluster.initdb.database`                  | Database created on first bootstrap                          | `immich`                                                         |
| `cnpg.cluster.initdb.owner`                     | Owner role of that database                                  | `immich`                                                         |
| `cnpg.cluster.initdb.postInitApplicationSQL`    | SQL run in the new database as superuser                     | creates `vchord` and `earthdistance`                             |
| `cnpg.cluster.initdb.secret.name`               | Existing basic-auth secret to seed the owner's credentials   | unset (CNPG generates `<cluster>-app`)                           |
| `cnpg.backups.enabled`                          | Enable barman-cloud backups                                  | `false`                                                          |

### Immich environment parameters

| Name                  | Description                                                      | Value                    |
|-----------------------|------------------------------------------------------------------|--------------------------|
| `env.uploadLocation`  | Path inside the container where uploaded media is stored         | `/usr/src/app/upload`    |
| `env.loglevel`        | Log verbosity (`verbose`, `debug`, `log`, `warn`, `error`)       | `log`                    |

### Persistence parameters

| Name                       | Description                                                  | Value           |
|----------------------------|--------------------------------------------------------------|-----------------|
| `persistence.enabled`      | Enable a PersistentVolumeClaim for uploaded media            | `true`          |
| `persistence.storageClass` | StorageClass for the PVC (`""` uses the cluster default)     | `""`            |
| `persistence.accessMode`   | PVC access mode                                              | `ReadWriteOnce` |
| `persistence.size`         | Size of the upload PVC                                       | `50Gi`          |

### Service parameters

| Name                | Description                     | Value       |
|---------------------|---------------------------------|-------------|
| `service.type`      | Kubernetes Service type         | `ClusterIP` |
| `service.port`      | Service port                    | `80`        |
| `service.targetPort`| Port Immich listens on in-pod   | `2283`      |

### Resource parameters

| Name                        | Description    | Value  |
|-----------------------------|----------------|--------|
| `resources.limits.cpu`      | CPU limit      | `500m` |
| `resources.limits.memory`   | Memory limit   | `2Gi`  |
| `resources.requests.cpu`    | CPU request    | `10m`  |
| `resources.requests.memory` | Memory request | `25Mi` |

### Scheduling parameters

| Name           | Description                                                                   | Value |
|----------------|-------------------------------------------------------------------------------|-------|
| `nodeSelector` | Node labels for Immich server pod assignment. Leave `{}` to allow any node.   | `{}`  |
| `affinity`     | Affinity rules for server pod scheduling                                      | `{}`  |
| `tolerations`  | Tolerations for server pod scheduling (array)                                 | `[]`  |

### Machine Learning parameters

| Name                                         | Description                                                         | Value                                        |
|----------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `machineLearning.enabled`                    | Deploy the Machine Learning sidecar                                 | `true`                                       |
| `machineLearning.image.repository`           | ML container image repository                                       | `ghcr.io/immich-app/immich-machine-learning` |
| `machineLearning.image.tag`                  | ML container image tag                                              | `v2.6.3`                                     |
| `machineLearning.env`                        | Extra environment variables for the ML container                    | `{}`                                         |
| `machineLearning.nodeSelector`               | Node labels for ML pod assignment                                   | `{}`                                         |
| `machineLearning.affinity`                   | Affinity rules for ML pod scheduling                                | `{}`                                         |
| `machineLearning.tolerations`                | Tolerations for ML pod scheduling (array)                           | `[]`                                         |
| `machineLearning.persistence.enabled`        | Enable a PersistentVolumeClaim for the ML model cache               | `true`                                       |
| `machineLearning.persistence.storageClass`   | StorageClass for the model-cache PVC (`""` uses the cluster default)| `""`                                         |
| `machineLearning.persistence.accessMode`     | PVC access mode                                                     | `ReadWriteOnce`                              |
| `machineLearning.persistence.size`           | Size of the model-cache PVC                                         | `10Gi`                                       |
| `machineLearning.resources.limits.cpu`       | ML CPU limit                                                        | `2`                                          |
| `machineLearning.resources.limits.memory`    | ML memory limit                                                     | `4Gi`                                        |
| `machineLearning.resources.requests.cpu`     | ML CPU request                                                      | `10m`                                        |
| `machineLearning.resources.requests.memory`  | ML memory request                                                   | `25Mi`                                       |

### Ingress parameters

| Name                      | Description                                                                   | Value                 |
|---------------------------|-------------------------------------------------------------------------------|-----------------------|
| `ingress.enabled`         | Enable an Ingress resource                                                    | `false`               |
| `ingress.ingressClassName`| IngressClass to use (e.g. `nginx`, `traefik`)                                 | `nginx`               |
| `ingress.annotations`     | Additional annotations for the Ingress resource                               | `{}`                  |
| `ingress.host`            | Hostname at which Immich will be served                                       | `immich.example.com`  |
| `ingress.path`            | Path prefix                                                                   | `/`                   |
| `ingress.tls`             | TLS configuration (leave `[]` if your proxy handles TLS termination upstream) | `[]`                  |

### HTTPRoute parameters (Gateway API)

| Name                       | Description                                                    | Value                 |
|----------------------------|------------------------------------------------------------------|-----------------------|
| `httpRoute.enabled`        | Enable an HTTPRoute resource                                     | `false`               |
| `httpRoute.parentRefs`     | References to the Gateway(s) this HTTPRoute attaches to          | `[]`                  |
| `httpRoute.host`           | Hostname at which Immich will be served                          | `immich.example.com`  |
| `httpRoute.path`           | Path prefix                                                      | `/`                   |
| `httpRoute.labels`         | Additional labels for the HTTPRoute resource                     | `{}`                  |
| `httpRoute.extraAnnotations` | Additional annotations for the HTTPRoute resource               | `{}`                  |

## Configuration and installation details

### Database

With `cnpg.enabled: true` (the default) nothing needs to be created up front. CNPG bootstraps the `immich` database, creates the `vchord` and `earthdistance` extensions (the Immich user is not a superuser, so it cannot create them itself), and the chart points Immich at the Cluster's read-write Service (`<cluster>-rw`) with the credentials from its app secret (`<cluster>-app`).

To choose the owner's password yourself, create a `kubernetes.io/basic-auth` secret and hand it to CNPG; Immich then reads its credentials from that secret instead:

```bash
kubectl create secret generic immich-postgresql-secret \
  --type=kubernetes.io/basic-auth \
  --from-literal=username=immich \
  --from-literal=password=<your-password>
```

```yaml
cnpg:
  cluster:
    initdb:
      secret:
        name: immich-postgresql-secret
```

Backups, recovery/import from an existing database, monitoring and any other Cluster settings are configured under `cnpg` with the cluster chart's own values. For example, to migrate from the companion [database chart](../database-helm-chart/), set `cnpg.mode: recovery` with `cnpg.recovery.method: import`.

#### Using an external database

Set `cnpg.enabled: false` and point the chart at your own PostgreSQL (it must have VectorChord available, e.g. the companion [database chart](../database-helm-chart/)). Credentials are read from a pre-existing Secret:

```bash
kubectl create secret generic postgres-secret \
  --from-literal=username=immich \
  --from-literal=password=<your-password>
```

```yaml
cnpg:
  enabled: false
databaseHost: "immich-db"
postgresUser:
  secretName: postgres-secret
postgresPassword:
  secretName: postgres-secret
```

### Valkey

With `valkey.enabled: true` (the default) the chart deploys a single Valkey instance without authentication or persistence and points Immich at its Service (`<release>-valkey`). Queued jobs do not survive a Valkey restart; enable `valkey.dataStorage` if that matters to you.

To use an existing Redis or Valkey instead:

```yaml
valkey:
  enabled: false
redisHost: "my-valkey"
```

Avoid a Service literally named `redis`: Kubernetes injects a `REDIS_PORT=tcp://...` env var for it, which clashes with Immich's own `REDIS_PORT` setting.

### Enabling Ingress

To expose Immich via an Ingress controller:

```yaml
ingress:
  enabled: true
  ingressClassName: nginx
  host: immich.example.com
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: 4G
```

#### With cert-manager TLS

```yaml
ingress:
  tls:
    - secretName: immich-tls
      hosts:
        - immich.example.com
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
```

#### With a Cloudflare Tunnel

```yaml
ingress:
  annotations:
    external-dns.alpha.kubernetes.io/cloudflare-proxied: "true"
    external-dns.alpha.kubernetes.io/hostname: immich.example.com
    external-dns.alpha.kubernetes.io/target: <tunnel-id>.cfargotunnel.com
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: 4G
```

### Enabling HTTPRoute (Gateway API)

To expose Immich via a Gateway API `Gateway` instead of an Ingress:

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
  host: immich.example.com
```

### Disabling Machine Learning

If your nodes lack the resources for the ML workload or you prefer to run it separately via the [ML helper chart](../immich-ml-helper-chart/):

```yaml
machineLearning:
  enabled: false
```

### Pinning Machine Learning to a specific node

```yaml
machineLearning:
  nodeSelector:
    kubernetes.io/arch: amd64
```

### Storage sizing guide

| Library size    | Upload PVC  | ML model cache |
|-----------------|-------------|----------------|
| < 10k photos    | 50 Gi       | 10 Gi          |
| 10k–100k photos | 200 Gi      | 10 Gi          |
| > 100k photos   | 500 Gi+     | 10 Gi          |
