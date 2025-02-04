{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We will truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "trivy-to-logzio.fullname" -}}
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
Create the name of the service account to use
*/}}
{{- define "trivy-to-logzio.serviceAccount" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "trivy-to-logzio.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Builds the full logzio listener host
*/}}
{{- define "trivyToLogzio.listenerHost" }}
{{- $region := .Values.global.logzioRegion -}}
{{- if or (eq $region "us") (not $region) -}}
https://listener.logz.io:8071
{{- else }}
{{- printf "https://listener-%s.logz.io:8071" $region }}
{{- end }}
{{- end }}