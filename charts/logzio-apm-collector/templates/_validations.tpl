{{/*
This file will contain validations on the input of the chart.
For example, verify the log level is with a valid value
*/}}

{{- define "check-tracing-token" -}}
  {{- if .Values.enabled }}
    {{- if and (not .Values.global.logzioTracesToken) (not .Values.secrets.logzioTracesToken) }}
        {{- fail "Missing Tracing Token" }}
    {{- end }}
  {{- end }}
{{- end -}}

{{- define "check-spm-token" -}}
  {{- if and (.Values.enabled) (.Values.spm.enabled) }}
    {{- if and (not .Values.global.logzioSpmToken) (not .Values.secrets.logzioSpmToken) }}
        {{- fail "Missing SPM Token" }}
    {{- end }}
  {{- end }}
{{- end -}}
