{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We will truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cloudwatch-fetcher.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Builds the full logzio listener host
*/}}
{{- define "cloudwatch-fetcher.listenerHost" }}
{{- if or ( eq $.Values.secrets.logzioListener "listener.logz.io" ) ( eq $.Values.secrets.logzioListener "" ) -}}
{{- printf "https://listener.logz.io:8071" }}
{{- else }}
{{- printf "https://%s:8071" .Values.secrets.logzioListener -}}
{{- end -}}
{{- end -}}