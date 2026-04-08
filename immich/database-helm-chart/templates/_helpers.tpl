{{/*
Expand the name of the chart.
*/}}
{{- define "database.name" -}}
{{- .Chart.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
Keeps the "-db" suffix so the Service DNS name stays stable.
*/}}
{{- define "database.fullname" -}}
{{- printf "%s-db" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the chart label value (name-version).
*/}}
{{- define "database.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "database.labels" -}}
helm.sh/chart: {{ include "database.chart" . }}
{{ include "database.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used in Deployment matchLabels and Service selector.
*/}}
{{- define "database.selectorLabels" -}}
app.kubernetes.io/name: {{ include "database.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: database
{{- end }}
