{{/*
Render the OBI configuration YAML
*/}}
{{- define "obi.config" -}}
{{- $config := deepCopy (.Values.config | default dict) -}}

{{/* Remove otel_metrics_export if metrics are disabled */}}
{{- if not .Values.metrics.enabled -}}
{{- $_ := unset $config "otel_metrics_export" -}}
{{- end -}}

{{/* Add network configuration if enabled */}}
{{- if .Values.network.enabled -}}
{{- $_ := set $config "network" (dict "enable" true) -}}
{{- end -}}
{{- tpl (toYaml $config) . -}}
{{- end -}}
