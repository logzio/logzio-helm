# Merge user supplied config.
{{- define "opentelemetry-collector.baseLoggingConfig" -}}
{{- $config := .Values.config | toYaml -}}
{{- toYaml $config -}}
{{- end }}

# Build config file for daemonset OpenTelemetry Collector
{{- define "opentelemetry-collector.loggingDaemonsetConfig" -}}
{{- $values := deepCopy .Values -}}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) -}}
{{- $config := include "opentelemetry-collector.baseLoggingConfig" $data -}}
{{- tpl $config . -}}
{{- end }}

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