{{/*
Verify tracing token was provided if the chart is enabled
*/}}
{{- define "check-tracing-token" -}}
  {{- if .Values.enabled }}
    {{- if not .Values.global.logzioTracesToken }}
      {{- fail "Missing Tracing Token" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Verify SPM token was provided if SPM is enabled
*/}}
{{- define "check-spm-token" -}}
  {{- if and (.Values.enabled) (.Values.spm.enabled) }}
    {{- if not .Values.global.logzioSpmToken }}
      {{- fail "Missing SPM Token" }}
    {{- end }}
  {{- end }}
{{- end }}
