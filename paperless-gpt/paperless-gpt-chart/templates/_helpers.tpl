{{/*
Expand the name of the chart.
*/}}
{{- define "paperless-gpt.name" -}}
{{- .Chart.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "paperless-gpt.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the chart label value (name-version).
*/}}
{{- define "paperless-gpt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "paperless-gpt.labels" -}}
helm.sh/chart: {{ include "paperless-gpt.chart" . }}
{{ include "paperless-gpt.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used in Deployment matchLabels and Service selector.
*/}}
{{- define "paperless-gpt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "paperless-gpt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: app
{{- end }}

{{/*
Image tag: uses .Values.image.tag when set, otherwise falls back to the
chart's appVersion (Chart.yaml).
*/}}
{{- define "paperless-gpt.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion -}}
{{- end }}
