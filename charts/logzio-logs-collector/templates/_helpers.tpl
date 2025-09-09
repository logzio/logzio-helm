{{/*
Expand the name of the chart.
*/}}
{{- define "logs-collector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "logs-collector.lowercase_chartname" -}}
{{- default .Chart.Name | lower }}
{{- end }}

{{/*
Get component name
*/}}
{{- define "logs-collector.component" -}}
{{- if eq .Values.mode "daemonset" -}}
component: logs-collector
{{- else if eq .Values.mode "standalone" -}}
component: logs-collector-standalone
{{- end -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "logs-collector.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "logs-collector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "logs-collector.labels" -}}
helm.sh/chart: {{ include "logs-collector.chart" . }}
{{ include "logs-collector.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "logs-collector.additionalLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "logs-collector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "logs-collector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "logs-collector.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "logs-collector.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Create the name of the clusterRole to use
*/}}
{{- define "logs-collector.clusterRoleName" -}}
{{- default (include "logs-collector.fullname" .) .Values.clusterRole.name }}
{{- end }}

{{/*
Create the name of the clusterRoleBinding to use
*/}}
{{- define "logs-collector.clusterRoleBindingName" -}}
{{- default (include "logs-collector.fullname" .) .Values.clusterRole.clusterRoleBinding.name }}
{{- end }}

{{- define "logs-collector.podAnnotations" -}}
{{- if .Values.podAnnotations }}
{{- tpl (.Values.podAnnotations | toYaml) . }}
{{- end }}
{{- end }}

{{- define "logs-collector.podLabels" -}}
{{- if .Values.podLabels }}
{{- tpl (.Values.podLabels | toYaml) . }}
{{- end }}
{{- end }}

{{- define "logs-collector.additionalLabels" -}}
{{- if .Values.additionalLabels }}
{{- tpl (.Values.additionalLabels | toYaml) . }}
{{- end }}
{{- end }}


{{/*
Compute Service creation on mode
*/}}
{{- define "logs-collector.serviceEnabled" }}
  {{- $serviceEnabled := true }}
  {{- if not (eq (toString .Values.service.enabled) "<nil>") }}
    {{- $serviceEnabled = .Values.service.enabled -}}
  {{- end }}
  {{- if and (eq .Values.mode "daemonset") (not .Values.service.enabled) }}
    {{- $serviceEnabled = false -}}
  {{- end }}

  {{- print $serviceEnabled }}
{{- end -}}


{{/*
Compute InternalTrafficPolicy on Service creation
*/}}
{{- define "logs-collector.serviceInternalTrafficPolicy" }}
  {{- if and (eq .Values.mode "daemonset") (eq .Values.service.enabled true) }}
    {{- print (.Values.service.internalTrafficPolicy | default "Local") -}}
  {{- else }}
    {{- print (.Values.service.internalTrafficPolicy | default "Cluster") -}}
  {{- end }}
{{- end -}}

{{/*
Allow the release namespace to be overridden
*/}}
{{- define "logs-collector.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
  This helper converts the input value of memory to Bytes.
  Input needs to be a valid value as supported by k8s memory resource field.
 */}}
{{- define "logs-collector.convertMemToBytes" }}
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

{{- define "logs-collector.gomemlimit" }}
{{- $memlimitBytes := include "logs-collector.convertMemToBytes" . | mulf 0.8 -}}
{{- printf "%dMiB" (divf $memlimitBytes 0x1p20 | floor | int64) -}}
{{- end }}


{{/*
Calculate Logz.io listener address based on region
*/}}
{{- define "logzio.listenerAddress" -}}
{{- $region := .Values.global.logzioRegion -}}
{{- if eq $region "us" -}}
listener.logz.io
{{- else if eq $region "au" -}}
listener-au.logz.io
{{- else if eq $region "ca" -}}
listener-ca.logz.io
{{- else if eq $region "eu" -}}
listener-eu.logz.io
{{- else if eq $region "uk" -}}
listener-uk.logz.io
{{- else -}}
listener.logz.io
{{- end -}}
{{- end }}

{{/*
Returns the value of resource detection enablement state
*/}}
{{- define "logs-collector.resourceDetectionEnabled" -}}
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
Usage: include "logs-collector.flattenResourceFilters" (dict "m" . "prefix" "")
Returns a YAML array of key=regex strings.
*/}}
{{- define "logs-collector.flattenFilters" -}}
{{- $m := .m -}}
{{- $prefix := .prefix | default "" -}}
{{- $out := list -}}
{{- range $k, $v := $m }}
  {{- if kindIs "map" $v }}
    {{- $out = concat $out (include "logs-collector.flattenFilters" (dict "m" $v "prefix" (printf "%s%s." $prefix $k)) | fromYamlArray) }}
  {{- else }}
    {{- $out = append $out (printf "%s%s=%s" $prefix $k $v) }}
  {{- end }}
{{- end }}
{{- toYaml $out }}
{{- end }}

{{/*
Merges local and global affinity settings.
*/}}
{{- define "logs-collector.affinity" -}}
{{- $affinity := dict -}}
{{- if .Values.affinity -}}
  {{- $affinity = mergeOverwrite $affinity .Values.affinity -}}
{{- end -}}
{{- if .Values.global.affinity -}}
  {{- $affinity = mergeOverwrite $affinity .Values.global.affinity -}}
{{- end -}}
{{- if $affinity -}}
affinity:
  {{- toYaml $affinity | nindent 2 }}
{{- end -}}
{{- end -}}

{{/*
Merges local and global nodeSelector settings.
*/}}
{{- define "logs-collector.nodeSelector" -}}
{{- $nodeSelector := dict -}}
{{- if .Values.nodeSelector -}}
  {{- $nodeSelector = mergeOverwrite $nodeSelector .Values.nodeSelector -}}
{{- end -}}
{{- if .Values.global.nodeSelector -}}
  {{- $nodeSelector = merge $nodeSelector .Values.global.nodeSelector -}}
{{- end -}}
{{- if $nodeSelector -}}
nodeSelector:
  {{- toYaml $nodeSelector | nindent 2 }}
{{- end -}}
{{- end -}}