{{/*
Expand the name of the chart.
*/}}
{{- define "logzio-otel-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "logzio-otel-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "logzio-otel-operator.labels" -}}
helm.sh/chart: {{ include "logzio-otel-operator.chart" . }}
{{ include "logzio-otel-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "logzio-otel-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "logzio-otel-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Otel collector service name
*/}}
{{- define "logzio-otel-operator.collector-name" -}}
{{- default "otel-collector" .Values.collector.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Otel collector service endpoint
*/}}
{{- define "logzio-otel-operator.collector-url" -}}
{{- $endpoint := .Values.collector.name }}
{{- printf "%s%s%s" "http://" $endpoint "-collector:4317" | trunc 63 | trimSuffix "-" }}
{{- end }}
