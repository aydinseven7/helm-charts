# Immich Machine Learning Helm Chart

A Helm chart for deploying the Immich Machine Learning service as a standalone workload on Kubernetes.

## TL;DR

```bash
helm install immich-ml ./immich-ml-helper-chart
```

## Introduction

This chart bootstraps an [Immich Machine Learning](https://immich.app/docs/features/smart-search) deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

The ML service provides **CLIP-based smart search** and **facial recognition** for Immich. It is a separate process from the main Immich server and communicates over HTTP. You can run it on a dedicated node (e.g. one with a GPU or more RAM) independently of the server.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure (recommended — see [Persistence](#persistence))
- The Immich server chart installed and reachable in the same cluster

## Installing the Chart

```bash
helm install my-release ./immich-ml-helper-chart
```

The command deploys the ML service with the default configuration. See the [Parameters](#parameters) section for customisation options.

## Uninstalling the Chart

```bash
helm uninstall my-release
```

> **Note:** The model-cache PersistentVolumeClaim is **not** deleted automatically. To remove it:
> ```bash
> kubectl delete pvc my-release-ml-pvc
> ```

## Parameters

### Machine Learning parameters

| Name                              | Description                                              | Value                                            |
|-----------------------------------|----------------------------------------------------------|--------------------------------------------------|
| `machineLearning.enabled`         | Deploy the Machine Learning service                      | `true`                                           |
| `machineLearning.image.repository`| Container image repository                               | `ghcr.io/immich-app/immich-machine-learning`     |
| `machineLearning.image.tag`       | Container image tag                                      | `v2.6.3`                                         |
| `machineLearning.env`             | Extra environment variables (map of key/value pairs)     | `{}`                                             |

### Machine Learning Service parameters

| Name                                    | Description                                                   | Value       |
|-----------------------------------------|---------------------------------------------------------------|-------------|
| `machineLearning.service.type`          | Kubernetes Service type                                       | `ClusterIP` |
| `machineLearning.service.port`          | Service port                                                  | `3003`      |
| `machineLearning.service.targetPort`    | Port the ML process listens on inside the container           | `3003`      |
| `machineLearning.service.nodePort`      | NodePort to expose when `service.type=NodePort` (optional)    | `""`        |

### Machine Learning Persistence parameters

| Name                                         | Description                                                       | Value           |
|----------------------------------------------|-------------------------------------------------------------------|-----------------|
| `machineLearning.persistence.enabled`        | Enable a PersistentVolumeClaim for the model cache                | `true`          |
| `machineLearning.persistence.storageClass`   | StorageClass for the PVC (`""` uses the cluster default)          | `""`            |
| `machineLearning.persistence.accessMode`     | PVC access mode                                                   | `ReadWriteOnce` |
| `machineLearning.persistence.size`           | Size of the model-cache PVC                                       | `10Gi`          |

### Machine Learning Resource parameters

| Name                                          | Description        | Value   |
|-----------------------------------------------|--------------------|---------|
| `machineLearning.resources.limits.cpu`        | CPU limit          | `2`     |
| `machineLearning.resources.limits.memory`     | Memory limit       | `4Gi`   |
| `machineLearning.resources.requests.cpu`      | CPU request        | `10m`   |
| `machineLearning.resources.requests.memory`   | Memory request     | `500Mi` |

### Scheduling parameters

| Name                               | Description                                                                   | Value |
|------------------------------------|-------------------------------------------------------------------------------|-------|
| `machineLearning.nodeSelector`     | Node labels for pod assignment. Leave `{}` to allow any node.                 | `{}`  |
| `machineLearning.tolerations`      | Tolerations for pod scheduling (array)                                        | `[]`  |

## Configuration and installation details

### Persistence

Without a persistent volume the ML service re-downloads all models on every restart (~2–5 Gi). It is strongly recommended to keep `persistence.enabled: true` in production.

### Hardware acceleration

To enable GPU-accelerated inference, supply an extended image variant and configure the appropriate backend. See the [Immich hardware acceleration docs](https://immich.app/docs/features/ml-hardware-acceleration) for the full list of supported backends (`cuda`, `rocm`, `openvino`, `armnn`, `rknn`).

```yaml
machineLearning:
  image:
    tag: "v2.6.3-cuda"
  # Mount the extended compose-style file for your runtime:
  # extends:
  #   file: hwaccel.ml.yml
  #   service: cuda
```

### Pinning to a specific node architecture

Machine learning workloads require `amd64` by default. If your cluster is mixed-architecture, use `nodeSelector`:

```yaml
machineLearning:
  nodeSelector:
    kubernetes.io/arch: amd64
```

### Exposing the service outside the cluster

The default `ClusterIP` type is sufficient when the Immich server is in the same cluster. To expose the service externally via a static port, set:

```yaml
machineLearning:
  service:
    type: NodePort
    nodePort: 32003
```

### Service DNS name

The chart creates a Service named `<release-name>-ml-svc`. Configure the Immich server to reach it via:

```
<release-name>-ml-svc.<namespace>.svc.cluster.local:3003
```
