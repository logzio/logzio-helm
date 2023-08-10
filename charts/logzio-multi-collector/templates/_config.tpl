

{{/*
Merge user supplied top-level (not particular to standalone or agent) config into memory limiter config.
*/}}
{{- define "opentelemetry-collector.baseConfig" -}}
{{- $processorsConfig := get .Values.baseCollectorConfig "processors" }}
{{- .Values.baseCollectorConfig | toYaml }}
{{- end }}




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
Build config file for standalone OpenTelemetry multi collector
*/}}
{{- define "opentelemetry-collector.multiCollectorConfig" -}}
{{- $configData := .Values.emptyConfig }}
{{- $metricsConfig := deepCopy .Values.multiCollectorConfig | mustMergeOverwrite  }}

{{- $ctxParams := dict "pipeline" "infrastructure" "targetNamespace" .targetNamespace -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $infraFilters := include "opentelemetry-collector.getPipelineFilters" $ctxParams -}}
{{- $ctxParams = dict "pipeline" "applications" "targetNamespace" .targetNamespace -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $applicationsFilters := include "opentelemetry-collector.getPipelineFilters" $ctxParams -}}

{{/* Handle opencost config */}}
{{- if .Values.opencost.enabled }}
{{- $opencostConfig := deepCopy .Values.opencost.config | mustMergeOverwrite }}
{{- $metricsConfig = deepCopy $opencostConfig | merge $metricsConfig | mustMergeOverwrite }}
{{/* merge processor list for opencost*/}}
{{- $_ := set (index $metricsConfig "service" "pipelines" "metrics/infrastructure") "processors" (concat (index $metricsConfig "service" "pipelines" "metrics/infrastructure" "processors") (index $opencostConfig "service" "pipelines" "metrics/infrastructure" "processors" )) -}}
{{- end }}

{{- $values := deepCopy .Values.multiCollector | mustMergeOverwrite (deepCopy .Values) -}}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) -}}
{{- $configData = $metricsConfig  }}

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
    {{- $metricsApplications := dict "exporters" (list "prometheusremotewrite/applications") "processors" (list "attributes/env_id" "filter/kubernetes360") "receivers" (list "prometheus/applications") -}}
    {{- $_ := set .Values.multiCollectorConfig.service.pipelines "metrics/applications" $metricsApplications -}}
  {{- end -}}

{{- .Values.multiCollector.configOverride | merge $configData | toYaml}}
{{- end -}}

{{/*
Create pipeline job filters
Param 1: dict: "pipeline" infrastructure/applications , "targetNamespace" & global context
*/}}


{{/*
Create pipeline job filters
Param 1: dict: "pipeline" infrastructure/applications , "targetNamespace",
"filterType" eks,aks,gke,kubeSystem,kubeDns custom & global context 
"filterKind" namespaces,metrics,services
"filterAction" keep,drop
*/}}
{{- define "opentelemetry-collector.getPipelineFilters" -}}
{{- $customKeep := "" -}}
{{- $customDrop := "" -}}
{{/*pipelines's metrics keep filters*/}}
{{- $pipeline := .pipeline -}}
{{- $metricsKeepFilters := (dict "source_labels" (list "__name__") "action" "keep") -}}
{{- $_ := set $ "filterType" "aks" -}}
{{- $_ := set $ "filterKind" "metrics" -}}
{{- $_ := set $ "filterAction" "keep" -}}
{{- if and (eq $pipeline "infrastructure") (eq (include "opentelemetry-collector.isFiltersExistsForNamespace" $) "true" ) -}}
  {{- $_ := set $metricsKeepFilters ("regex" ) .Values.OobFilters.aks -}}
{{- else if (and (eq $pipeline "infrastructure") (eq (include "opentelemetry-collector.isFiltersExistsForNamespace" ($_ := set $ "filterType" "eks")) "true" )) -}}
  {{- $_ := set $metricsKeepFilters ("regex" ) .Values.OobFilters.eks -}}
{{- else if (and (eq $pipeline "infrastructure") (eq (include "opentelemetry-collector.isFiltersExistsForNamespace" (($_ := set $ "filterType" "gke"))) "true" )) -}}
  {{- $_ := set $metricsKeepFilters ("regex" ) .Values.OobFilters.gke -}}
{{- end -}}

