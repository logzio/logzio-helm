# Merge user supplied config.
{{- define "metrics-collector.baseMetricsConfig" -}}
{{- $config := .Values.config | toYaml -}}
{{- toYaml $config -}}
{{- end }}

# Build config file for daemonset metrics Collector
{{- define "metrics-collector.metricsDaemonsetConfig" -}}
{{- $values := deepCopy .Values.daemonsetCollector.config -}}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) -}}
{{- $config := include "metrics-collector.baseMetricsConfig" $data -}}
{{- tpl $config . -}}
{{- end }}

# Build config file for standalone metrics Collector
{{- define "metrics-collector.metricsStandaloneConfig" -}}
{{- $values := deepCopy .Values.standaloneCollector.config -}}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) -}}
{{- $config := include "metrics-collector.baseMetricsConfig" $data -}}
{{- tpl $config . -}}
{{- end }}

{{/* Build the list of port for service */}}
{{- define "metrics-collector.servicePortsConfig" -}}
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
{{- define "metrics-collector.podPortsConfig" -}}
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