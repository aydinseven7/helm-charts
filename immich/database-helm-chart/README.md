# Immich Database Helm Chart

A Helm chart for deploying the Immich-patched PostgreSQL database on Kubernetes.

## TL;DR

```bash
kubectl create secret generic postgres-secret \
  --from-literal=username=immich \
  --from-literal=password=changeme

helm install immich-db ./database-helm-chart
```

## Introduction

This chart bootstraps an [Immich-patched PostgreSQL](https://github.com/immich-app/postgres) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

The image is a drop-in PostgreSQL 14 build that bundles the **pgvecto.rs** and **VectorChord** extensions required by Immich for vector-similarity search. A plain `postgres` image will not work.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure
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
helm install my-release ./database-helm-chart
```

The command deploys PostgreSQL on the Kubernetes cluster with the default configuration. See the [Parameters](#parameters) section for customisation options.

## Uninstalling the Chart

```bash
helm uninstall my-release
```

> **Note:** The PersistentVolumeClaim created by the chart is **not** deleted automatically. To remove it:
> ```bash
> kubectl delete pvc my-release-db-pvc
> ```

## Parameters

### Image parameters

| Name               | Description                          | Value                                           |
|--------------------|--------------------------------------|-------------------------------------------------|
| `image.repository` | PostgreSQL image repository          | `ghcr.io/immich-app/postgres`                   |
| `image.tag`        | PostgreSQL image tag                 | `14-vectorchord0.4.3-pgvectors0.2.0`            |

### PostgreSQL credential parameters

Credentials are sourced from a Kubernetes Secret. The fields below tell the chart which Secret and key to read.

| Name                    | Description                                           | Value             |
|-------------------------|-------------------------------------------------------|-------------------|
| `postgresUser.name`     | Name of the Secret containing the PostgreSQL username | `postgres-secret` |
| `postgresUser.key`      | Key within the Secret for the username value          | `username`        |
| `postgresPassword.name` | Name of the Secret containing the PostgreSQL password | `postgres-secret` |
| `postgresPassword.key`  | Key within the Secret for the password value          | `password`        |
| `postgresDatabase`      | Name of the database to create                        | `immich`          |

### Persistence parameters

| Name                        | Description                                                    | Value   |
|-----------------------------|----------------------------------------------------------------|---------|
| `persistence.enabled`       | Enable a PersistentVolumeClaim for database data               | `true`  |
| `persistence.storageClass`  | StorageClass for the PVC (`""` uses the cluster default)       | `""`    |
| `persistence.accessMode`    | PVC access mode                                                | `ReadWriteOnce` |
| `persistence.size`          | Size of the PVC                                                | `10Gi`  |

### Scheduling parameters

| Name           | Description                                                              | Value |
|----------------|--------------------------------------------------------------------------|-------|
| `nodeSelector` | Node labels for pod assignment. Leave `{}` to allow any node.            | `{}`  |

## Configuration and installation details

### Choosing a storage class

Set `persistence.storageClass` to match a StorageClass available in your cluster:

```yaml
persistence:
  storageClass: "longhorn"
  size: 30Gi
```

Run `kubectl get storageclass` to list available classes.

### Pinning the database to a node

If your database storage is local to a specific node, use `nodeSelector`:

```yaml
nodeSelector:
  kubernetes.io/hostname: my-storage-node
```

### Service DNS name

The chart creates a `ClusterIP` Service named `<release-name>-db` on port `5432`. When installing with the recommended release name `immich-db`, the DNS name becomes:

```
immich-db.default.svc.cluster.local
```

Set `databaseHost: immich-db` in the Immich server chart to match.
