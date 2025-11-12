{{/*
Create a default fully qualified app name for OBI.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "obi.fullname" -}}
{{- printf "%s-obi" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels for OBI */}}
{{- define "obi.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "obi.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: obi
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels for OBI */}}
{{- define "obi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "obi.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: obi
{{- end -}}

{{/* Get the OTLP traces endpoint */}}
{{- define "obi.tracesEndpoint" -}}
{{- if .Values.traces.endpoint -}}
{{- tpl .Values.traces.endpoint . -}}
{{- end -}}
{{- end -}}

{{/* Get the OTLP metrics endpoint */}}
{{- define "obi.metricsEndpoint" -}}
{{- if .Values.metrics.endpoint -}}
{{- tpl .Values.metrics.endpoint . -}}
{{- end -}}
{{- end -}}

{{/* Service account name for OBI */}}
{{- define "obi.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
  {{- default (include "obi.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
  {{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/* Secret name for OBI authentication */}}
{{- define "obi.secretName" -}}
{{- printf "%s-auth" (include "obi.fullname" .) -}}
{{- end -}}
