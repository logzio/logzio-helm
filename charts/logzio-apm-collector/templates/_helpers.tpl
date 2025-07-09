{{/*
Expand the name of the chart.
*/}}
{{- define "apm-collector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "apm-collector.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/* Allow the release namespace to be overridden */}}
{{- define "apm-collector.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/* Get component name */}}
{{- define "apm-collector.component" -}}
component: apm-collector
{{- end }}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "apm-collector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "apm-collector.lowercase_chartname" -}}
{{- default .Chart.Name | lower }}
{{- end }}

{{/* Selector labels */}}
{{- define "apm-collector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "apm-collector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Custom additional labels */}}
{{- define "apm-collector.additionalLabels" -}}
{{- if .Values.additionalLabels }}
{{- tpl (.Values.additionalLabels | toYaml) . }}
{{- end }}
{{- end }}

{{/* Common labels */}}
{{- define "apm-collector.labels" -}}
helm.sh/chart: {{ include "apm-collector.chart" . }}
{{ include "apm-collector.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "apm-collector.additionalLabels" . }}
{{- end }}

{{/* Create the name of the service account to use */}}
{{- define "apm-collector.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "apm-collector.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Create the name of the clusterRole to use */}}
{{- define "apm-collector.clusterRoleName" -}}
{{- default (include "apm-collector.fullname" .) .Values.clusterRole.name }}
{{- end }}

{{/* Create the name of the clusterRoleBinding to use */}}
{{- define "apm-collector.clusterRoleBindingName" -}}
{{- default (include "apm-collector.fullname" .) .Values.clusterRole.clusterRoleBinding.name }}
{{- end }}

{{/* Custom pod annotations */}}
{{- define "apm-collector.podAnnotations" -}}
{{- if .Values.podAnnotations -}}
{{- tpl (.Values.podAnnotations | toYaml) . }}
{{- end -}}
{{- end -}}

{{/*Custom pod labels */}}
{{- define "apm-collector.podLabels" -}}
{{- if .Values.podLabels }}
{{- tpl (.Values.podLabels | toYaml) . }}
{{- end }}
{{- end }}

{{/*
  This helper converts the input value of memory to Bytes.
  Input needs to be a valid value as supported by k8s memory resource field.
 */}}
{{- define "apm-collector.convertMemToBytes" }}
  {{- $mem := lower . -}}
  {{- if hasSuffix "e" $mem -}}
    {{- $mem = mulf (trimSuffix "e" $mem | float64) 1e18 -}}
  {{- else if hasSuffix "ei" $mem -}}
    {{- $mem = mulf (trimSuffix "e" $mem | float64) 0x1p60 -}}
  {{- else if hasSuffix "p" $mem -}}
    {{- $mem = mulf (trimSuffix "p" $mem | float64) 1e15 -}}
  {{- else if hasSuffix "pi" $mem -}}
    {{- $mem = mulf (trimSuffix "pi" $mem | float64) 0x1p50 -}}
  {{- else if hasSuffix "t" $mem -}}
    {{- $mem = mulf (trimSuffix "t" $mem | float64) 1e12 -}}
  {{- else if hasSuffix "ti" $mem -}}
    {{- $mem = mulf (trimSuffix "ti" $mem | float64) 0x1p40 -}}
  {{- else if hasSuffix "g" $mem -}}
    {{- $mem = mulf (trimSuffix "g" $mem | float64) 1e9 -}}
  {{- else if hasSuffix "gi" $mem -}}
    {{- $mem = mulf (trimSuffix "gi" $mem | float64) 0x1p30 -}}
  {{- else if hasSuffix "m" $mem -}}
    {{- $mem = mulf (trimSuffix "m" $mem | float64) 1e6 -}}
  {{- else if hasSuffix "mi" $mem -}}
    {{- $mem = mulf (trimSuffix "mi" $mem | float64) 0x1p20 -}}
  {{- else if hasSuffix "k" $mem -}}
    {{- $mem = mulf (trimSuffix "k" $mem | float64) 1e3 -}}
  {{- else if hasSuffix "ki" $mem -}}
    {{- $mem = mulf (trimSuffix "ki" $mem | float64) 0x1p10 -}}
  {{- end }}
{{- $mem }}
{{- end }}

{{/*
Create GOMEMLIMIT value
*/}}
{{- define "apm-collector.gomemlimit" }}
{{- $memlimitBytes := include "apm-collector.convertMemToBytes" . | mulf 0.8 -}}
{{- printf "%dMiB" (divf $memlimitBytes 0x1p20 | floor | int64) -}}
{{- end }}

{{/*
The APM service address
*/}}
{{- define "apm-collector.serviceAddr" -}}
{{- $serviceName := include "apm-collector.fullname" .}}
{{- printf "http://%s.%s.svc.cluster.local" $serviceName .Release.Namespace }}
{{- end }}

{{/*
Returns the value of resource detection enablement state
*/}}
{{- define "apm-collector.resourceDetectionEnabled" -}}
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

{{/*
Recursively flattens a map into dot-separated keys for resource filters.
Usage: include "apm-collector.flattenFilters" (dict "m" . "prefix" "")
Returns a YAML array of key=regex strings.
*/}}
{{- define "apm-collector.flattenFilters" -}}
{{- $m := .m -}}
{{- $prefix := .prefix | default "" -}}
{{- $out := list -}}
{{- range $k, $v := $m }}
  {{- if kindIs "map" $v }}
    {{- $out = concat $out (include "apm-collector.flattenFilters" (dict "m" $v "prefix" (printf "%s%s." $prefix $k)) | fromYamlArray) }}
  {{- else }}
    {{- $out = append $out (printf "%s%s=%s" $prefix $k $v) }}
  {{- end }}
{{- end }}
{{- toYaml $out }}
{{- end }}
