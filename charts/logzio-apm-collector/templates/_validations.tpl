{{/*
Verify tracing token was provided if the chart is enabled
*/}}
{{- define "check-tracing-token" -}}
  {{- if .Values.enabled }}
    {{- $hasGlobalToken := and (hasKey .Values "global") .Values.global.logzioTracesToken -}}
    {{- $hasSecretsToken := .Values.secrets.logzioTracesToken -}}
    {{- if not (or $hasGlobalToken $hasSecretsToken) }}
      {{- fail "Missing Tracing Token" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Verify SPM token was provided if SPM is enabled
*/}}
{{- define "check-spm-token" -}}
  {{- if and (.Values.enabled) (.Values.spm.enabled) }}
    {{- $hasGlobalToken := and (hasKey .Values "global") .Values.global.logzioSpmToken -}}
    {{- $hasSecretsToken := .Values.secrets.logzioSpmToken -}}
    {{- if not (or $hasGlobalToken $hasSecretsToken) }}
      {{- fail "Missing SPM Token" }}
    {{- end }}
  {{- end }}
{{- end }}
