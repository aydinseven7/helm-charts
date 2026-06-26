{{/*
Expand the name of the chart.
*/}}
{{- define "airtrail.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Full app name.
*/}}
{{- define "airtrail.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "airtrail.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for the airtrail app (used for matchLabels/selector and
duplicated onto resource labels).
*/}}
{{- define "airtrail.selectorLabels" -}}
app.kubernetes.io/name: {{ include "airtrail.fullname" . }}
app.kubernetes.io/component: app
{{- end }}

{{/*
Name of the CNPG Cluster resource (created by this chart, or an existing one).
*/}}
{{- define "airtrail.cnpgClusterName" -}}
{{- if .Values.postgresql.existingCluster }}
{{- .Values.postgresql.existingCluster }}
{{- else if .Values.postgresql.clusterName }}
{{- .Values.postgresql.clusterName }}
{{- else }}
{{- printf "%s-db" (include "airtrail.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Name of the secret holding connection credentials (including the ready-to-use
"uri" key) - either CNPG's generated "-app" secret, or postgresql.existingSecret
when set, since CNPG uses it as the app secret directly instead of generating
one of its own.
*/}}
{{- define "airtrail.cnpgSecretName" -}}
{{- if .Values.postgresql.existingSecret }}
{{- .Values.postgresql.existingSecret }}
{{- else }}
{{- printf "%s-app" (include "airtrail.cnpgClusterName" .) }}
{{- end }}
{{- end }}

{{/*
Sanity checks on values. Fails the render with a clear message instead of
producing manifests that would only break at apply/runtime.
*/}}
{{- define "airtrail.validateValues" -}}
{{- if and .Values.postgresql.create .Values.postgresql.existingCluster }}
{{- fail "postgresql.create and postgresql.existingCluster are mutually exclusive - set postgresql.create to false when pointing at an existing cluster" }}
{{- end }}
{{- if and (not .Values.postgresql.create) (not .Values.postgresql.existingCluster) }}
{{- fail "no postgresql cluster configured - set postgresql.create to true or provide postgresql.existingCluster" }}
{{- end }}
{{- if and .Values.postgresql.existingSecret .Values.postgresql.existingCluster }}
{{- fail "postgresql.existingSecret only applies when this chart creates the Cluster - it has no effect when postgresql.existingCluster is set" }}
{{- end }}
{{- if and .Values.httpRoute.enabled (not .Values.httpRoute.parentRefs) }}
{{- fail "httpRoute.enabled is true but httpRoute.parentRefs is empty - an HTTPRoute needs at least one parentRef" }}
{{- end }}
{{- end }}
