{{/*
Expand the name of the chart.
*/}}
{{- define "immich-ml.name" -}}
{{- .Chart.Name }}
{{- end }}

{{/*
Create a default fully qualified app name.
Keeps the "-ml" suffix so the Service DNS name stays stable.
*/}}
{{- define "immich-ml.fullname" -}}
{{- printf "%s-ml" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create the chart label value (name-version).
*/}}
{{- define "immich-ml.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "immich-ml.labels" -}}
helm.sh/chart: {{ include "immich-ml.chart" . }}
{{ include "immich-ml.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used in Deployment matchLabels and Service selector.
*/}}
{{- define "immich-ml.selectorLabels" -}}
app.kubernetes.io/name: {{ include "immich-ml.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: machine-learning
{{- end }}
