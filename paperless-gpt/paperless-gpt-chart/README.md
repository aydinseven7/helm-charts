# paperless-gpt Helm Chart

A Helm chart for deploying [paperless-gpt](https://github.com/icereed/paperless-gpt) on Kubernetes — an LLM-powered assistant for [paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) that generates OCR text, titles, tags, correspondents, and other metadata for scanned documents.

## TL;DR

```bash
kubectl create secret generic paperless-gpt-secrets \
  --from-literal=PAPERLESS_API_TOKEN=<your-paperless-ngx-api-token>

helm install my-release ./paperless-gpt-chart \
  --set secretName=paperless-gpt-secrets \
  --set paperless.baseUrl=https://paperless.example.com
```

## Introduction

This chart bootstraps a paperless-gpt deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

paperless-gpt polls paperless-ngx for documents tagged with its trigger tag(s) and uses a configured LLM (Ollama, OpenAI, Anthropic, Mistral, or Google AI) to OCR scanned pages and suggest titles, tags, correspondents, and other metadata. Suggestions can be reviewed manually or applied automatically once you trust the output.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8.0+
- PV provisioner support in the underlying infrastructure
- A paperless-ngx instance and API token
- An LLM backend (e.g. a reachable Ollama server, or an API key for a cloud provider)

## Before you begin

Sensitive values — the paperless-ngx API token and any LLM provider API keys — are read from a pre-existing Secret so they never appear in values files or Helm history. Create it before installing the chart, with one key per env var paperless-gpt expects:

```bash
kubectl create secret generic paperless-gpt-secrets \
  --from-literal=PAPERLESS_API_TOKEN=<your-paperless-ngx-api-token>
  # add more --from-literal flags for provider keys if needed, e.g.:
  # --from-literal=OPENAI_API_KEY=<your-key>
```

Then point the chart at it via `secretName`.

## Installing the Chart

To install the chart with the release name `my-release`:

```bash
helm install my-release ./paperless-gpt-chart
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
helm uninstall my-release
```

> **Note:** PersistentVolumeClaims created by the chart are **not** deleted automatically. To remove them:
> ```bash
> kubectl delete pvc my-release-prompts
> ```

## Parameters

### Image parameters

| Name               | Description                    | Value                 |
|--------------------|----------------------------------|------------------------|
| `image.repository` | paperless-gpt image repository | `icereed/paperless-gpt` |
| `image.tag`        | paperless-gpt image tag (`""` defaults to the chart's `appVersion`) | `""` |
| `replicaCount`     | Number of replicas             | `1`                    |

### Secret parameters

| Name         | Description                                                                 | Value |
|--------------|------------------------------------------------------------------------------|-------|
| `secretName` | Pre-existing Secret exposed via `envFrom`; must contain `PAPERLESS_API_TOKEN` plus any provider API keys you use | `""` |

### Paperless-ngx connection parameters

| Name                  | Description                                                       | Value |
|-----------------------|---------------------------------------------------------------------|-------|
| `paperless.baseUrl`   | Base URL of the paperless-ngx instance                             | `""`  |
| `paperless.publicUrl` | Public URL used to generate links back to paperless-ngx (`""` uses `baseUrl`) | `""` |

### Tagging parameters

| Name                   | Description                                                        | Value            |
|------------------------|-----------------------------------------------------------------------|------------------|
| `tagging.manualTag`    | Tag that triggers manual (review-before-apply) suggestions            | `paperless-gpt` |
| `tagging.autoTag`      | Tag that triggers fully automatic metadata tagging (`""` disables)    | `""`             |
| `tagging.autoOcrTag`   | Tag that triggers fully automatic OCR (`""` disables)                 | `""`             |

Stay on `manualTag` only until your test batch reject rate looks acceptable before enabling either auto tag.

### LLM parameters

| Name             | Description                                                        | Value    |
|------------------|-----------------------------------------------------------------------|----------|
| `llm.provider`   | Text LLM provider (`ollama`, `openai`, `anthropic`, `mistral`, `googleai`) | `ollama` |
| `llm.model`      | Text LLM model name                                                | `""`     |
| `llm.language`   | Language paperless-gpt should respond in (`""` uses the app default) | `""`  |
| `ocr.provider`   | OCR backend (`llm`, `azure`, `google_docai`, `docling`)            | `llm`    |
| `vision.provider`| Vision LLM provider used for OCR                                  | `ollama` |
| `vision.model`   | Vision LLM model name                                              | `""`     |
| `vision.temperature` | Vision LLM sampling temperature                                | `0.2`    |
| `vision.maxTokens`   | Vision LLM max output tokens                                    | `2500`   |

### Ollama parameters

| Name                     | Description                                        | Value  |
|--------------------------|-------------------------------------------------------|--------|
| `ollama.host`            | Ollama server URL (`""` leaves `OLLAMA_HOST` unset)    | `""`   |
| `ollama.contextLength`   | Ollama context window size (sets `NumCtx`)             | `8192` |
| `tokenLimit`             | Max tokens of document content sent to the text LLM    | `3000` |
| `imageMaxRenderDpi`      | DPI used when rendering PDF pages for vision OCR       | `250`  |

### PDF safety parameters

| Name           | Description                                                    | Value   |
|----------------|--------------------------------------------------------------------|---------|
| `pdf.upload`   | Allow paperless-gpt to upload OCR'd PDFs back to paperless-ngx     | `false` |
| `pdf.replace`  | Allow paperless-gpt to replace the original PDF with the OCR'd one | `false` |
| `logLevel`     | Log verbosity (`debug`, `info`, `warn`, `error`)                   | `info`  |

Leave both `pdf.*` flags off until you trust the OCR/tagging output on a test batch.

### Persistence parameters

| Name                        | Description                                                                 | Value           |
|-----------------------------|--------------------------------------------------------------------------------|-----------------|
| `persistence.enabled`       | Enable a PersistentVolumeClaim for `/app/prompts`                              | `true`          |
| `persistence.existingClaim` | Use an existing PVC instead of creating one (other `persistence.*` fields ignored) | `""`         |
| `persistence.storageClass`  | StorageClass for the prompts PVC (`""` uses the cluster default)               | `longhorn`      |
| `persistence.accessMode`    | PVC access mode                                                                 | `ReadWriteOnce` |
| `persistence.size`          | Size of the prompts PVC                                                        | `100Mi`         |
| `persistence.extraLabels`   | Extra labels for the PersistentVolumeClaim                                     | `{}`            |
| `persistence.annotations`   | Annotations for the PersistentVolumeClaim                                      | `{}`            |

paperless-gpt saves prompt edits made through its UI back to `/app/prompts` at runtime, so this volume must stay writable and persistent — it isn't just a config mount.

### Service parameters

| Name                  | Description                                     | Value       |
|-----------------------|----------------------------------------------------|-------------|
| `service.type`        | Kubernetes Service type                            | `ClusterIP` |
| `service.port`        | Service port                                       | `8080`      |
| `service.targetPort`  | Port paperless-gpt listens on inside the container | `8080`      |
| `service.extraLabels` | Extra labels for the Service                       | `{}`        |
| `service.annotations` | Annotations for the Service                        | `{}`        |

### Ingress parameters

| Name                  | Description                                     | Value                       |
|-----------------------|-----------------------------------------------------|------------------------------|
| `ingress.enabled`     | Enable a classic Ingress resource                   | `false`                     |
| `ingress.className`   | IngressClass to use                                 | `""`                        |
| `ingress.annotations` | Additional annotations for the Ingress resource     | `{}`                        |
| `ingress.hosts`       | Ingress host/path rules                             | See `values.yaml`           |
| `ingress.tls`         | TLS configuration for the Ingress resource          | `[]`                        |

### HTTPRoute parameters

| Name                     | Description                                                      | Value |
|--------------------------|----------------------------------------------------------------------|-------|
| `httpRoute.enabled`      | Create a Gateway API HTTPRoute instead of a classic Ingress          | `false` |
| `httpRoute.parentRefs`   | Gateway API parentRefs pointing at your Gateway                     | `[]`  |
| `httpRoute.hostnames`    | Hostnames to route to this service                                  | See `values.yaml` |
| `httpRoute.annotations`  | Annotations for the HTTPRoute                                       | `{}`  |
| `httpRoute.rules`        | Gateway API match/filter rules                                      | See `values.yaml` |

### Scheduling parameters

| Name           | Description                     | Value |
|----------------|----------------------------------|-------|
| `nodeSelector` | Node labels for pod assignment  | `{}`  |
| `tolerations`  | Tolerations for pod assignment  | `[]`  |
| `affinity`     | Affinity rules for pod assignment | `{}` |

### Resource parameters

| Name        | Description                                                  | Value |
|-------------|------------------------------------------------------------------|-------|
| `resources` | Resource requests and limits for the paperless-gpt container    | `{}`  |
| `extraEnv`  | Extra environment variables appended to the container as-is     | `[]`  |

## Configuration and installation details

### Using Ollama

By default `llm.provider` and `vision.provider` are both `ollama`. Set `ollama.host` to your Ollama server (e.g. `http://host.docker.internal:11434` on the same node, or a Service DNS name if Ollama runs in-cluster), and `llm.model` / `vision.model` to a model you've pulled (a single vision-capable model such as `qwen2.5vl:7b` can serve both roles).

### Using a cloud LLM provider

Set `llm.provider` (and `vision.provider` if using LLM-based OCR) to `openai`, `anthropic`, `mistral`, or `googleai`, set the corresponding `*.model`, and add the provider's API key to the Secret referenced by `secretName` (e.g. `OPENAI_API_KEY`).

### Enabling automatic tagging

Start with only `tagging.manualTag` set and review suggestions in the paperless-gpt UI. Once you're confident in the output quality, set `tagging.autoTag` and/or `tagging.autoOcrTag` to have matching documents processed without review.

### Enabling Ingress or HTTPRoute

Only one of `ingress` or `httpRoute` should be enabled at a time.

```yaml
ingress:
  enabled: true
  className: traefik
  hosts:
    - host: paperless-gpt.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
```

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
  hostnames:
    - paperless-gpt.yourdomain.com
```
