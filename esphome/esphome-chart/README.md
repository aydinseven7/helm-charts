# ESPHome Helm Chart

A Helm chart for deploying the [ESPHome](https://esphome.io) dashboard on Kubernetes.

## TL;DR

```bash
kubectl create secret generic esphome-dashboard-auth \
  --from-literal=USERNAME=admin \
  --from-literal=PASSWORD=changeme

helm install my-release ./esphome-chart
```

## Introduction

This chart bootstraps an ESPHome dashboard deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

ESPHome requires **host networking** so the dashboard can discover and communicate with ESP devices on the local network. Pin the pod to a node that has physical access to the target device network via `nodeSelector`.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure
- A Kubernetes Secret containing the dashboard credentials (see [Before you begin](#before-you-begin))

## Before you begin

Dashboard credentials are read from a pre-existing Secret so that passwords never appear in values files or Helm history. Create it before installing the chart:

```bash
kubectl create secret generic esphome-dashboard-auth \
  --from-literal=USERNAME=admin \
  --from-literal=PASSWORD=<your-password>
```

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm install my-release ./esphome-chart
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

| Name               | Description               | Value                      |
|--------------------|---------------------------|----------------------------|
| `image.repository` | ESPHome image repository  | `ghcr.io/esphome/esphome` |
| `image.tag`        | ESPHome image tag (`""` defaults to the chart's `appVersion`) | `""` |

### ESPHome parameters

| Name         | Description                                                                   | Value  |
|--------------|-------------------------------------------------------------------------------|--------|
| `secretName` | Name of a pre-existing Secret containing dashboard credentials (USERNAME, PASSWORD) | `""` |
| `logLevel`   | Log verbosity (`debug`, `info`, `warning`, `error`, `critical`)               | `info` |
| `replicaCount` | Number of ESPHome replicas                                                  | `1`    |

### Network parameters

| Name          | Description                                                        | Value                     |
|---------------|--------------------------------------------------------------------|---------------------------|
| `hostNetwork` | Enable host networking (required for device discovery)             | `true`                    |
| `dnsPolicy`   | DNS policy to use when host networking is enabled                  | `ClusterFirstWithHostNet` |

### Persistence parameters

| Name                       | Description                                                       | Value           |
|----------------------------|-------------------------------------------------------------------|-----------------|
| `persistence.enabled`      | Enable a PersistentVolumeClaim for ESPHome configuration files    | `true`          |
| `persistence.storageClass` | StorageClass for the config PVC (`""` uses the cluster default)   | `longhorn`      |
| `persistence.accessMode`   | PVC access mode                                                   | `ReadWriteOnce` |
| `persistence.size`         | Size of the config PVC                                            | `500Mi`         |

### Service parameters

| Name                 | Description                                 | Value       |
|----------------------|---------------------------------------------|-------------|
| `service.type`       | Kubernetes Service type                     | `ClusterIP` |
| `service.port`       | Service port                                | `80`        |
| `service.targetPort` | Port ESPHome listens on inside the container | `6052`     |

### Ingress parameters

| Name                       | Description                                          | Value                  |
|----------------------------|------------------------------------------------------|------------------------|
| `ingress.enabled`          | Enable an Ingress resource                           | `false`                |
| `ingress.ingressClassName` | IngressClass to use                                  | `traefik`              |
| `ingress.annotations`      | Additional annotations for the Ingress resource      | `{}`                   |
| `ingress.host`             | Hostname at which ESPHome will be served             | `esphome.example.com`  |
| `ingress.path`             | Path prefix for the Ingress rule                     | `/`                    |
| `ingress.tls`              | Enable TLS termination at the Ingress controller     | `true`                 |
| `ingress.tlsSecretName`    | Name of the TLS Secret (ignored when `tls: false`)   | `""`                   |

### Scheduling parameters

| Name           | Description                    | Value |
|----------------|--------------------------------|-------|
| `nodeSelector` | Node labels for pod assignment | `{}`  |

### Resource parameters

| Name        | Description                                              | Value |
|-------------|----------------------------------------------------------|-------|
| `resources` | Resource requests and limits for the ESPHome container   | `{}`  |

## Configuration and installation details

### Host networking

ESPHome uses mDNS and direct TCP connections to flash and monitor ESP devices. These require host networking — the pod shares the node's network namespace. Use `nodeSelector` to pin it to the node closest to your devices.

### Credentials Secret

The `secretName` value must reference a Secret with `USERNAME` and `PASSWORD` keys. The chart does not create this Secret automatically to avoid storing credentials in Helm history.

### Enabling Ingress

```yaml
ingress:
  enabled: true
  ingressClassName: traefik
  host: esphome.yourdomain.com
  tls: true
  tlsSecretName: esphome-tls
```
