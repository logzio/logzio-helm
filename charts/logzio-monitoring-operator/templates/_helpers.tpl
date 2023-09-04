{{/*
Expand the name of the chart.
*/}}
{{- define "logzio-monitoring-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "logzio-monitoring-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "logzio-monitoring-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "logzio-monitoring-operator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Otel-traces
Create the name of the clusterRoleBinding to use
*/}}
{{- define "logzio-monitoring-operator.clusterRoleBindingName" -}}
{{- if .Values.clusterRole.create }}
{{- default (include "logzio-monitoring-operator.fullname" .) .Values.clusterRoleBinding.name }}
{{- else }}
{{- default "default" .Values.clusterRoleBinding.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the clusterRole to use
*/}}
{{- define "logzio-monitoring-operator.clusterRoleName" -}}
{{- if .Values.clusterRole.create }}
{{- default (include "logzio-monitoring-operator.fullname" .) .Values.clusterRole.name }}
{{- else }}
{{- default "default" .Values.clusterRole.name }}
{{- end }}
{{- end }}
