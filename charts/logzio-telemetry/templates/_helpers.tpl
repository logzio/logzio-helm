{{/*
Expand the name of the chart.
*/}}
{{- define "opentelemetry-collector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opentelemetry-collector.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- printf "%s-%s" .Values.fullnameOverride "standalone" | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name ( printf "%s-%s" .Values.nameOverride "standalone" )}}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{- define "opentelemetry-collector.serviceName" -}}
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


{{- define "opentelemetry-collector.daemonsetFullname" -}}
{{- if .Values.fullnameOverride }}
{{- printf "%s-%s" .Values.fullnameOverride "ds" | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name (printf "%s-%s" .Values.nameOverride "ds")}}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name  | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{- define "opentelemetry-spm.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- printf "%s-%s" .Values.fullnameOverride "spm" | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $spmNameWithChart := printf "%s-%s" .Chart.Name "spm"}}
{{- $spmNameFullOverride := printf "%s-%s" .Values.nameOverride "spm"}}
{{- $name := default $spmNameWithChart $spmNameFullOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "opentelemetry-collector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opentelemetry-collector.labels" -}}
helm.sh/chart: {{ include "opentelemetry-collector.chart" . }}
{{ include "opentelemetry-collector.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "opentelemetry-collector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opentelemetry-collector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
component: logzio-telemetry-collector
{{- end }}

{{- define "opentelemetry-collector-spm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opentelemetry-collector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
component: standalone-collector-spm
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "opentelemetry-collector.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "opentelemetry-collector.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Otel-traces
Create the name of the clusterRoleBinding to use
*/}}
{{- define "opentelemetry-collector.clusterRoleBindingName" -}}
{{- if .Values.clusterRole.create }}
{{- default (include "opentelemetry-collector.fullname" .) .Values.clusterRole.clusterRoleBinding.name }}
{{- else }}
{{- default "default" .Values.clusterRole.clusterRoleBinding.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the clusterRole to use
*/}}
{{- define "opentelemetry-collector.clusterRoleName" -}}
{{- if .Values.clusterRole.create }}
{{- default (include "opentelemetry-collector.fullname" .) .Values.clusterRole.name }}
{{- else }}
{{- default "default" .Values.clusterRole.name }}
{{- end }}
{{- end }}


{{/*
Create k360 metrics list - will be used for K360 promethetus filters
If any OOB filters is being used the function return the OOB filter concatenated with custom keep infrastrucre filter
*/}}
{{- define "opentelemetry-collector.k360Metrics" -}}
{{- $metrics := "" }}
{{- if .Values.enableMetricsFilter.aks }}
    {{- $metrics = .Values.prometheusFilters.metrics.infrastructure.keep.aks }}
{{- else if .Values.enableMetricsFilter.gke}}
    {{- $metrics = .Values.prometheusFilters.metrics.infrastructure.keep.gke }}
{{- else }}
    {{- $metrics = .Values.prometheusFilters.metrics.infrastructure.keep.eks }}
{{- end -}}

{{- if .Values.prometheusFilters.metrics.infrastructure.keep.custom }}
    {{- $metrics = print $metrics "|" .Values.prometheusFilters.metrics.infrastructure.keep.custom }}
{{- end }}
{{- $metrics }}
{{- end }}

{{/*
Builds the full logzio listener host
*/}}
{{- define "metrics-collector.listenerAddress" }}
{{- if not (eq .Values.global.customMetricsEndpoint "") -}}
{{- printf "%s" .Values.global.customMetricsEndpoint -}}
{{- else }}
{{- $region := .Values.global.logzioRegion -}}
{{- if or (eq $region "us") (not $region) -}}
https://listener.logz.io:8053
{{- else }}
{{- printf "https://listener-%s.logz.io:8053" $region }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Returns the value of resource detection enablement state
*/}}
{{- define "opentelemetry-collector.resourceDetectionEnabled" -}}
{{- if (hasKey .Values "resourceDetection") }}
{{- if (hasKey .Values.resourceDetection "enabled") }}
{{- .Values.resourceDetection.enabled }}
{{- else }}
{{- .Values.global.resourceDetection.enabled }}
{{- end }}
{{- else }}
{{- .Values.global.resourceDetection.enabled }}
{{- end }}
{{- end }}