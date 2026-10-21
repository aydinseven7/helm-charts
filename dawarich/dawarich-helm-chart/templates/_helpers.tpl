{{/*
Expand the name of the chart.
*/}}
{{- define "dawarich.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dawarich.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart label value (name + version).
*/}}
{{- define "dawarich.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to all resources.
*/}}
{{- define "dawarich.labels" -}}
helm.sh/chart: {{ include "dawarich.chart" . }}
{{ include "dawarich.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Image tag — uses .Values.image.tag when set, otherwise falls back to Chart.AppVersion.
*/}}
{{- define "dawarich.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion }}
{{- end }}

{{/*
Selector labels — used on Deployments and Services. Must stay stable after first deploy.
*/}}
{{- define "dawarich.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dawarich.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the bundled CNPG Cluster. Mirrors the cloudnative-pg "cluster" chart's
own cluster.fullname helper, where the chart name is the dependency alias "cnpg".
*/}}
{{- define "dawarich.cnpg.fullname" -}}
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
Database host — database.host when set, otherwise the CNPG Cluster's read-write Service.
*/}}
{{- define "dawarich.database.host" -}}
{{- if .Values.database.host }}
{{- .Values.database.host }}
{{- else if .Values.cnpg.enabled }}
{{- printf "%s-rw" (include "dawarich.cnpg.fullname" .) }}
{{- else }}
{{- fail "database.host is required when cnpg.enabled is false" }}
{{- end }}
{{- end }}

{{/*
CNPG app secret holding the owner's username and password, when the database
credentials should come from it (cnpg.enabled and no database.existingSecret).
Empty otherwise. Uses cnpg.cluster.initdb.secret.name when set, since CNPG
then uses that secret instead of generating "<cluster>-app".
*/}}
{{- define "dawarich.database.cnpgSecret" -}}
{{- if and .Values.cnpg.enabled (not .Values.database.existingSecret.name) }}
{{- dig "cluster" "initdb" "secret" "name" "" .Values.cnpg | default (printf "%s-app" (include "dawarich.cnpg.fullname" .)) }}
{{- end }}
{{- end }}

{{/*
Database credential env vars, shared by the web and Sidekiq containers.
*/}}
{{- define "dawarich.database.env" -}}
{{- $cnpgSecret := include "dawarich.database.cnpgSecret" . -}}
{{- if $cnpgSecret -}}
- name: DATABASE_USERNAME
  valueFrom:
    secretKeyRef:
      name: {{ $cnpgSecret }}
      key: username
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ $cnpgSecret }}
      key: password
{{- else if .Values.database.existingSecret.name -}}
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.database.existingSecret.name }}
      key: {{ .Values.database.existingSecret.key }}
{{- else -}}
- name: DATABASE_PASSWORD
  value: {{ .Values.database.password | quote }}
{{- end }}
{{- end }}

{{/*
Name of the bundled Valkey Service. Mirrors the valkey chart's own
valkey.fullname helper.
*/}}
{{- define "dawarich.valkey.fullname" -}}
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
Redis URL — redis.host when set, otherwise the bundled Valkey Service.
*/}}
{{- define "dawarich.redis.url" -}}
{{- if .Values.redis.host }}
{{- .Values.redis.host }}
{{- else if .Values.valkey.enabled }}
{{- printf "redis://%s:%v" (include "dawarich.valkey.fullname" .) (dig "service" "port" 6379 .Values.valkey) }}
{{- else }}
{{- fail "redis.host is required when valkey.enabled is false" }}
{{- end }}
{{- end }}
