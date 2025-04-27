{{/* Build the list of port for service */}}
{{- define "apm-collector.servicePortsConfig" -}}
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

{{/* Build the list of port for SPM service */}}
{{- define "spm-collector.servicePortsConfig" -}}
{{- $ports := deepCopy .Values.portsSpm }}
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
{{- define "apm-collector.podPortsConfig" -}}
{{- $ports := deepCopy .Values.ports }}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  containerPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
  {{- if and $.isAgent $port.hostPort }}
  hostPort: {{ $port.hostPort }}
  {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Build the list of port for SPM pod */}}
{{- define "spm-collector.podPortsConfig" -}}
{{- $ports := deepCopy .Values.portsSpm }}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  containerPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
  {{- if and $.isAgent $port.hostPort }}
  hostPort: {{ $port.hostPort }}
  {{- end }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Build config file for APM Collector */}}
{{- define "apm-collector.config" -}}
{{- $tracesConfig := deepCopy .Values.traceConfig }}
{{- if not (or .Values.spm.enabled .Values.serviceGraph.enabled) }}
{{- $_ := unset $tracesConfig.service.pipelines "traces/spm" }}
{{- end -}}

{{- if (eq (include "apm-collector.resourceDetectionEnabled" .) "true") }}
{{- $resDetectionConfig := (include "apm-collector.resourceDetectionConfig" .Values.global.distribution | fromYaml) }}
  {{- if $resDetectionConfig }}
    {{- range $key, $value := $resDetectionConfig }}
      {{- $_ := set $tracesConfig "processors" (merge (index $tracesConfig "processors") (dict $key $value)) }}
      {{- $_ := set (index $tracesConfig "service" "pipelines" "traces") "processors" (prepend (index $tracesConfig "service" "pipelines" "traces" "processors") $key) }}
      {{- $_ := set (index $tracesConfig "service" "pipelines" "traces/spm") "processors" (prepend (index $tracesConfig "service" "pipelines" "traces/spm" "processors") $key) }}
    {{- end }}
  {{- end }}
{{- end }}

{{- tpl ($tracesConfig | toYaml) . }}
{{- end -}}

{{/* Build config file for SPM Collector */}}
{{- define "spm-collector.config" -}}
{{- $spmConfig := deepCopy .Values.spmConfig }}
{{- if .Values.serviceGraph.enabled }}
{{- $_ := set (index $spmConfig "service" "pipelines" "metrics/spm-logzio") "receivers" (append (index $spmConfig "service" "pipelines" "metrics/spm-logzio" "receivers") "servicegraph") -}}
{{- $_ := set (index $spmConfig "service" "pipelines" "traces") "exporters" (append (index $spmConfig "service" "pipelines" "traces" "exporters") "servicegraph") -}}
{{- end }}
{{- if .Values.spm.enabled }}
{{- $_ := set (index $spmConfig "service" "pipelines" "metrics/spm-logzio") "receivers" (append (index $spmConfig "service" "pipelines" "metrics/spm-logzio" "receivers") "spanmetrics") -}}
{{- $_ := set (index $spmConfig "service" "pipelines" "traces") "exporters" (append (index $spmConfig "service" "pipelines" "traces" "exporters") "spanmetrics") -}}
{{- end }}
{{- tpl ($spmConfig | toYaml) . }}
{{- end }}

{{/* Build config for Resource Detection according to distribution */}}
{{- define "apm-collector.resourceDetectionConfig" -}}
{{- if . }}
{{- if eq . "eks" }}
resourcedetection/distribution:
  timeout: 15s
  detectors: ["eks", "ec2"]
{{- else if eq . "aks" }}
resourcedetection/distribution:
  detectors: ["env", "aks"]
{{- else if eq . "gke" }}
resourcedetection/distribution:
  detectors: ["env", "gcp"]
{{- else }}
resourcedetection/all:
  detectors: [ec2, azure, gcp]
{{- end }}
{{- else }}
resourcedetection/all:
  detectors: [ec2, azure, gcp]
{{- end }}
{{- end }}