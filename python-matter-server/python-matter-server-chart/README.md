# Python Matter Server Helm Chart

A Helm chart for deploying the [Python Matter Server](https://github.com/home-assistant-libs/python-matter-server) on Kubernetes.

## TL;DR

```bash
helm install my-release ./python-matter-server-chart
```

## Introduction

This chart bootstraps a Python Matter Server deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

Python Matter Server implements the Matter protocol stack and exposes a WebSocket API on port **5580** that Home Assistant uses to control Matter-compatible smart home devices.

It requires **host networking** and an **unconfined AppArmor profile** so that the Matter transport layers (UDP multicast, Bluetooth) can function correctly. Pin the pod to a node with a Thread or Bluetooth radio via `nodeSelector`.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure
- A node with access to the Thread/BLE radio used for Matter commissioning

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm install my-release ./python-matter-server-chart
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
helm uninstall my-release
```

> **Note:** PersistentVolumeClaims created by the chart are **not** deleted automatically. To remove them:
> ```bash
> kubectl delete pvc my-release-pvc
> ```

## Parameters

### Image parameters

| Name               | Description                           | Value                                              |
|--------------------|---------------------------------------|----------------------------------------------------|
| `image.repository` | Python Matter Server image repository | `ghcr.io/home-assistant-libs/python-matter-server` |
| `image.tag`        | Python Matter Server image tag        | `8.1.2`                                            |

### Python Matter Server parameters

| Name          | Description                                                               | Value   |
|---------------|---------------------------------------------------------------------------|---------|
| `logLevel`    | Log verbosity (`silly`, `debug`, `info`, `notice`, `warn`, `error`, `fatal`) | `info` |
| `storagePath` | Path inside the container where Matter commissioning data is persisted    | `/data` |
| `annotations` | Pod-level annotations (AppArmor confinement disabled by default)          | See values.yaml |
| `replicaCount` | Number of replicas                                                       | `1`     |

### Network parameters

| Name          | Description                                                        | Value                     |
|---------------|--------------------------------------------------------------------|---------------------------|
| `hostNetwork` | Enable host networking (required for Matter UDP multicast)         | `true`                    |
| `dnsPolicy`   | DNS policy to use when host networking is enabled                  | `ClusterFirstWithHostNet` |

### Persistence parameters

| Name                       | Description                                                         | Value           |
|----------------------------|---------------------------------------------------------------------|-----------------|
| `persistence.enabled`      | Enable a PersistentVolumeClaim for Matter commissioning data        | `true`          |
| `persistence.storageClass` | StorageClass for the data PVC (`""` uses the cluster default)       | `longhorn`      |
| `persistence.accessMode`   | PVC access mode                                                     | `ReadWriteOnce` |
| `persistence.size`         | Size of the data PVC                                                | `1Gi`           |

### Service parameters

| Name                 | Description                                       | Value       |
|----------------------|---------------------------------------------------|-------------|
| `service.type`       | Kubernetes Service type                           | `ClusterIP` |
| `service.port`       | Matter WebSocket server port (used by Home Assistant) | `5580`  |
| `service.targetPort` | Port the server listens on inside the container   | `5580`      |

### Scheduling parameters

| Name           | Description                    | Value |
|----------------|--------------------------------|-------|
| `nodeSelector` | Node labels for pod assignment | `{}`  |

### Resource parameters

| Name        | Description                                                     | Value |
|-------------|-----------------------------------------------------------------|-------|
| `resources` | Resource requests and limits for the Matter Server container    | `{}`  |

## Configuration and installation details

### Connecting Home Assistant

Point your Home Assistant Matter integration at the WebSocket service. If the release name is `my-release` and both are in the same namespace, the address is:

```
ws://my-release-svc:5580/ws
```

### Host networking and AppArmor

Matter uses UDP multicast for device discovery and Bluetooth for commissioning. Both require host networking and an unconfined AppArmor profile. These are enabled by default — do not disable them without understanding the impact on device commissioning.

### Pinning to a specific node

Use `nodeSelector` to ensure the pod is scheduled on a node with the required Thread or Bluetooth radio:

```yaml
nodeSelector:
  kubernetes.io/hostname: my-node
```
