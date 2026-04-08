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
