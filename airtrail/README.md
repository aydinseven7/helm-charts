# AirTrail

[AirTrail](https://github.com/JohanOhly/AirTrail) is a modern, open-source personal flight tracking system. This chart bootstraps an AirTrail deployment on a Kubernetes cluster using the Helm package manager.

## TL;DR

```console
helm install my-release . \
  --set airtrail.origin=https://airtrail.example.com
```

## Introduction

This chart deploys [AirTrail](https://airtrail.johan.ohly.dk) on a Kubernetes cluster. It can optionally provision its own PostgreSQL database via the [CloudNativePG](https://cloudnative-pg.io/) operator, and exposes the app through a classic `Ingress` or a Gateway API `HTTPRoute`.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- The [CloudNativePG operator](https://cloudnative-pg.io/documentation/current/installation_upgrade/) installed in the cluster, if `postgresql.create=true` (the default) or if pointing at an existing CNPG `Cluster`
- The [Gateway API CRDs](https://gateway-api.sigs.k8s.io/guides/) installed in the cluster, if `httpRoute.enabled=true`

## Installing the Chart

To install the chart with the release name `my-release`:

```console
helm install my-release .
```

These commands deploy AirTrail on the Kubernetes cluster with default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
helm uninstall my-release
```

This removes all the Kubernetes components associated with the chart, including the CNPG `Cluster` (if `postgresql.create=true`). The underlying PersistentVolumes are not deleted unless their reclaim policy is set to `Delete`.

## Parameters

### AirTrail application parameters

| Name                            | Description                                                                  | Value             |
| -------------------------------- | ----------------------------------------------------------------------------- | ----------------- |
| `airtrail.image.repository`      | AirTrail image repository                                                    | `johly/airtrail`  |
| `airtrail.image.tag`             | AirTrail image tag                                                           | `latest`          |
| `airtrail.image.pullPolicy`      | AirTrail image pull policy                                                   | `IfNotPresent`    |
| `airtrail.replicaCount`          | Number of AirTrail replicas to deploy                                        | `1`               |
| `airtrail.service.type`          | AirTrail service type                                                        | `ClusterIP`       |
| `airtrail.service.port`          | AirTrail service HTTP port                                                   | `3000`            |
| `airtrail.origin`                | Externally reachable origin(s) for the app (comma separated for multiple)    | `http://localhost:3000` |
| `airtrail.resources`             | AirTrail container resource requests/limits                                  | `{}`              |
| `airtrail.nodeSelector`          | Node labels for AirTrail pod assignment                                      | `{}`              |
| `airtrail.tolerations`           | Tolerations for AirTrail pod assignment                                      | `[]`              |
| `airtrail.affinity`              | Affinity for AirTrail pod assignment                                         | `{}`              |
| `extraEnv`                       | Extra environment variables appended to the AirTrail container as-is        | `[]`              |

### Uploads persistence parameters

| Name                                  | Description                                                              | Value          |
| -------------------------------------- | -------------------------------------------------------------------------- | -------------- |
| `airtrail.uploads.enabled`             | Enable persistence for uploaded files                                    | `true`         |
| `airtrail.uploads.existingClaim`       | Name of an existing PVC to use instead of creating one                   | `""`           |
| `airtrail.uploads.storageClass`        | PVC storage class                                                        | `""`           |
| `airtrail.uploads.size`                | PVC requested size                                                       | `2Gi`          |
| `airtrail.uploads.uploadLocation`      | In-container path used both as the volume mount path and `UPLOAD_LOCATION` env var | `/app/uploads` |

### PostgreSQL (CloudNativePG) parameters

| Name                                | Description                                                                                          | Value      |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------ | ---------- |
| `postgresql.create`                  | Create a CNPG `Cluster` resource for AirTrail. Mutually exclusive with `postgresql.existingCluster`  | `true`     |
| `postgresql.clusterName`             | Name of the `Cluster` resource to create. Defaults to `<release>-db`                                  | `""`       |
| `postgresql.existingCluster`         | Name of an existing CNPG `Cluster` to use instead of creating one                                    | `""`       |
| `postgresql.instances`               | Number of instances in the created `Cluster`                                                         | `1`        |
| `postgresql.imageName`               | Pin a specific postgres image used by the operator, e.g. `ghcr.io/cloudnative-pg/postgresql:16.4`    | `""`       |
| `postgresql.storage.size`            | Size of the storage volume for the created `Cluster`                                                 | `5Gi`      |
| `postgresql.storage.storageClass`    | Storage class for the created `Cluster`                                                              | `""`       |
| `postgresql.database`                | Database name created on first bootstrap                                                             | `airtrail` |
| `postgresql.owner`                   | Database owner role created on first bootstrap                                                       | `airtrail` |
| `postgresql.resources`               | Resource requests/limits for the `Cluster` pods                                                      | `{}`       |

> **Note**: Exactly one of `postgresql.create` or `postgresql.existingCluster` must be set; the chart fails the render otherwise (see [templates/checks.yaml](templates/checks.yaml)).

### Ingress parameters

| Name                     | Description                                              | Value                    |
| ------------------------- | ----------------------------------------------------------- | ------------------------ |
| `ingress.enabled`         | Enable ingress record generation for AirTrail             | `false`                  |
| `ingress.className`      | IngressClass to use for the Ingress record                | `""`                     |
| `ingress.annotations`    | Additional annotations for the Ingress resource            | `{}`                     |
| `ingress.hosts`          | List of hosts and paths routed to AirTrail                | `[{host: airtrail.example.com, paths: [...]}]` |
| `ingress.tls`            | TLS configuration for the Ingress resource                 | `[]`                     |

### Gateway API HTTPRoute parameters

| Name                       | Description                                                                          | Value                                |
| --------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------- |
| `httpRoute.enabled`         | Enable `HTTPRoute` generation for AirTrail (alternative to `ingress`)                  | `false`                               |
| `httpRoute.annotations`    | Additional annotations for the `HTTPRoute` resource                                    | `{}`                                  |
| `httpRoute.parentRefs`     | Gateway API `parentRefs` the route attaches to. Required when `httpRoute.enabled=true` | `[]`                                  |
| `httpRoute.hostnames`      | Hostnames matched by the route                                                         | `[airtrail.example.com]`              |
| `httpRoute.rules`          | Routing rules (matches/backendRefs are wired to the AirTrail service automatically)    | `[{matches: [{path: {type: PathPrefix, value: /}}]}]` |

## Configuration and installation details

### Bring your own PostgreSQL cluster

If you already manage a CloudNativePG `Cluster` (or any Postgres exposing a compatible `-app` secret), set:

```console
helm install my-release . \
  --set postgresql.create=false \
  --set postgresql.existingCluster=my-existing-cluster
```

The chart reads connection details from the `<cluster-name>-app` Secret's `uri` key, matching CNPG's generated application secret format.

### Exposing AirTrail

Pick one of `ingress` or `httpRoute` depending on what's available in your cluster - both default to disabled, leaving the `Service` reachable only inside the cluster (or via `kubectl port-forward`, see `helm install` notes).

### Persistence

By default the chart creates a PVC for uploaded files (`airtrail.uploads.enabled=true`). Set `airtrail.uploads.existingClaim` to reuse a PVC you manage yourself, or set `airtrail.uploads.enabled=false` to use ephemeral storage (not recommended outside of testing).

## License

This chart packages [AirTrail](https://github.com/JohanOhly/AirTrail), licensed separately by its authors. See the chart's [LICENSE](LICENSE) file for the chart's own license.
