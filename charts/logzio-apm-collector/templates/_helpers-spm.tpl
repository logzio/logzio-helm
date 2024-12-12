
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "spm-collector.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- printf "%s-%s" .Values.fullnameOverride "spm" | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Chart.Name "spm" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Get component name
*/}}
{{- define "spm-collector.component" -}}
component: spm-collector
{{- end }}

{{/*
Create Logz.io listener address based on region
*/}}
{{- define "spm-collector.listenerAddress" -}}
{{- $region := .Values.global.logzioRegion -}}
{{- if or (eq $region "us") (not $region) -}}
https://listener.logz.io:8053
{{- else }}
{{- printf "https://listener-%s.logz.io:8053" $region }}
{{- end }}
{{- end }}

{{/*
The SPM service address
*/}}
{{- define "spm-collector.serviceAddr" -}}
{{- $serviceName := include "spm-collector.fullname" .}}
{{- printf "http://%s.%s.svc.cluster.local:4317" $serviceName .Release.Namespace }}
{{- end }}
