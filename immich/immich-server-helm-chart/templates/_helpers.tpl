{{/*
Expand the name of the chart.
*/}}
{{- define "immich-server.name" -}}
{{- .Chart.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "immich-server.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the chart label value (name-version).
*/}}
{{- define "immich-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "immich-server.labels" -}}
helm.sh/chart: {{ include "immich-server.chart" . }}
{{ include "immich-server.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for the Immich server Deployment and Service.
*/}}
{{- define "immich-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "immich-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: server
{{- end }}

{{/*
Selector labels for the Machine Learning Deployment and Service.
Component differs so both can coexist in the same release.
*/}}
{{- define "immich-ml.selectorLabels" -}}
app.kubernetes.io/name: {{ include "immich-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: machine-learning
{{- end }}

{{/*
Common labels for the Machine Learning Deployment metadata.
*/}}
{{- define "immich-ml.labels" -}}
helm.sh/chart: {{ include "immich-server.chart" . }}
{{ include "immich-ml.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Name of the bundled CNPG Cluster. Mirrors the cloudnative-pg "cluster" chart's
own cluster.fullname helper, where the chart name is the dependency alias "cnpg".
*/}}
{{- define "immich-server.cnpg.fullname" -}}
{{- if .Values.cnpg.fullnameOverride }}
{{- .Values.cnpg.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "cnpg" .Values.cnpg.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Database host — databaseHost when set, otherwise the CNPG Cluster's read-write Service.
*/}}
{{- define "immich-server.database.host" -}}
{{- if .Values.databaseHost }}
{{- .Values.databaseHost }}
{{- else if .Values.cnpg.enabled }}
{{- printf "%s-rw" (include "immich-server.cnpg.fullname" .) }}
{{- else }}
{{- fail "databaseHost is required when cnpg.enabled is false" }}
{{- end }}
{{- end }}

{{/*
Secret holding a database credential. Takes (list $ <configured secretName>):
the configured name when set, otherwise the CNPG app secret — which is
cnpg.cluster.initdb.secret.name when set, since CNPG then uses that secret
instead of generating "<cluster>-app".
*/}}
{{- define "immich-server.database.secretName" -}}
{{- $root := index . 0 }}
{{- $name := index . 1 }}
{{- if $name }}
{{- $name }}
{{- else if $root.Values.cnpg.enabled }}
{{- dig "cluster" "initdb" "secret" "name" "" $root.Values.cnpg | default (printf "%s-app" (include "immich-server.cnpg.fullname" $root)) }}
{{- else }}
{{- fail "postgresUser.secretName and postgresPassword.secretName are required when cnpg.enabled is false" }}
{{- end }}
{{- end }}

{{/*
Name of the bundled Valkey Service. Mirrors the valkey chart's own
valkey.fullname helper.
*/}}
{{- define "immich-server.valkey.fullname" -}}
{{- if .Values.valkey.fullnameOverride }}
{{- .Values.valkey.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "valkey" .Values.valkey.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Redis host — redisHost when set, otherwise the bundled Valkey Service.
*/}}
{{- define "immich-server.redis.host" -}}
{{- if .Values.redisHost }}
{{- .Values.redisHost }}
{{- else if .Values.valkey.enabled }}
{{- include "immich-server.valkey.fullname" . }}
{{- else }}
{{- fail "redisHost is required when valkey.enabled is false" }}
{{- end }}
{{- end }}
