# Immich Server Helm Chart

A Helm chart for deploying the Immich photo and video management server on Kubernetes.

## TL;DR

```bash
kubectl create secret generic postgres-secret \
  --from-literal=username=immich \
  --from-literal=password=changeme

helm install immich ./immich-server-helm-chart
```

## Introduction

This chart bootstraps an [Immich](https://immich.app) server deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

The chart deploys the **Immich server** (API + web UI) and optionally co-deploys the **Machine Learning** sidecar (CLIP smart search and facial recognition) in the same release. External PostgreSQL and Redis services are required and must be reachable by DNS before installation.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure
- A running PostgreSQL instance (see the companion [database chart](../database-helm-chart/))
- A running Redis instance (e.g. [Bitnami Redis](https://github.com/bitnami/charts/tree/main/bitnami/redis))
- A Kubernetes Secret containing the PostgreSQL credentials (see [Before you begin](#before-you-begin))

## Before you begin

Credentials are read from a pre-existing Secret so that passwords never appear in values files or Helm history. Create it before installing the chart:

```bash
kubectl create secret generic postgres-secret \
  --from-literal=username=immich \
  --from-literal=password=<your-password>
```

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
| `databaseHost` | Kubernetes DNS name of the PostgreSQL Service                               | `immich-db`    |
| `redisHost`    | Kubernetes DNS name of the Redis Service                                    | `redis-master` |
| `databaseName` | Name of the PostgreSQL database Immich should connect to                    | `immich`       |

### PostgreSQL credential parameters

Credentials are sourced from a Kubernetes Secret. The fields below tell the chart which Secret and key to read.

| Name                          | Description                                           | Value             |
|-------------------------------|-------------------------------------------------------|-------------------|
| `postgresUser.secretName`     | Name of the Secret containing the PostgreSQL username | `postgres-secret` |
| `postgresUser.key`            | Key within the Secret for the username value          | `username`        |
| `postgresPassword.secretName` | Name of the Secret containing the PostgreSQL password | `postgres-secret` |
| `postgresPassword.key`        | Key within the Secret for the password value          | `password`        |

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

## Configuration and installation details

### Connecting to external services

Ensure PostgreSQL and Redis are reachable before installing this chart. Set `databaseHost` and `redisHost` to the Kubernetes Service DNS names of those deployments:

```yaml
databaseHost: "immich-db"      # Service name of the database chart release
redisHost: "redis-master"      # Default Service name from Bitnami Redis chart
```

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