{{- $_ := set $ "filterType" "custom" -}}
{{- if eq (include "opentelemetry-collector.isFiltersExistsForNamespace" $) "true" -}}
  {{- $customKeep = index .Values "prometheusFilters" .targetNamespace "metrics" $pipeline "keep" "custom" -}}
  {{- if $customKeep -}}
    {{- if (hasKey $metricsKeepFilters "regex" ) -}}
      {{- $_ := set $metricsKeepFilters "regex" (print (get $metricsKeepFilters ("regex") ) "|" $customKeep ) -}}
    {{- else -}}
      {{- $_ := set $metricsKeepFilters "regex" $customKeep -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*pipeline's metrics drop filters*/}}
{{- $metricsDropFilters := (dict "source_labels" (list "__name__") "action" "drop") -}}
{{- $_ := set $ "filterAction" "drop" -}}
{{- if eq (include "opentelemetry-collector.isFiltersExistsForNamespace" $) "true" -}}
  {{- $customDrop := index .Values "prometheusFilters" .targetNamespace "metrics" $pipeline "drop" "custom" -}}
  {{- if $customDrop -}}
    {{- $_ := set $metricsDropFilters "regex" $customDrop -}}
  {{- end -}}
{{- end -}}

{{/*pipeline's namespace keep filters*/}}
{{- $namespaceKeepFilters := (dict "source_labels" (list "namespace") "action" "keep") -}}
{{- $_ := set $ "filterKind" "namespaces" -}}
{{- $_ := set $ "filterAction" "keep" -}}
{{- if eq (include "opentelemetry-collector.isFiltersExistsForNamespace" $) "true" -}}
  {{- $customKeep = index .Values "prometheusFilters" .targetNamespace "namespaces" $pipeline "keep" "custom" -}}
  {{- if $customKeep -}}
    {{- $_ := set $namespaceKeepFilters "regex" $customKeep -}}
  {{- end -}}
{{- end -}}

{{/*pipeline's namespace drop filters*/}}
{{- $namespaceDropFilters := (dict "source_labels" (list "namespace") "action" "drop") -}}
{{- $_ := set $ "filterAction" "drop" -}}
{{- $_ := set $ "filterType" "dropKubeSystem" -}}

{{- if (and (eq $pipeline "infrastructure") (eq (include "opentelemetry-collector.isFiltersExistsForNamespace" $) "true" )) -}}
  {{- $_ := set $namespaceDropFilters "regex" .Values.OobFilters.kubeSystem -}}
{{- end -}}

{{- $_ := set $ "filterType" "custom" -}}
{{- if eq (include "opentelemetry-collector.isFiltersExistsForNamespace" $) "true" -}}
  {{- $customDrop = index .Values "prometheusFilters" .targetNamespace "namespaces" $pipeline "drop" "custom" -}}
  {{- if $customDrop -}}
    {{- if (hasKey $namespaceDropFilters "regex" ) -}}
      {{- $_ := set $namespaceDropFilters "regex" (print (get $namespaceDropFilters ("regex") ) "|" $customDrop ) -}}
    {{- else -}}
      {{- $_ := set $namespaceDropFilters "regex" $customDrop -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*pipeline's service keep filters - only valid for infrastructure pipelines!*/}}
{{- $serviceKeepFilters := (dict "source_labels" (list "__meta_kubernetes_service_name") "action" "keep") -}}
{{- $serviceDropFilters := (dict "source_labels" (list "__meta_kubernetes_service_name") "action" "drop") -}}
{{- if eq $pipeline "infrastructure" -}}
{{- $_ := set $ "filterKind" "services" -}}
{{- $_ := set $ "filterAction" "keep" -}}
{{- $_ := set $ "filterType" "custom" -}}
{{- if eq (include "opentelemetry-collector.isFiltersExistsForNamespace" $) "true" -}}
    {{- $customKeep = index .Values "prometheusFilters" .targetNamespace "services" $pipeline "keep" "custom" -}}
    {{- if $customKeep -}}
      {{- $_ := set $serviceKeepFilters "regex" $customKeep -}}
    {{- end -}}
{{- end -}}
{{- $_ := set $ "filterAction" "drop" -}}
    {{/*pipeline's service drop filters*/}}
    {{- if eq $pipeline "infrastructure" -}}
      {{- $_ := set $ "filterType" "disableKubeDns" -}}
      {{- if eq (include "opentelemetry-collector.isFiltersExistsForNamespace" $) "true" -}}
        {{- $_ := set $serviceDropFilters ("regex" ) .Values.OobFilters.kubeDns -}}
      {{- end -}}
    {{- end -}}
    {{- $_ := set $ "filterType" "custom" -}}
    {{- if eq (include "opentelemetry-collector.isFiltersExistsForNamespace" $) "true" -}}
      {{- $customDrop = index .Values "prometheusFilters" .targetNamespace "services" $pipeline "drop" "custom" -}}
      {{- if $customDrop -}}
        {{- if (hasKey $serviceDropFilters "regex" ) -}}
          {{- $_ := set $serviceDropFilters "regex" (print (get $serviceDropFilters ("regex") ) "|" $customDrop ) -}}
        {{- else -}}
          {{- $_ := set $serviceDropFilters "regex" $customDrop -}}
        {{- end -}}
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
Create pipeline job filters
Param 1: dict: "pipeline" infrastructure/applications , "targetNamespace",
"filterType" eks,aks,gke,kubeSystem,kubeDns custom & global context 
"filterKind" namespaces,metrics,services
"filterAction" keep,drop
*/}}
{{- define "opentelemetry-collector.isFiltersExistsForNamespace" -}}
{{- $isExists := "" -}}
{{- if (has .filterType (list "aks" "eks" "gke" "dropKubeSystem" "disableKubeDns")) -}}
  {{- $isExists = dig .targetNamespace .filterType "" $.Values.enableMetricsFilter -}}
{{- else -}}
  {{- $isExists = dig .targetNamespace .filterKind .pipeline .filterAction .filterType "" $.Values.prometheusFilters -}}
{{- end -}}
{{- $_ := set $ "test" $isExists -}}
{{- if $isExists -}}
  {{- true -}}
{{- else -}}
  {{- false -}}
{{- end -}}
{{- end -}}


{{- define "opentelemetry-collector.cadvisorCollectorConfig" -}}
{{- $configData := .Values.emptyConfig }}
{{- $metricsConfig := deepCopy .Values.cadvisorCollectorConfig | mustMergeOverwrite  }}

{{- $ctxParams := dict "pipeline" "infrastructure" -}}
{{- $ctxParams = merge $ctxParams $ -}}
{{- $infraFilters := include "opentelemetry-collector.getPipelineFilters" $ctxParams -}}

{{- $configData = $metricsConfig  }}

  {{- range $job := (index $configData "receivers" "prometheus/cadvisor" "config" "scrape_configs") -}}
    {{- range $key,$filter := ($infraFilters | fromJson) -}}
      {{- if contains "metric" $key -}}
        {{- $_ := set $job ("metric_relabel_configs" | toYaml)  ( append $job.metric_relabel_configs ($filter)) -}}
      {{- else -}}
        {{- $_ := set $job ("relabel_configs" | toYaml)  ( append $job.relabel_configs ($filter)) -}}
      {{- end -}}
    {{- end -}} 
  {{- end -}}

{{- $configData | toYaml}}
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







