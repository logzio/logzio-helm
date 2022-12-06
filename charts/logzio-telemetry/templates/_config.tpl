{{/*
Default memory limiter configuration for OpenTelemetry Collector based on k8s resource limits.
*/}}
{{- define "opentelemetry-collector.memoryLimiter" -}}
# check_interval is the time between measurements of memory usage.
check_interval: 5s

# By default limit_mib is set to 80% of ".Values.resources.limits.memory"
limit_mib: {{ include "opentelemetry-collector.getMemLimitMib" .Values.resources.limits.memory }}

# By default spike_limit_mib is set to 25% of ".Values.resources.limits.memory"
spike_limit_mib: {{ include "opentelemetry-collector.getMemSpikeLimitMib" .Values.resources.limits.memory }}
{{- end }}

{{/*
Merge user supplied top-level (not particular to standalone or agent) config into memory limiter config.
*/}}
{{- define "opentelemetry-collector.baseConfig" -}}
{{- $processorsConfig := get .Values.baseCollectorConfig "processors" }}
{{- if not $processorsConfig.memory_limiter }}
{{- $_ := set $processorsConfig "memory_limiter" (include "opentelemetry-collector.memoryLimiter" . | fromYaml) }}
{{- end }}
{{- .Values.baseCollectorConfig | toYaml }}
{{- end }}

{{/*
Build config file for agent OpenTelemetry Collector
*/}}
{{- define "opentelemetry-collector.agentCollectorConfig" -}}
{{- $values := deepCopy .Values.agentCollector | mustMergeOverwrite (deepCopy .Values)  }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.baseConfig" $data | fromYaml }}
{{- $config := include "opentelemetry-collector.agent.containerLogsConfig" $data | fromYaml | mustMergeOverwrite $config }}
{{- $config := include "opentelemetry-collector.agentConfigOverride" $data | fromYaml | mustMergeOverwrite $config }}
{{- .Values.agentCollector.configOverride | mustMergeOverwrite $config | toYaml }}
{{- end }}

{{/*
Build config file for standalone OpenTelemetry Collector
*/}}
{{- define "opentelemetry-collector.standaloneCollectorConfig" -}}
{{- $configData := .Values.emptyConfig }}
{{- $metricsConfig := deepCopy .Values.metricsConfig | mustMergeOverwrite  }}
{{- $tracesConfig := deepCopy .Values.tracesConfig | mustMergeOverwrite }}
{{- $spmConfig := deepCopy .Values.spmConfig | mustMergeOverwrite }}
{{- $values := deepCopy .Values.standaloneCollector | mustMergeOverwrite (deepCopy .Values) }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.baseConfig" $data | fromYaml }}

{{- if and .Values.metrics.enabled .Values.traces.enabled  .Values.spm.enabled }}
{{- $configData = $metricsConfig  | merge $tracesConfig | merge $spmConfig | mustMergeOverwrite }}

{{- else if and .Values.metrics.enabled .Values.traces.enabled }}
{{- $configData = $metricsConfig  | merge $tracesConfig | mustMergeOverwrite }}

{{- else if and .Values.spm.enabled .Values.traces.enabled -}}
{{- $configData = $tracesConfig  | merge $spmConfig | mustMergeOverwrite }}

{{- else if .Values.metrics.enabled -}}
{{- $configData = $metricsConfig  }}

{{- else if .Values.traces.enabled -}}
{{- $configData = $tracesConfig }}
{{- end -}}

{{/*
Use metrics filter configuration:
Filter aks,eks and gke with basic logzio dashboard filters
Drop kube-dns metrics by skipping kube-dns service scraping. (Relevant for eks which
is not supporting )
*/}}
{{- if and .Values.metrics.enabled (or .Values.enableMetricsFilter.eks .Values.enableMetricsFilter.aks .Values.enableMetricsFilter.gke .Values.enableMetricsFilter.kubeSystem .Values.disableKubeDnsScraping)}}
{{- range $job := $configData.receivers.prometheus.config.scrape_configs}}
{{- if and $.Values.disableKubeDnsScraping (eq $job.job_name "kubernetes-service-endpoints")}}
{{- $_ := set $job ("relabel_configs" | toYaml)  ( mustAppend $job.relabel_configs ($.Files.Get "metrics_filter/eks_kubedns_drop_filter.toml" | fromYaml) ) }}
{{- end }}
{{- if and $.Values.enableMetricsFilter.kubeSystem (or (eq $job.job_name "kubernetes-service-endpoints") (eq $job.job_name "kubernetes-cadvisor") (eq $job.job_name "windows-metrics")) }}
{{- $_ := set $job ("relabel_configs" | toYaml)  ( mustAppend $job.relabel_configs ($.Files.Get "metrics_filter/kube-system.toml" | fromYaml) ) }}
{{- end }}
{{- if  and (ne $job.job_name "applications") (ne $job.job_name "collector-metrics")}}
{{- if $.Values.enableMetricsFilter.eks}}
{{- $_ := set $job ("metric_relabel_configs" | toYaml)  ($.Files.Get "metrics_filter/eks_filter.toml" | fromYaml | list ) }}
{{- else if $.Values.enableMetricsFilter.aks}}
{{- $_ := set $job ("metric_relabel_configs" | toYaml)  ($.Files.Get "metrics_filter/aks_filter.toml" | fromYaml | list ) }}
{{- else if $.Values.enableMetricsFilter.gke}}
{{- $_ := set $job ("metric_relabel_configs" | toYaml)  ($.Files.Get "metrics_filter/gke_filter.toml" | fromYaml | list ) }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- .Values.standaloneCollector.configOverride | merge $configData | mustMergeOverwrite $config | toYaml}}
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

{{- define "opentelemetry-collector.agent.containerLogsConfig" -}}
{{- if .Values.agentCollector.containerLogs.enabled }}
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

