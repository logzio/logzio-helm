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

{{- /* Inject dynamic filters */}}
{{- include "logs-collector.addFilterProcessors" (dict "config" $config "filters" .Values.filters) }}

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

{{- include "logs-collector.addFilterProcessors" (dict "config" $config "filters" .Values.filters) }}

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

{{/* Build OTTL expression for a single filter rule */}}
{{- define "logs-collector.filterExpression" -}}
{{- $target := .target -}}
{{- $sub := .sub | default "" -}}
{{- $regex := .regex -}}
{{- if eq $target "namespace" -}}
IsMatch(resource.attributes["k8s.namespace.name"], "{{ $regex }}")
{{- else if eq $target "service" -}}
IsMatch(resource.attributes["service.name"], "{{ $regex }}")
{{- else if eq $target "attribute" -}}
IsMatch(attributes["{{ $sub }}"], "{{ $regex }}")
{{- else if eq $target "resource" -}}
IsMatch(resource.attributes["{{ $sub }}"], "{{ $regex }}")
{{- end -}}
{{- else }}
{{- printf "WARNING: Unsupported filter target '%s' in logs-collector.filterExpression" $target | warn }}
{{- end }}

{{- end }}

{{/* Append filter processors based on .filters to the provided config */}}
{{- define "logs-collector.addFilterProcessors" -}}
{{- $config := .config -}}
{{- $filters := .filters | default dict -}}
{{- if or $filters.exclude $filters.include }}
  {{- /* Prepare slices for exclude and include expressions */}}
  {{- $excludeExprs := list -}}
  {{- $includeExprs := list -}}

  {{- /* Iterate over exclude rules */}}
  {{- with $filters.exclude }}
    {{- range $tkey, $val := . }}
      {{- if or (eq $tkey "namespace") (eq $tkey "service") }}
        {{- $expr := include "logs-collector.filterExpression" (dict "target" $tkey "regex" $val) }}
        {{- $excludeExprs = append $excludeExprs $expr }}
      {{- else if or (eq $tkey "attribute") (eq $tkey "resource") }}
        {{- range $subk, $subv := $val }}
          {{- $expr := include "logs-collector.filterExpression" (dict "target" $tkey "sub" $subk "regex" $subv) }}
          {{- $excludeExprs = append $excludeExprs $expr }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* Iterate over include rules (generate NOT expressions) */}}
  {{- with $filters.include }}
    {{- range $tkey, $val := . }}
      {{- if or (eq $tkey "namespace") (eq $tkey "service") }}
        {{- $expr := include "logs-collector.filterExpression" (dict "target" $tkey "regex" $val) }}
        {{- $includeExprs = append $includeExprs (printf "not (%s)" $expr) }}
      {{- else if or (eq $tkey "attribute") (eq $tkey "resource") }}
        {{- range $subk, $subv := $val }}
          {{- $expr := include "logs-collector.filterExpression" (dict "target" $tkey "sub" $subk "regex" $subv) }}
          {{- $includeExprs = append $includeExprs (printf "not (%s)" $expr) }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* Ensure processors map exists */}}
  {{- if not (hasKey $config "processors") }}
    {{- $_ := set $config "processors" (dict) }}
  {{- end }}

  {{- /* Inject filter/exclude processor */}}
  {{- if gt (len $excludeExprs) 0 }}
    {{- $_ := set (index $config "processors") "filter/exclude" (dict "error_mode" "ignore" "logs" (dict "log_record" $excludeExprs)) }}
  {{- end }}

  {{- /* Inject filter/include processor */}}
  {{- if gt (len $includeExprs) 0 }}
    {{- $_ := set (index $config "processors") "filter/include" (dict "error_mode" "ignore" "logs" (dict "log_record" $includeExprs)) }}
  {{- end }}

  {{- /* Update pipeline order */}}
  {{- $pipeline := index $config "service" "pipelines" "logs" }}
  {{- $orig := $pipeline.processors | default list }}
  {{- $new := list }}
  {{- $filtersAdded := false }}
  {{- range $i, $p := $orig }}
    {{- $new = append $new $p }}
    {{- if and (eq $p "k8sattributes") (not $filtersAdded) }}
      {{- if gt (len $excludeExprs) 0 }}
        {{- $new = append $new "filter/exclude" }}
      {{- end }}
      {{- if gt (len $includeExprs) 0 }}
        {{- $new = append $new "filter/include" }}
      {{- end }}
      {{- $filtersAdded = true }}
    {{- end }}
  {{- end }}
  {{- /* If k8sattributes wasn't present, append filters at start */}}
  {{- if and (not $filtersAdded) (or (gt (len $excludeExprs) 0) (gt (len $includeExprs) 0)) }}
    {{- $new = append (list "filter/exclude") $new }}
    {{- if gt (len $includeExprs) 0 }}
      {{- $new = append (list "filter/include") $new }}
    {{- end }}
  {{- end }}
  {{- $_ := set $pipeline "processors" $new }}
{{- end }}
{{- end }}