{{/*
Expand the name of the chart.
*/}}
{{- define "esphome.name" -}}
{{- .Chart.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "esphome.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the chart label value (name-version).
*/}}
{{- define "esphome.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "esphome.labels" -}}
helm.sh/chart: {{ include "esphome.chart" . }}
{{ include "esphome.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used in Deployment matchLabels and Service selector.
*/}}
{{- define "esphome.selectorLabels" -}}
app.kubernetes.io/name: {{ include "esphome.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: dashboard
{{- end }}

{{/*
Image tag: uses .Values.image.tag when set, otherwise falls back to the
chart's appVersion (Chart.yaml).
*/}}
{{- define "esphome.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion -}}
{{- end }}
