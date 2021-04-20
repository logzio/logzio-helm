{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "filebeat.fullname" -}}
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
{{- define "filebeat.serviceAccount" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "filebeat.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Convert logzio region code to listener host
*/}}
{{- define "logzio.listenerHost" }}
{{- if or ( eq $.Values.secrets.logzioRegion "us" ) ( eq $.Values.secrets.logzioRegion " " ) -}}
{{- printf "listener.logz.io" }}
{{- else if or ( eq $.Values.secrets.logzioRegion "au" ) ( eq $.Values.secrets.logzioRegion "ca" ) ( eq $.Values.secrets.logzioRegion "eu" ) ( eq $.Values.secrets.logzioRegion "nl" ) ( eq $.Values.secrets.logzioRegion "uk" ) ( eq $.Values.secrets.logzioRegion "wa" ) }}
{{- printf "listener-%s.logz.io" .Values.secrets.logzioRegion -}}
{{- end -}}
{{- end -}}