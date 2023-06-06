

{{/*
Merge user supplied top-level (not particular to standalone or agent) config into memory limiter config.
*/}}
{{- define "opentelemetry-collector.baseConfig" -}}
{{- $processorsConfig := get .Values.baseCollectorConfig "processors" }}
{{- .Values.baseCollectorConfig | toYaml }}
{{- end }}


{{/*
Build config file for standalone OpenTelemetry Collector
*/}}
{{- define "opentelemetry-collector.standaloneCollectorConfig" -}}
{{- $configData := .Values.emptyConfig }}
{{- $metricsConfig := deepCopy .Values.metricsConfig | mustMergeOverwrite  }}
{{- $tracesConfig := deepCopy .Values.tracesConfig | mustMergeOverwrite }}
{{- $spmConfig := deepCopy .Values.spmForwarderConfig | mustMergeOverwrite }}
{{- $values := deepCopy .Values.standaloneCollector | mustMergeOverwrite (deepCopy .Values) }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.baseConfig" $data | fromYaml }}
{{- $ctxParams := dict "pipeline" "infrastructure" -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $infraFilters := include "opentelemetry-collector.getPipelineFilters" $ctxParams -}}
{{- $ctxParams = dict "pipeline" "applications" -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $applicationsFilters := include "opentelemetry-collector.getPipelineFilters" $ctxParams -}}

{{/* Handle opencost config */}}
{{- if .Values.opencost.enabled -}}
{{- $opencostConfig := deepCopy .Values.opencost.config | mustMergeOverwrite -}}
{{- $metricsConfig = deepCopy $opencostConfig | merge $metricsConfig | mustMergeOverwrite -}}
{{/* merge processor list for opencost*/}}
{{- $_ := set (index $metricsConfig "service" "pipelines" "metrics/infrastructure") "processors" (concat (index $metricsConfig "service" "pipelines" "metrics/infrastructure" "processors") (index $opencostConfig "service" "pipelines" "metrics/infrastructure" "processors" )) -}}
{{- end -}}


{{- if and (and (eq .Values.collector.mode "standalone") (.Values.metrics.enabled)) .Values.traces.enabled  .Values.spm.enabled }}
{{- $configData = $metricsConfig  | merge $tracesConfig | merge $spmConfig | mustMergeOverwrite }}

{{- else if and (and (eq .Values.collector.mode "standalone") (.Values.metrics.enabled)) .Values.traces.enabled }}
{{- $configData = $metricsConfig  | merge $tracesConfig | mustMergeOverwrite }}

{{- else if and .Values.spm.enabled .Values.traces.enabled -}}
{{- $configData = $tracesConfig  | merge $spmConfig | mustMergeOverwrite }}

{{- else if (and (eq .Values.collector.mode "standalone") (.Values.metrics.enabled)) -}}
{{- $configData = $metricsConfig  }}

{{- else if .Values.traces.enabled -}}
{{- $configData = $tracesConfig }}
{{- end -}}


{{- if (and (eq .Values.collector.mode "standalone") (.Values.metrics.enabled)) -}}
  {{- range $job := (index $configData "receivers" "prometheus/infrastructure" "config" "scrape_configs") -}}
    {{- range $key,$filter := ($infraFilters | fromJson) -}}
      {{- if contains "metric" $key -}}
        {{- $_ := set $job ("metric_relabel_configs" | toYaml)  ( append $job.metric_relabel_configs ($filter)) -}}
      {{- else -}}
        {{- $_ := set $job ("relabel_configs" | toYaml)  ( append $job.relabel_configs ($filter)) -}}
      {{- end -}}
    {{- end -}} 
  {{- end -}}

  {{- range $job := (index $configData "receivers" "prometheus/cadvisor" "config" "scrape_configs") -}}
    {{- range $key,$filter := ($infraFilters | fromJson) -}}
      {{- if contains "metric" $key -}}
        {{- $_ := set $job ("metric_relabel_configs" | toYaml)  ( append $job.metric_relabel_configs ($filter)) -}}
      {{- else -}}
        {{- $_ := set $job ("relabel_configs" | toYaml)  ( append $job.relabel_configs ($filter)) -}}
      {{- end -}}
    {{- end -}} 
  {{- end -}}

  {{- range $job := (index $configData "receivers" "prometheus/applications" "config" "scrape_configs") -}}
    {{- range $key,$filter := ($applicationsFilters | fromJson) -}}
      {{- if contains "metric" $key -}}
        {{- $_ := set $job ("metric_relabel_configs" | toYaml)  ( append $job.metric_relabel_configs ($filter)) -}}
      {{- else -}}
        {{- $_ := set $job ("relabel_configs" | toYaml)  ( append $job.relabel_configs ($filter)) -}}
      {{- end -}}
    {{- end -}} 
  {{- end -}}
{{- end -}}
{{- .Values.standaloneCollector.configOverride | merge $configData | mustMergeOverwrite $config | toYaml}}
{{- end -}}

{{- define "opentelemetry-collector.spanMetricsAggregatorConfig" -}}
{{- $configData := .Values.emptyConfig }}
{{- $spmConfig := deepCopy .Values.spanMetricsAgregator.config | mustMergeOverwrite }}
{{- $configData = merge $spmConfig | mustMergeOverwrite }}
{{- end -}}


{{/*
Convert memory value from resources.limit to numeric value in MiB to be used by otel memory_limiter processor.
*/}}
{{- define "opentelemetry-collector.convertMemToMib" -}}
{{- $mem := lower . -}}
{{- if hasSuffix "e" $mem -}}
{{- trimSuffix "e" $mem | atoi | mul 1000 | mul 1000 | mul 1000 | mul 1000 -}}
{{- else if hasSuffix "ei" $mem -}}
{{- trimSuffix "ei" $mem | atoi | mul 1024 | mul 1024 | mul 1024 | mul 1024 -}}
{{- else if hasSuffix "p" $mem -}}
{{- trimSuffix "p" $mem | atoi | mul 1000 | mul 1000 | mul 1000 -}}
{{- else if hasSuffix "pi" $mem -}}
{{- trimSuffix "pi" $mem | atoi | mul 1024 | mul 1024 | mul 1024 -}}
{{- else if hasSuffix "t" $mem -}}
{{- trimSuffix "t" $mem | atoi | mul 1000 | mul 1000 -}}
{{- else if hasSuffix "ti" $mem -}}
{{- trimSuffix "ti" $mem | atoi | mul 1024 | mul 1024 -}}
{{- else if hasSuffix "g" $mem -}}
{{- trimSuffix "g" $mem | atoi | mul 1000 -}}
{{- else if hasSuffix "gi" $mem -}}
{{- trimSuffix "gi" $mem | atoi | mul 1024 -}}
{{- else if hasSuffix "m" $mem -}}
{{- div (trimSuffix "m" $mem | atoi | mul 1000) 1024 -}}
{{- else if hasSuffix "mi" $mem -}}
{{- trimSuffix "mi" $mem | atoi -}}
{{- else if hasSuffix "k" $mem -}}
{{- div (trimSuffix "k" $mem | atoi) 1000 -}}
{{- else if hasSuffix "ki" $mem -}}
{{- div (trimSuffix "ki" $mem | atoi) 1024 -}}
{{- else -}}
{{- div (div ($mem | atoi) 1024) 1024 -}}
{{- end -}}
{{- end -}}

{{/*
Get otel memory_limiter limit_mib value based on 80% of resources.memory.limit.
*/}}
{{- define "opentelemetry-collector.getMemLimitMib" -}}
{{- div (mul (include "opentelemetry-collector.convertMemToMib" .) 80) 100 }}
{{- end -}}

{{/*
Get otel memory_limiter spike_limit_mib value based on 25% of resources.memory.limit.
*/}}
{{- define "opentelemetry-collector.getMemSpikeLimitMib" -}}
{{- div (mul (include "opentelemetry-collector.convertMemToMib" .) 25) 100 }}
{{- end -}}

{{/*
Get otel memory_limiter ballast_size_mib value based on 40% of resources.memory.limit.
*/}}
{{- define "opentelemetry-collector.getMemBallastSizeMib" }}
{{- div (mul (include "opentelemetry-collector.convertMemToMib" .) 40) 100 }}
{{- end -}}

{{/*
Default config override for agent collector deamonset
*/}}
{{- define "opentelemetry-collector.agentConfigOverride" -}}
{{- if .Values.standaloneCollector.enabled }}
exporters:
  otlp:
    endpoint: {{ include "opentelemetry-collector.fullname" . }}:4317
    insecure: true
{{- end }}

{{- if .Values.standaloneCollector.enabled }}
service:
  pipelines:
    logs:
      exporters: [otlp]
    metrics:
      exporters: [otlp]
    traces:
      exporters: [otlp]
{{- end }}
{{- end }}

{{/*
Build config file for standalone OpenTelemetry Collector daemonset
*/}}
{{- define "opentelemetry-collector.daemonsetCollectorConfig" -}}
{{- $configData := .Values.emptyConfig }}
{{- $metricsConfig := deepCopy .Values.daemonsetConfig | mustMergeOverwrite  }}

{{- $ctxParams := dict "pipeline" "infrastructure" -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $infraFilters := include "opentelemetry-collector.getPipelineFilters" $ctxParams -}}
{{- $ctxParams = dict "pipeline" "applications" -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $applicationsFilters := include "opentelemetry-collector.getPipelineFilters" $ctxParams -}}

{{/* Handle opencost config */}}
{{- if .Values.opencost.enabled }}
{{- $opencostConfig := deepCopy .Values.opencost.config | mustMergeOverwrite }}
{{- $metricsConfig = deepCopy $opencostConfig | merge $metricsConfig | mustMergeOverwrite }}
{{/* merge processor list for opencost*/}}
{{- $_ := set (index $metricsConfig "service" "pipelines" "metrics/infrastructure") "processors" (concat (index $metricsConfig "service" "pipelines" "metrics/infrastructure" "processors") (index $opencostConfig "service" "pipelines" "metrics/infrastructure" "processors" )) -}}
{{- end }}

{{- $values := deepCopy .Values.daemonsetCollector | mustMergeOverwrite (deepCopy .Values) }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.baseConfig" $data | fromYaml }}
{{-  if .Values.metrics.enabled -}}
{{- $configData = $metricsConfig  }}
{{- end }}

{{- if .Values.metrics.enabled -}}
  {{- range $job := (index $configData "receivers" "prometheus/infrastructure" "config" "scrape_configs") -}}
    {{- range $key,$filter := ($infraFilters | fromJson) -}}
      {{- if contains "metric" $key -}}
        {{- $_ := set $job ("metric_relabel_configs" | toYaml)  ( append $job.metric_relabel_configs ($filter)) -}}
      {{- else -}}
        {{- $_ := set $job ("relabel_configs" | toYaml)  ( append $job.relabel_configs ($filter)) -}}
      {{- end -}}
    {{- end -}} 
  {{- end -}}

  {{- range $job := (index $configData "receivers" "prometheus/cadvisor" "config" "scrape_configs") -}}
    {{- range $key,$filter := ($infraFilters | fromJson) -}}
      {{- if contains "metric" $key -}}
        {{- $_ := set $job ("metric_relabel_configs" | toYaml)  ( append $job.metric_relabel_configs ($filter)) -}}
      {{- else -}}
        {{- $_ := set $job ("relabel_configs" | toYaml)  ( append $job.relabel_configs ($filter)) -}}
      {{- end -}}
    {{- end -}} 
  {{- end -}}

  {{- range $job := (index $configData "receivers" "prometheus/applications" "config" "scrape_configs") -}}
    {{- range $key,$filter := ($applicationsFilters | fromJson) -}}
      {{- if contains "metric" $key -}}
        {{- $_ := set $job ("metric_relabel_configs" | toYaml)  ( append $job.metric_relabel_configs ($filter)) -}}
      {{- else -}}
        {{- $_ := set $job ("relabel_configs" | toYaml)  ( append $job.relabel_configs ($filter)) -}}
      {{- end -}}
    {{- end -}} 
  {{- end -}}
{{- end -}}

{{- .Values.daemonsetCollector.configOverride | merge $configData | mustMergeOverwrite $config | toYaml}}
{{- end -}}

{{/*
Create pipeline job filters
Param 1: dict: "pipeline" infrastructure/applications & global context
*/}}
{{- define "opentelemetry-collector.getPipelineFilters" -}}

{{/*pipelines's metrics keep filters*/}}
{{- $pipeline := .pipeline -}}
{{- $metricsKeepFilters := (dict "source_labels" (list "__name__") "action" "keep") -}}
{{- if (and .Values.enableMetricsFilter.aks (eq $pipeline "infrastructure")) -}}
  {{- $_ := set $metricsKeepFilters ("regex" ) .Values.prometheusFilters.metrics.infrastructure.keep.aks -}}
{{- else if (and .Values.enableMetricsFilter.eks (eq $pipeline "infrastructure")) -}}
  {{- $_ := set $metricsKeepFilters ("regex" ) .Values.prometheusFilters.metrics.infrastructure.keep.eks -}}
{{- else if (and .Values.enableMetricsFilter.gke (eq $pipeline "infrastructure")) -}}
  {{- $_ := set $metricsKeepFilters ("regex" ) .Values.prometheusFilters.metrics.infrastructure.keep.gke -}}
{{- end -}}
{{- $customKeep := index .Values "prometheusFilters" "metrics" $pipeline "keep" "custom" -}}
{{- if $customKeep -}}
  {{- if (hasKey $metricsKeepFilters "regex" ) -}}
    {{- $_ := set $metricsKeepFilters "regex" (print (get $metricsKeepFilters ("regex") ) "|" $customKeep ) -}}
  {{- else -}}
    {{- $_ := set $metricsKeepFilters "regex" $customKeep -}}
  {{- end -}}
{{- end -}}

{{/*pipeline's metrics drop filters*/}}
{{- $metricsDropFilters := (dict "source_labels" (list "__name__") "action" "drop") -}}
{{- $customDrop := index .Values "prometheusFilters" "metrics" $pipeline "drop" "custom" -}}
{{- if $customDrop -}}
  {{- $_ := set $metricsDropFilters "regex" $customDrop -}}
{{- end -}}

{{/*pipeline's namespace keep filters*/}}
{{- $namespaceKeepFilters := (dict "source_labels" (list "namespace") "action" "keep") -}}
{{- $customKeep = index .Values "prometheusFilters" "namespaces" $pipeline "drop" "custom" -}}
{{- if $customKeep -}}
  {{- $_ := set $namespaceKeepFilters "regex" $customKeep -}}
{{- end -}}

{{/*pipeline's namespace drop filters*/}}
{{- $namespaceDropFilters := (dict "source_labels" (list "namespace") "action" "drop") -}}
{{- if (and .Values.enableMetricsFilter.kubeSystem (eq $pipeline "infrastructure")) -}}
  {{- $_ = set $namespaceDropFilters ("regex" ) .Values.prometheusFilters.namespaces.infrastructure.drop.kubeSystem -}}
{{- end -}}
{{- $customDrop = index .Values "prometheusFilters" "namespaces" $pipeline "drop" "custom" -}}
{{- if $customDrop -}}
  {{- if (hasKey $namespaceDropFilters "regex" ) -}}
    {{- $_ := set $namespaceDropFilters "regex" (print (get $namespaceDropFilters ("regex") ) "|" $customDrop ) -}}
  {{- else -}}
    {{- $_ := set $namespaceDropFilters "regex" $customDrop -}}
  {{- end -}}
{{- end -}}

{{/*pipeline's service keep filters - only valid for infrastructure pipelines!*/}}
{{- $serviceKeepFilters := (dict "source_labels" (list "__meta_kubernetes_service_name") "action" "keep") -}}
{{- $serviceDropFilters := (dict "source_labels" (list "__meta_kubernetes_service_name") "action" "drop") -}}
{{- if eq $pipeline "infrastructure" -}}
  {{- $customKeep = index .Values "prometheusFilters" "services" $pipeline "keep" "custom" -}}
  {{- if $customKeep -}}
    {{- $_ := set $serviceKeepFilters "regex" $customKeep -}}
  {{- end -}}

  {{/*pipeline's service drop filters*/}}
  {{- if (and .Values.disableKubeDnsScraping (eq $pipeline "infrastructure")) -}}
    {{- $_ := set $serviceDropFilters ("regex" ) .Values.prometheusFilters.services.infrastructure.drop.kubeDns -}}
  {{- end -}}
  {{- $customDrop = index .Values "prometheusFilters" "services" $pipeline "drop" "custom" -}}
  {{- if $customDrop -}}
    {{- if (hasKey $serviceDropFilters "regex" ) -}}
      {{- $_ := set $serviceDropFilters "regex" (print (get $serviceDropFilters ("regex") ) "|" $customDrop ) -}}
    {{- else -}}
      {{- $_ := set $serviceDropFilters "regex" $customDrop -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*remove empty filters*/}}
{{/*use the "metric" prefix for dict keys to associate filter with "metric_relabel_config"*/}}
{{- $allFilters := dict "metric1" $metricsKeepFilters "metric2" $metricsDropFilters "3" $namespaceKeepFilters "4" $namespaceDropFilters "5" $serviceDropFilters "6" $serviceKeepFilters -}}
{{- $checkedFilters := dict -}}
{{- range $key,$filter := $allFilters -}}
{{/*check if regex key exists, if so filter also exist*/}}
  {{- if  (hasKey $filter "regex" ) -}}
    {{- $_ := set $checkedFilters $key $filter  -}}
  {{- end -}}  
{{- end -}}
{{- $res := $checkedFilters | toJson -}}
{{- $res -}}
{{- end -}}


{{- define "opentelemetry-collector.agent.containerLogsConfig" -}}
{{- if .Values.agentCollector.containerLogs.enabled -}}
receivers:
  filelog:
    include: [ /var/log/pods/*/*/*.log ]
    # Exclude collector container's logs. The file format is /var/log/pods/<namespace_name>_<pod_name>_<pod_uid>/<container_name>/<run_id>.log
    exclude: [ /var/log/pods/{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}*_*/{{ .Chart.Name }}/*.log ]
    start_at: beginning
    include_file_path: true
    include_file_name: false
    operators:
      # Find out which format is used by kubernetes
      - type: router
        id: get-format
        routes:
          - output: parser-docker
            expr: '$$record matches "^\\{"'
          - output: parser-crio
            expr: '$$record matches "^[^ Z]+ "'
          - output: parser-containerd
            expr: '$$record matches "^[^ Z]+Z"'
      # Parse CRI-O format
      - type: regex_parser
        id: parser-crio
        regex: '^(?P<time>[^ Z]+) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) (?P<log>.*)$'
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: time
          layout_type: gotime
          layout: '2006-01-02T15:04:05.000000000-07:00'
      # Parse CRI-Containerd format
      - type: regex_parser
        id: parser-containerd
        regex: '^(?P<time>[^ ^Z]+Z) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) (?P<log>.*)$'
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: time
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
      # Parse Docker format
      - type: json_parser
        id: parser-docker
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: time
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
      # Extract metadata from file path
      - type: regex_parser
        id: extract_metadata_from_filepath
        regex: '^.*\/(?P<namespace>[^_]+)_(?P<pod_name>[^_]+)_(?P<uid>[a-f0-9\-]{36})\/(?P<container_name>[^\._]+)\/(?P<run_id>\d+)\.log$'
        parse_from: $$attributes.file_path
      # Move out attributes to Attributes
      - type: metadata
        labels:
          stream: 'EXPR($.stream)'
          k8s.container.name: 'EXPR($.container_name)'
          k8s.namespace.name: 'EXPR($.namespace)'
          k8s.pod.name: 'EXPR($.pod_name)'
          run_id: 'EXPR($.run_id)'
          k8s.pod.uid: 'EXPR($.uid)'
      # Clean up log record
      - type: restructure
        id: clean-up-log-record
        ops:
          - move:
              from: log
              to: $
service:
  pipelines:
    logs:
      receivers:
        - filelog
        - otlp
{{- end }}
{{- end }}

	{{/* Build the list of port for standalone service */}}
{{- define "opentelemetry-collector.standalonePortsConfig" -}}

{{- $ports := deepCopy .Values.ports }}
{{- if .Values.standaloneCollector.ports  }}
{{- $ports = deepCopy .Values.standaloneCollector.ports | mustMergeOverwrite (deepCopy .Values.ports) }}
{{- end }}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  port: {{ $port.servicePort }}
  targetPort: {{ $key }}
  protocol: {{ $port.protocol }}
{{- end }}
{{- end }}
{{- end }}







