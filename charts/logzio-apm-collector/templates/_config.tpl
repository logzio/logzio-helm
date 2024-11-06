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
{{- end }}
{{- end }}
{{- end }}

{{/* Build config file for APM Collector */}}
{{- define "apm-collector.config" -}}
{{- if .Values.spm.enabled }}
{{- $tracesConfig := deepCopy .Values.traceConfig }}
{{- $spmForwarderConfig := deepCopy .Values.spmForwarderConfig }}
{{- ($tracesConfig | merge $spmForwarderConfig | mustMergeOverwrite) | toYaml }}
{{- else }}
{{- .Values.traceConfig | toYaml }}
{{- end}}
{{- end }}

{{/* Build config file for SPM Collector */}}
{{- define "spm-collector.config" -}}
{{- if .Values.serviceGraph.enabled }}
{{- $spmConfig := deepCopy .Values.spmConfig }}
{{- $serviceGraphConfig := deepCopy .Values.serviceGraphConfig }}
{{- $spmConfig.connectors = merge $spmConfig.connectors $serviceGraphConfig.connectors }}
{{- $spmConfig.service.pipelines.traces.exporters = concat $spmConfig.service.pipelines.traces.exporters $serviceGraphConfig.service.pipelines.traces.exporters }}
{{- $spmConfig.service.pipelines.metrics.spm-logzio.receivers = concat $spmConfig.service.pipelines.metrics.spm-logzio.receivers $serviceGraphConfig.service.pipelines.metrics.spm-logzio.receivers }}
{{- $spmConfig | toYaml }}
{{- else }}
{{- .Values.spmConfig | toYaml }}
{{- end }}
{{- end }}
