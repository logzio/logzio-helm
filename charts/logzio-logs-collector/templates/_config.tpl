# Merge user supplied config.
{{- define "logs-collector.baseLoggingConfig" -}}
{{- $config := .Values.config | toYaml -}}
{{- toYaml $config -}}
{{- end }}

# Build config file for daemonset logs Collector
{{- define "logs-collector.loggingDaemonsetConfig" -}}
{{- $values := deepCopy .Values -}}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) -}}
{{- $config := deepCopy .Values.config }}

{{- if (eq (include "logs-collector.resourceDetectionEnabled" .) "true") }}
  {{- include "logs-collector.addResourceDetectionProcessors" (dict "config" $config "distribution" .Values.global.distribution) }}
{{- end }}

{{- tpl ($config | toYaml) . -}}
{{- end }}

# Build config file for standalone logs Collector
{{- define "logs-collector.loggingStandaloneConfig" -}}
{{- $values := deepCopy .Values -}}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) -}}
{{- $config := deepCopy .Values.config }}

{{- if (eq (include "logs-collector.resourceDetectionEnabled" .) "true") }}
  {{- include "logs-collector.addResourceDetectionProcessors" (dict "config" $config "distribution" .Values.global.distribution) }}
{{- end }}

{{- tpl ($config | toYaml) . -}}
{{- end }}

{{/* Build the list of port for service */}}
{{- define "logs-collector.servicePortsConfig" -}}
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
{{- define "logs-collector.podPortsConfig" -}}
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

{{/* Build config for Resource Detection according to distribution */}}
{{- define "logs-collector.resourceDetectionConfig" -}}
{{- if . }}
{{- if eq . "eks" }}
resourcedetection/distribution:
  timeout: 15s
  detectors: ["eks", "ec2"]
{{- else if eq . "aks" }}
resourcedetection/distribution:
  detectors: ["aks", "azure"]
{{- else if eq . "gke" }}
resourcedetection/distribution:
  detectors: ["gcp"]
{{- else }}
resourcedetection/all:
  detectors: [ec2, azure, gcp]
{{- end }}
{{- else }}
resourcedetection/all:
  detectors: [ec2, azure, gcp]
{{- end }}
{{- end }}

{{/* Append Resource Detection to Opentelemetry config */}}
{{- define "logs-collector.addResourceDetectionProcessors" -}}
{{- $config := .config -}}
{{- $resDetectionConfig := (include "logs-collector.resourceDetectionConfig" .distribution | fromYaml) }}
  {{- if $resDetectionConfig }}
    {{- range $key, $value := $resDetectionConfig }}
      {{- $_ := set $config "processors" (merge (index $config "processors") (dict $key $value)) }}
      {{- $_ := set (index $config "service" "pipelines" "logs") "processors" (prepend (index $config "service" "pipelines" "logs" "processors") $key) }}
    {{- end }}
  {{- end }}
{{- end }}