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

{{- if (eq (include "apm-collector.resourceDetectionEnabled" .) "true") }}
{{- $resDetectionConfig := (include "apm-collector.resourceDetectionConfig" .Values.global.distribution | fromYaml) }}
  {{- if $resDetectionConfig }}
    {{- range $key, $value := $resDetectionConfig }}
      {{- $_ := set $tracesConfig "processors" (merge (index $tracesConfig "processors") (dict $key $value)) }}
      {{- $_ := set (index $tracesConfig "service" "pipelines" "traces") "processors" (prepend (index $tracesConfig "service" "pipelines" "traces" "processors") $key) }}
      {{- if hasKey $tracesConfig.service.pipelines "traces/spm" }}
      {{- $_ := set (index $tracesConfig "service" "pipelines" "traces/spm") "processors" (prepend (index $tracesConfig "service" "pipelines" "traces/spm" "processors") $key) }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}


{{- if not (or .Values.spm.enabled .Values.serviceGraph.enabled) }}
{{- $_ := unset $tracesConfig.service.pipelines "traces/spm" }}
{{- end -}}

{{/* Inject dynamic filters */}}
{{- include "apm-collector.addFilterProcessors" (dict "config" $tracesConfig "filters" .Values.filters) }}

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

{{/* Build OTTL expression for a single filter rule (traces) */}}
{{- define "apm-collector.filterExpression" -}}
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
{{- else }}
# WARNING: Unsupported filter target '{{ $target }}' in apm-collector.filterExpression
{{- end }}
{{- end }}

{{/* Append filter processors based on .filters to the provided config (traces pipeline) */}}
{{- define "apm-collector.addFilterProcessors" -}}
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
        {{- $expr := include "apm-collector.filterExpression" (dict "target" $tkey "regex" $val) }}
        {{- $excludeExprs = append $excludeExprs $expr }}
      {{- else if eq $tkey "attribute" }}
        {{- $flat := include "apm-collector.flattenFilters" (dict "m" $val "prefix" "") | fromYamlArray }}
        {{- range $item := $flat }}
          {{- $parts := splitList "=" $item }}
          {{- $key := index $parts 0 }}
          {{- $regex := index $parts 1 }}
          {{- $expr := include "apm-collector.filterExpression" (dict "target" "attribute" "sub" $key "regex" $regex) }}
          {{- $excludeExprs = append $excludeExprs $expr }}
        {{- end }}
      {{- else if eq $tkey "resource" }}
        {{- $flat := include "apm-collector.flattenFilters" (dict "m" $val "prefix" "") | fromYamlArray }}
        {{- range $item := $flat }}
          {{- $parts := splitList "=" $item }}
          {{- $key := index $parts 0 }}
          {{- $regex := index $parts 1 }}
          {{- $expr := include "apm-collector.filterExpression" (dict "target" "resource" "sub" $key "regex" $regex) }}
          {{- $excludeExprs = append $excludeExprs $expr }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* Iterate over include rules (generate NOT expressions) */}}
  {{- with $filters.include }}
    {{- range $tkey, $val := . }}
      {{- if or (eq $tkey "namespace") (eq $tkey "service") }}
        {{- $expr := include "apm-collector.filterExpression" (dict "target" $tkey "regex" $val) }}
        {{- $includeExprs = append $includeExprs (printf "not (%s)" $expr) }}
      {{- else if eq $tkey "attribute" }}
        {{- $flat := include "apm-collector.flattenFilters" (dict "m" $val "prefix" "") | fromYamlArray }}
        {{- range $item := $flat }}
          {{- $parts := splitList "=" $item }}
          {{- $key := index $parts 0 }}
          {{- $regex := index $parts 1 }}
          {{- $expr := include "apm-collector.filterExpression" (dict "target" "attribute" "sub" $key "regex" $regex) }}
          {{- $includeExprs = append $includeExprs (printf "not (%s)" $expr) }}
        {{- end }}
      {{- else if eq $tkey "resource" }}
        {{- $flat := include "apm-collector.flattenFilters" (dict "m" $val "prefix" "") | fromYamlArray }}
        {{- range $item := $flat }}
          {{- $parts := splitList "=" $item }}
          {{- $key := index $parts 0 }}
          {{- $regex := index $parts 1 }}
          {{- $expr := include "apm-collector.filterExpression" (dict "target" "resource" "sub" $key "regex" $regex) }}
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
    {{- $_ := set (index $config "processors") "filter/exclude" (dict "error_mode" "ignore" "traces" (dict "span" $excludeExprs)) }}
  {{- end }}

  {{- /* Inject filter/include processor */}}
  {{- if gt (len $includeExprs) 0 }}
    {{- $_ := set (index $config "processors") "filter/include" (dict "error_mode" "ignore" "traces" (dict "span" $includeExprs)) }}
  {{- end }}

  {{- /* Update processors order for each relevant traces pipeline */}}
  {{- range $pName, $pCfg := (index $config "service" "pipelines") }}
    {{- if hasPrefix $pName "traces" }}
      {{- $orig := $pCfg.processors | default list }}
      {{- $new := list }}
      {{- $filtersAdded := false }}
      {{- range $idx, $proc := $orig }}
        {{- $new = append $new $proc }}
        {{- if and (eq $proc "k8sattributes") (not $filtersAdded) }}
          {{- if gt (len $excludeExprs) 0 }}
            {{- $new = append $new "filter/exclude" }}
          {{- end }}
          {{- if gt (len $includeExprs) 0 }}
            {{- $new = append $new "filter/include" }}
          {{- end }}
          {{- $filtersAdded = true }}
        {{- end }}
      {{- end }}
      {{- if and (not $filtersAdded) (or (gt (len $excludeExprs) 0) (gt (len $includeExprs) 0)) }}
        {{- $new = append (list "filter/exclude") $new }}
        {{- if gt (len $includeExprs) 0 }}
          {{- $new = append (list "filter/include") $new }}
        {{- end }}
      {{- end }}
      {{- $_ := set $pCfg "processors" $new }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}