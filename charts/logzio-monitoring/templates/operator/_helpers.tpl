{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "otel-operator.fullname" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}-instrumentation
{{- end -}}


{{/* Common labels */}}
{{- define "otel-operator.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Common annotations */}}
{{- define "otel-operator.annotations" -}}
helm.sh/hook: "post-install, post-upgrade"
{{- end -}}

{{/* Common annotations */}}
{{- define "otel-operator.cleanupAnnotations" -}}
helm.sh/hook-delete-policy: "before-hook-creation, hook-succeeded, hook-failed"
{{- end -}}


{{/* Resource\DataType exporter type definer */}}
{{- define "otel-operator.rsourceExporterType" -}}
{{- $enabledResource := .enabledResource -}}
{{- $enabledSubChart := .enabledSubChart -}}
{{- if and $enabledResource $enabledSubChart -}}
"otlp"
{{- else -}}
"none"
{{- end -}}
{{- end -}}

{{/* The relevant endpoint's service address */}}
{{- define "otel-operator.serviceAddr" -}}
{{- $serviceName := .serviceName -}}
{{- $releaseNamespace := .releaseNamespace -}}
{{- printf "http://%s.%s.svc.cluster.local" $serviceName $releaseNamespace }}
{{- end -}}