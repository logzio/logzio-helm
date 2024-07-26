# Merge user supplied config.
{{- define "metrics-collector.baseConfig" -}}
{{- .Values.baseConfig | toYaml }}
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

{{/*
Create pipeline job filters
Param 1: dict: "pipeline" infrastructure/applications & global context
*/}}
{{- define "metrics-collector.getPipelineFilters" -}}

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
{{- $customKeep = index .Values "prometheusFilters" "namespaces" $pipeline "keep" "custom" -}}
{{- if $customKeep -}}
  {{- $_ := set $namespaceKeepFilters "regex" $customKeep -}}
{{- end -}}

{{/*pipeline's namespace drop filters*/}}
{{- $namespaceDropFilters := (dict "source_labels" (list "namespace") "action" "drop") -}}
{{- if (and .Values.enableMetricsFilter.dropKubeSystem (eq $pipeline "infrastructure")) -}}
  {{- $_ := set $namespaceDropFilters ("regex" ) .Values.prometheusFilters.namespaces.infrastructure.drop.kubeSystem -}}
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
{{- $allFilters := dict "metric1" $metricsKeepFilters "metric2" $metricsDropFilters "metric3" $namespaceKeepFilters "metric4" $namespaceDropFilters "5" $serviceDropFilters "6" $serviceKeepFilters -}}
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

{{/*
Build config file for standalone OpenTelemetry Collector
*/}}
{{- define "metrics-collector.standaloneCollectorConfig" -}}
{{- $configData := .Values.emptyConfig }}
{{- $standaloneConfig := deepCopy .Values.standaloneConfig | mustMergeOverwrite  }}
{{- $values := deepCopy .Values.standaloneCollector | mustMergeOverwrite (deepCopy .Values) }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "metrics-collector.baseConfig" $data | fromYaml }}
{{- $ctxParams := dict "pipeline" "infrastructure" -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $infraFilters := include "metrics-collector.getPipelineFilters" $ctxParams -}}
{{- $ctxParams = dict "pipeline" "applications" -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $applicationsFilters := include "metrics-collector.getPipelineFilters" $ctxParams -}}

{{/* Handle opencost config */}}
{{- if .Values.opencost.enabled -}}
{{- $opencostConfig := deepCopy .Values.opencost.config | mustMergeOverwrite -}}
{{- $standaloneConfig = deepCopy $opencostConfig | merge $standaloneConfig | mustMergeOverwrite -}}
{{/* merge processor list for opencost*/}}
{{- $_ := set (index $standaloneConfig "service" "pipelines" "metrics/infrastructure") "processors" (concat (index $standaloneConfig "service" "pipelines" "metrics/infrastructure" "processors") (index $opencostConfig "service" "pipelines" "metrics/infrastructure" "processors" )) -}}
{{- end -}}

{{/* Handle k8s objects config */}}
{{- if .Values.k8sObjectsLogs.enabled -}}
{{- $k8sObjectsLogsConfig := deepCopy .Values.k8sObjectsLogs.config | mustMergeOverwrite -}}
{{- $standaloneConfig = deepCopy $k8sObjectsLogsConfig | merge $standaloneConfig | mustMergeOverwrite -}}
{{- end -}}

{{- if (and (eq .Values.mode "standalone") (.Values.enabled)) -}}
{{- $configData = $standaloneConfig  }}
{{- end -}}

{{- if (and (eq .Values.mode "standalone") (.Values.enabled)) -}}
  {{- range $job := (index $configData "receivers" "prometheus/infrastructure" "config" "scrape_configs") -}}
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
  {{- if .Values.applicationMetrics.enabled -}}
    {{- $metricsApplications := dict "exporters" (list "prometheusremotewrite/applications") "processors" (list "attributes/env_id") "receivers" (list "prometheus/applications") -}}
    {{- $_ := set .Values.standaloneConfig.service.pipelines "metrics/applications" $metricsApplications -}}
  {{- end -}}
{{- end -}}
{{- .Values.standaloneCollector.configOverride | merge $configData | mustMergeOverwrite $config | toYaml}}
{{- end -}}


# Build config file for daemonset metrics Collector
{{- define "metrics-collector.daemonsetCollectorConfig" -}}
{{- $configData := .Values.emptyConfig }}
{{- $daemonsetConfig := deepCopy .Values.daemonsetConfig | mustMergeOverwrite  }}
{{- $values := deepCopy .Values.daemonsetCollector | mustMergeOverwrite (deepCopy .Values) }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "metrics-collector.baseConfig" $data | fromYaml }}
{{- $ctxParams := dict "pipeline" "infrastructure" -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $infraFilters := include "metrics-collector.getPipelineFilters" $ctxParams -}}
{{- $ctxParams = dict "pipeline" "applications" -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $applicationsFilters := include "metrics-collector.getPipelineFilters" $ctxParams -}}

{{/* Handle opencost config */}}
{{- if .Values.opencost.enabled -}}
{{- $opencostConfig := deepCopy .Values.opencost.config | mustMergeOverwrite -}}
{{- $daemonsetConfig = deepCopy $opencostConfig | merge $daemonsetConfig | mustMergeOverwrite -}}
{{/* merge processor list for opencost*/}}
{{- $_ := set (index $daemonsetConfig "service" "pipelines" "metrics/infrastructure") "processors" (concat (index $daemonsetConfig "service" "pipelines" "metrics/infrastructure" "processors") (index $opencostConfig "service" "pipelines" "metrics/infrastructure" "processors" )) -}}
{{- end -}}

{{/* Handle k8s objects config */}}
{{- if .Values.k8sObjectsLogs.enabled -}}
{{- $k8sObjectsLogsConfig := deepCopy .Values.k8sObjectsLogs.config | mustMergeOverwrite -}}
{{- $daemonsetConfig = deepCopy $k8sObjectsLogsConfig | merge $daemonsetConfig | mustMergeOverwrite -}}
{{- end -}}

{{- if (and (eq .Values.mode "daemonset") (.Values.enabled)) -}}
{{- $configData = $daemonsetConfig  }}
{{- end -}}

{{- if (and (eq .Values.mode "daemonset") (.Values.enabled)) -}}
  {{- range $job := (index $configData "receivers" "prometheus/infrastructure" "config" "scrape_configs") -}}
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
  {{- if .Values.applicationMetrics.enabled -}}
    {{- $metricsApplications := dict "exporters" (list "prometheusremotewrite/applications") "processors" (list "attributes/env_id" ) "receivers" (list "prometheus/applications") -}}
    {{- $_ := set .Values.daemonsetConfig.service.pipelines "metrics/applications" $metricsApplications -}}
  {{- end -}}

{{- end -}}

{{- .Values.daemonsetCollector.configOverride | merge $configData | mustMergeOverwrite $config | toYaml}}
{{- end -}}