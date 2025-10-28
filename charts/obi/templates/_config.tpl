{{/*
Render the OBI configuration YAML
*/}}
{{- define "obi.config" -}}
{{- $config := deepCopy (.Values.config | default dict) -}}

{{/* Add network configuration if enabled */}}
{{- if .Values.network.enabled -}}
{{- $_ := set $config "network" (dict "enable" true) -}}
{{- end -}}
{{- tpl (toYaml $config) . -}}
{{- end -}}
