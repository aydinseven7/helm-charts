# Dawarich

[Dawarich](https://github.com/Freika/dawarich) is a self-hosted location history tracker. It accepts location data from mobile apps (e.g. Overland, OwnTracks) and lets you browse, search, and analyse your travel history on an interactive map.

## TL;DR

```bash
helm install dawarich ./dawarich-helm-chart \
  --set ingress.host=dawarich.example.com \
  --set database.existingSecret.name=dawarich-postgres-secret \
  --set redis.host=redis://redis-master:6379
```

## Introduction

This chart deploys Dawarich on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

The deployment runs two containers in a single Pod:

- **web** – Rails server (`bin/rails server`), also serves the Prometheus metrics endpoint at `/metrics`
- **sidekiq** – Background job worker; runs its own in-process metrics exporter on `PROMETHEUS_EXPORTER_PORT`

Both containers share the same PersistentVolumes for uploads, watched imports, and public assets.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- A running PostgreSQL instance with the PostGIS extension (see the companion `postgis` chart)
- A running Redis instance (e.g. Bitnami Redis chart)
- A Kubernetes secret containing the database password (see [Database credentials](#database-credentials))

## Installing the Chart

```bash
helm install dawarich ./dawarich-helm-chart -f my-values.yaml
```

## Uninstalling the Chart

```bash
helm uninstall dawarich
```

Note: PersistentVolumeClaims are **not** deleted automatically. Remove them manually if no longer needed.

---

## Parameters

### Global parameters

| Name               | Description                                      | Value |
|--------------------|--------------------------------------------------|-------|
| `nameOverride`     | Override the chart name used in resource names   | `""`  |
| `fullnameOverride` | Override the fully qualified app name            | `""`  |

### Image parameters

| Name               | Description               | Value               |
|--------------------|---------------------------|---------------------|
| `image.repository` | Dawarich image repository                                    | `freikin/dawarich` |
| `image.tag`        | Dawarich image tag. Defaults to `Chart.AppVersion` when empty. | `""`             |

### Service parameters

| Name                   | Description                          | Value       |
|------------------------|--------------------------------------|-------------|
| `service.enabled`      | Enable the Kubernetes Service        | `true`      |
| `service.type`         | Service type                         | `ClusterIP` |
| `service.port`         | Service port                         | `3000`      |
| `service.targetPort`   | Container port traffic is routed to  | `3000`      |
| `service.protocol`     | Protocol used by the service         | `TCP`       |
| `service.annotations`  | Additional annotations for the Service | `{}`      |
| `service.labels`       | Additional labels for the Service    | `{}`        |

### Ingress parameters

| Name                       | Description                                       | Value                  |
|----------------------------|---------------------------------------------------|------------------------|
| `ingress.enabled`          | Enable Ingress                                    | `true`                 |
| `ingress.ingressClassName` | IngressClass to use                               | `""`                   |
| `ingress.host`             | Hostname the application is reachable at          | `dawarich.example.com` |
| `ingress.path`             | Path prefix for the ingress rule                  | `/`                    |
| `ingress.annotations`      | Additional annotations (e.g. nginx, cert-manager) | `{}`                   |
| `ingress.tls`              | TLS configuration block                           | `[]`                   |

### HTTPRoute parameters

| Name                    | Description                                                        | Value   |
|-------------------------|--------------------------------------------------------------------|---------|
| `httpRoute.enabled`     | Enable HTTPRoute (Gateway API). Mutually exclusive with `ingress`. | `false` |
| `httpRoute.annotations` | Additional annotations for the HTTPRoute                           | `{}`    |
| `httpRoute.parentRefs`  | List of Gateways this route attaches to                            | `[]`    |
| `httpRoute.hostnames`   | Hostnames to match. Falls back to `ingress.host` when empty.       | `[]`    |
| `httpRoute.extraRules`  | Additional rule entries appended to `spec.rules`                   | `[]`    |

### Application environment parameters

| Name                                    | Description                                                          | Value                  |
|-----------------------------------------|----------------------------------------------------------------------|------------------------|
| `env.RAILS_ENV`                         | Rails environment (`production` or `development`)                    | `production`           |
| `env.APPLICATION_HOSTS`                 | Comma-separated list of hostnames Rails accepts requests for         | `dawarich.example.com` |
| `env.RAILS_APPLICATION_CONFIG_HOSTS`    | Additional trusted hosts. Defaults to `ingress.host` when empty.     | `""`                   |
| `env.APPLICATION_PROTOCOL`             | Protocol the app is served over (`http` or `https`)                  | `http`                 |
| `env.BACKGROUND_PROCESSING_CONCURRENCY` | Number of concurrent Sidekiq workers                                 | `10`                   |
| `env.STORE_GEODATA`                     | Persist downloaded reverse-geocoding data locally                    | `true`                 |
| `env.timeZone`                          | Rails time zone string (e.g. `Europe/Berlin`)                        | `UTC`                  |
| `env.PROMETHEUS_EXPORTER_ENABLED`       | Enable the Prometheus metrics endpoint on the web container          | `false`                |
| `env.PROMETHEUS_EXPORTER_PORT`          | Port the in-process Sidekiq metrics exporter binds to                | `9394`                 |
| `env.SIDEKIQ_METRICS_URL`               | URL the web container fetches Sidekiq metrics from. Override when Sidekiq's hostname differs from the docker-compose default (e.g. set `http://localhost:9394/metrics` on Kubernetes). | `http://localhost:9394/metrics` |

### SMTP parameters

| Name                        | Description                                               | Value              |
|-----------------------------|-----------------------------------------------------------|--------------------|
| `smtp.address`              | SMTP server hostname                                      | `smtp.example.com` |
| `smtp.port`                 | SMTP server port                                          | `587`              |
| `smtp.domain`               | SMTP HELO domain                                          | `example.com`      |
| `smtp.username`             | SMTP login username                                       | `user@example.com` |
| `smtp.password`             | SMTP password (ignored when `existingSecret.name` is set) | `""`               |
| `smtp.existingSecret.name`  | Name of the Secret containing the SMTP password           | `dawarich-secret`  |
| `smtp.existingSecret.key`   | Key within the secret for the SMTP password               | `smtp-password`    |

### Database parameters

| Name                           | Description                                              | Value                      |
|--------------------------------|----------------------------------------------------------|----------------------------|
| `database.host`                | PostgreSQL host                                          | `postgis`                  |
| `database.username`            | PostgreSQL username                                      | `postgres`                 |
| `database.name`                | PostgreSQL database name                                 | `dawarich`                 |
| `database.password`            | Database password (ignored when `existingSecret` is set) | `""`                       |
| `database.existingSecret.name` | Name of the secret containing the database password      | `dawarich-postgres-secret` |
| `database.existingSecret.key`  | Key within the secret for the password                   | `password`                 |

### Redis parameters

| Name         | Description          | Value                       |
|--------------|----------------------|-----------------------------|
| `redis.host` | Redis connection URL | `redis://redis-master:6379` |

### Resource parameters

| Name        | Description                                        | Value |
|-------------|----------------------------------------------------|-------|
| `resources` | CPU/memory requests and limits for both containers | `{}`  |

### Metrics parameters

| Name                                        | Description                                                                                                  | Value                           |
|---------------------------------------------|--------------------------------------------------------------------------------------------------------------|---------------------------------|
| `metrics.enabled`                           | Enable Prometheus metrics (`PROMETHEUS_EXPORTER_ENABLED`) and render the ServiceMonitor                      | `false`                         |
| `metrics.serviceMonitor.enabled`            | Create a `ServiceMonitor` resource (requires `metrics.enabled` and the Prometheus Operator CRD)              | `false`                         |
| `metrics.serviceMonitor.namespace`          | Namespace to deploy the ServiceMonitor into. Defaults to the release namespace.                              | `""`                            |
| `metrics.serviceMonitor.interval`           | Scrape interval                                                                                              | `30s`                           |
| `metrics.serviceMonitor.scrapeTimeout`      | Scrape timeout. Empty uses the global Prometheus default.                                                    | `""`                            |
| `metrics.serviceMonitor.honorLabels`        | When true, preserves metric labels that collide with target labels                                           | `false`                         |
| `metrics.serviceMonitor.relabelings`        | RelabelConfigs to apply to samples before scraping                                                           | `[]`                            |
| `metrics.serviceMonitor.metricRelabelings`  | MetricRelabelConfigs to apply to samples before ingestion                                                    | `[]`                            |
| `metrics.serviceMonitor.selector`           | Labels added to the ServiceMonitor metadata for operator discovery (e.g. `release: kube-prometheus-stack`). Leave empty if your operator discovers all ServiceMonitors in the namespace. | `{}` |
| `metrics.serviceMonitor.additionalLabels`   | Additional labels added to the ServiceMonitor metadata                                                       | `{}`                            |
| `metrics.serviceMonitor.annotations`        | Annotations added to the ServiceMonitor metadata                                                             | `{}`                            |
| `metrics.serviceMonitor.scheme`             | Endpoint scheme. Empty defaults to `http`.                                                                   | `""`                            |
| `metrics.serviceMonitor.tlsConfig`          | TLS configuration for the scrape endpoint                                                                    | `{}`                            |
| `metrics.serviceMonitor.credentialsSecret`  | Name of the Secret containing `metrics-username` and `metrics-password` keys for basic auth. Leave empty to disable basic auth. | `""` |

### Persistence parameters

| Name                              | Description                             | Value           |
|-----------------------------------|-----------------------------------------|-----------------|
| `persistence.watched.enabled`     | Enable PVC for watched import files     | `true`          |
| `persistence.watched.size`        | Size of the watched files PVC           | `1Gi`           |
| `persistence.watched.storageClass`| Storage class (empty = cluster default) | `""`            |
| `persistence.watched.accessMode`  | PVC access mode                         | `ReadWriteOnce` |
| `persistence.public.enabled`      | Enable PVC for public assets            | `true`          |
| `persistence.public.size`         | Size of the public assets PVC           | `1Gi`           |
| `persistence.public.storageClass` | Storage class (empty = cluster default) | `""`            |
| `persistence.public.accessMode`   | PVC access mode                         | `ReadWriteOnce` |
| `persistence.storage.enabled`     | Enable PVC for Active Storage uploads   | `true`          |
| `persistence.storage.size`        | Size of the storage PVC                 | `1Gi`           |
| `persistence.storage.storageClass`| Storage class (empty = cluster default) | `""`            |
| `persistence.storage.accessMode`  | PVC access mode                         | `ReadWriteOnce` |
| `persistence.db.enabled`          | Enable PVC for database data directory  | `true`          |
| `persistence.db.size`             | Size of the database PVC                | `5Gi`           |
| `persistence.db.storageClass`     | Storage class (empty = cluster default) | `""`            |
| `persistence.db.accessMode`       | PVC access mode                         | `ReadWriteOnce` |

---

## Configuration and installation details

### Ingress vs HTTPRoute

The chart supports two mutually exclusive ways to expose the application:

- **Ingress** (`ingress.enabled: true`) — standard `networking.k8s.io/v1` Ingress, compatible with any ingress controller.
- **HTTPRoute** (`httpRoute.enabled: true`) — Kubernetes Gateway API `HTTPRoute`. Requires a Gateway API-compatible controller (e.g. Envoy Gateway, Istio, Cilium) and the Gateway API CRDs installed in the cluster.

Enable at most one at a time. A minimal HTTPRoute configuration:

```yaml
ingress:
  enabled: false

httpRoute:
  enabled: true
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
  hostnames:
    - dawarich.example.com
```

If `httpRoute.hostnames` is left empty, the chart falls back to `ingress.host`.

Use `extraRules` to append additional entries to `spec.rules`, for example to route a second path to a different backend:

```yaml
httpRoute:
  extraRules:
    - matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: my-api-svc
          port: 8080
```

### Database credentials

The chart reads the database password from a Kubernetes Secret rather than storing it in plain text. Create the secret before installing the chart:

```bash
kubectl create secret generic dawarich-postgres-secret \
  --from-literal=password=my-db-password \
  --namespace dawarich
```

Then reference it in your values:

```yaml
database:
  existingSecret:
    name: dawarich-postgres-secret
    key: password
```

If you do not use an existing secret, you can set `database.password` directly — though this is not recommended for production.

### SMTP / email configuration

Dawarich can send emails (e.g. password resets) via SMTP. The SMTP password is read from a Kubernetes Secret to avoid storing credentials in values files.

Create the secret:

```bash
kubectl create secret generic dawarich-secret \
  --from-literal=smtp-password=my-smtp-password \
  --namespace dawarich
```

Then configure SMTP in your values:

```yaml
smtp:
  address: smtp.example.com
  port: 587
  domain: example.com
  username: user@example.com
  existingSecret:
    name: dawarich-secret
    key: smtp-password
```

Alternatively, set `smtp.password` directly (not recommended for production):

```yaml
smtp:
  address: smtp.example.com
  port: 587
  domain: example.com
  username: user@example.com
  password: my-smtp-password
```

SMTP is optional. If left unconfigured, email sending will fail silently; all other functionality will work normally.

### Application environment (`env`)

The `env` block populates a ConfigMap that is loaded by both the web and Sidekiq containers. Key fields to configure:

- **`APPLICATION_HOSTS`** and **`RAILS_APPLICATION_CONFIG_HOSTS`** must include every hostname the app is reachable at, or Rails will reject the request with a `blocked host` error. `RAILS_APPLICATION_CONFIG_HOSTS` defaults to `ingress.host` when left empty.
- **`RAILS_ENV`** should be `production` for real deployments. Using `development` enables more verbose logging and disables some caching.
- **`STORE_GEODATA`** controls whether reverse-geocoding data is cached locally. Set to `false` to rely solely on external APIs.
- **`timeZone`** accepts any [Rails time zone string](https://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html) (e.g. `Europe/Berlin`, `America/New_York`).

### Ingress

The Ingress resource is enabled by default. When using a TLS termination proxy upstream (e.g. Cloudflare Tunnel), leave `ingress.tls` empty and set `APPLICATION_PROTOCOL: http`. When terminating TLS at the ingress controller, add a TLS block and set `APPLICATION_PROTOCOL: https`:

```yaml
ingress:
  tls:
    - secretName: dawarich-tls
      hosts:
        - dawarich.example.com
env:
  APPLICATION_PROTOCOL: https
```

### Metrics and ServiceMonitor

Since Dawarich 1.7.7, metrics are served in-process by each application:

- The **web container** exposes a Prometheus-compatible endpoint at `/metrics` on its main port (3000), aggregating both web and Sidekiq metrics.
- The **Sidekiq container** runs its own in-process metrics exporter on `PROMETHEUS_EXPORTER_PORT` (default `9394`). The web container fetches these internally via `SIDEKIQ_METRICS_URL`.

To enable metrics, set `metrics.enabled: true`. This sets `PROMETHEUS_EXPORTER_ENABLED=true` on both containers. On Kubernetes, `SIDEKIQ_METRICS_URL` defaults to `http://localhost:9394/metrics` since both containers share a Pod and are reachable via localhost.

To also create a `ServiceMonitor` for the Prometheus Operator (or VictoriaMetrics VMAgent):

```yaml
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
    credentialsSecret: dawarich-secret
```

The `ServiceMonitor` is only rendered when the `monitoring.coreos.com/v1` CRD is present in the cluster.

#### Metrics basic auth

Dawarich 1.7.7 introduced `METRICS_USERNAME` and `METRICS_PASSWORD` to protect the `/metrics` endpoint. When `metrics.serviceMonitor.credentialsSecret` is set, the chart:

1. Injects `METRICS_USERNAME` and `METRICS_PASSWORD` into the web container from the named Secret.
2. Configures `basicAuth` on the ServiceMonitor endpoint so the scraper authenticates correctly.

Add the credentials to your secret before enabling:

```bash
kubectl create secret generic dawarich-secret \
  --from-literal=smtp-password=my-smtp-password \
  --from-literal=metrics-username=prometheus \
  --from-literal=metrics-password=my-metrics-password \
  --namespace dawarich
```

#### ServiceMonitor operator discovery

By default `metrics.serviceMonitor.selector` is empty, which works when the Prometheus Operator or VMAgent is configured to discover all ServiceMonitors in the namespace. If your operator uses a label-based `serviceMonitorSelector` (common with `kube-prometheus-stack`), add the required label:

```yaml
metrics:
  serviceMonitor:
    selector:
      release: kube-prometheus-stack
```

### Resource requests and limits

`resources` applies to **both** the web container and the Sidekiq container. Recommended starting values for a small instance:

```yaml
resources:
  limits:
    cpu: 1
    memory: 1Gi
  requests:
    cpu: 50m
    memory: 128Mi
```
