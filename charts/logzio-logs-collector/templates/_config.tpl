{{/*
Default memory limiter configuration for OpenTelemetry Collector based on k8s resource limits.
*/}}
{{- define "opentelemetry-collector.memoryLimiter" -}}
# check_interval is the time between measurements of memory usage.
check_interval: 5s

# By default limit_mib is set to 80% of ".Values.resources.limits.memory"
limit_percentage: 80

# By default spike_limit_mib is set to 25% of ".Values.resources.limits.memory"
spike_limit_percentage: 25
{{- end }}

# TODO test
{{/*
Merge user supplied config into memory limiter config.
*/}}
{{- define "opentelemetry-collector.baseConfig" -}}
# {{- $processorsConfig := get .Values.config "processors" }}
# {{- if not $processorsConfig.memory_limiter }}
# {{-   $_ := set $processorsConfig "memory_limiter" (include "opentelemetry-collector.memoryLimiter" . | fromYaml) }}
# {{- end }}

# {{- if .Values.useGOMEMLIMIT }}
#   {{- if (((.Values.config).service).extensions) }}
#     {{- $_ := set .Values.config.service "extensions" (without .Values.config.service.extensions "memory_ballast") }}
#   {{- end}}
#   {{- $_ := unset (.Values.config.extensions) "memory_ballast" }}
# {{- else }}
#   {{- $memoryBallastConfig := get .Values.config.extensions "memory_ballast" }}
#   {{- if or (not $memoryBallastConfig) (not $memoryBallastConfig.size_in_percentage) }}
#   {{-   $_ := set $memoryBallastConfig "size_in_percentage" 40 }}
#   {{- end }}
# {{- end }}

{{- .Values.config | toYaml }}
{{- end }}

{{/*
Build config file for daemonset OpenTelemetry Collector
*/}}
{{- define "opentelemetry-collector.daemonsetConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.baseConfig" $data | fromYaml }}
{{- tpl (toYaml $config) . }}
{{- end }}


## TODO need to add this to config and service extentions
# extensions:
#  file_storage:
#    directory: /var/lib/otelcol
#
# TODO also this
# filog.storage: file_storage
#


{{/* Build the list of port for service */}}
{{- define "opentelemetry-collector.servicePortsConfig" -}}
{{- $ports := deepCopy .Values.ports }}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  port: {{ $port.servicePort }}
  targetPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
  {{- if $port.appProtocol }}
  appProtocol: {{ $port.appProtocol }}
  {{- end }}
{{- if $port.nodePort }}
  nodePort: {{ $port.nodePort }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Build the list of port for pod */}}
{{- define "opentelemetry-collector.podPortsConfig" -}}
{{- $ports := deepCopy .Values.ports }}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  containerPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
  {{- if and $.isAgent $port.hostPort }}
  hostPort: {{ $port.hostPort }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}