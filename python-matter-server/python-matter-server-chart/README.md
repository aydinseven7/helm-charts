# Matter Server Helm Chart

A Helm chart for deploying [matter-js/matterjs-server](https://github.com/matter-js/matterjs-server) on Kubernetes — the OHF-based successor to the archived [Python Matter Server](https://github.com/home-assistant-libs/python-matter-server) (this chart deployed the Python implementation prior to `v1.0.0`).

## TL;DR

```bash
helm install my-release ./python-matter-server-chart
```

## Introduction

This chart bootstraps a Matter server deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

The server implements the Matter protocol stack and exposes a WebSocket API and a built-in web dashboard, both on port **5580**, that Home Assistant and browsers use respectively to interact with Matter-compatible smart home devices.

It requires **host networking** and an **unconfined AppArmor profile** so that the Matter transport layers (UDP multicast, Bluetooth) can function correctly. Pin the pod to a node with a Thread or Bluetooth radio via `nodeSelector`.

### Upgrading from the Python Matter Server (`< 1.0.0`)

The new image runs as a non-root user (uid/gid `1000`) and chowns `/data` to match, whereas the Python image wrote its data as root. This chart now sets `fsGroup: 1000` by default so the existing PVC becomes readable/writable — you shouldn't need to do anything extra. On first start, the new server detects and migrates the old server's legacy JSON data automatically; watch the pod logs for `LegacyDataLoader` / `LegacyDataInjector` entries confirming your fabric and nodes were picked up. Take a backup of the PVC before upgrading in case the migration doesn't go cleanly.

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

| Name               | Description                     | Value                                |
|--------------------|----------------------------------|----------------------------------------|
| `image.repository` | Matter server image repository  | `ghcr.io/matter-js/matterjs-server`    |
| `image.tag`        | Matter server image tag         | `1.3.1`                                |

### Matter Server parameters

| Name             | Description                                                                                            | Value            |
|------------------|-----------------------------------------------------------------------------------------------------------|------------------|
| `logLevel`       | Log verbosity (`silly`, `debug`, `info`, `notice`, `warn`, `error`, `fatal`)                              | `info`           |
| `storagePath`    | Path inside the container where Matter commissioning data is persisted                                   | `/data`          |
| `productionMode` | Set `true` when accessed through a reverse proxy/ingress, so the dashboard connects to the WS server at the current URL instead of prompting for one | `false` |
| `fsGroup`        | Group ownership applied to the data PVC on mount (must match the image's runtime uid/gid, `1000`)         | `1000`           |
| `annotations`    | Pod-level annotations (AppArmor confinement disabled by default)                                          | See values.yaml  |
| `replicaCount`   | Number of replicas                                                                                         | `1`              |

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

| Name                 | Description                                                                    | Value       |
|----------------------|---------------------------------------------------------------------------------|-------------|
| `service.type`       | Kubernetes Service type                                                        | `ClusterIP` |
| `service.port`       | Matter WebSocket API + built-in dashboard port (used by Home Assistant and for browser access) | `5580` |
| `service.targetPort` | Port the server listens on inside the container                                | `5580`      |

### Scheduling parameters

| Name           | Description                    | Value |
|----------------|--------------------------------|-------|
| `nodeSelector` | Node labels for pod assignment | `{}`  |

### Resource parameters

| Name        | Description                                                     | Value |
|-------------|-------------------------------------------------------------------|-------|
| `resources` | Resource requests and limits for the Matter Server container    | `{}`  |

## Configuration and installation details

### Connecting Home Assistant

Point your Home Assistant Matter integration at the WebSocket service. If the release name is `my-release` and both are in the same namespace, the address is:

```
ws://my-release-svc:5580/ws
```

### Accessing the dashboard

The server ships a built-in web dashboard on the same port as the WebSocket API. Browse to `http://my-release-svc:5580` (or the node/host address if using `hostNetwork`). If it's exposed through a reverse proxy or ingress, set `productionMode: true` so the dashboard connects to the WS server automatically instead of prompting for an address.

### Host networking and AppArmor

Matter uses UDP multicast for device discovery and Bluetooth for commissioning. Both require host networking and an unconfined AppArmor profile. These are enabled by default — do not disable them without understanding the impact on device commissioning.

### Pinning to a specific node

Use `nodeSelector` to ensure the pod is scheduled on a node with the required Thread or Bluetooth radio:

```yaml
nodeSelector:
  kubernetes.io/hostname: my-node
```
