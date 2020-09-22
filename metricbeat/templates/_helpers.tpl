{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "metricbeat.fullname" -}}
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
{{- define "metricbeat.serviceAccount" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "metricbeat.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Get chosen configuration for deployment
*/}}
{{- define "metricbeat.chosenDeploymentConfig" }}
{{- if .Values.deployment.metricbeatConfig.custom }}
{{- range $path, $config := .Values.deployment.metricbeatConfig.custom }}
  {{ $path }}: |-
{{ $config | indent 4 -}}
{{- end -}}
{{- else if .Values.deployment.leanConfig }}
{{- range $path, $config := .Values.deployment.metricbeatConfig.lean }}
  {{ $path }}: |-
{{ $config | indent 4 -}}
{{- end -}}
{{- else }}
{{- range $path, $config := .Values.deployment.metricbeatConfig.default }}
  {{ $path }}: |-
{{ $config | indent 4 -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get chosen configuration for daemonset
*/}}
{{- define "metricbeat.chosenDaemonsetConfig" }}
{{- if .Values.daemonset.metricbeatConfig.custom }}
{{- range $path, $config := .Values.daemonset.metricbeatConfig.custom }}
  {{ $path }}: |-
{{ $config | indent 4 -}}
{{- end -}}
{{- else if .Values.daemonset.leanConfig }}
{{- range $path, $config := .Values.daemonset.metricbeatConfig.lean }}
  {{ $path }}: |-
{{ $config | indent 4 -}}
{{- end -}}
{{- else }}
{{- range $path, $config := .Values.daemonset.metricbeatConfig.default }}
  {{ $path }}: |-
{{ $config | indent 4 -}}
{{- end -}}
{{- end -}}
{{- end -}}