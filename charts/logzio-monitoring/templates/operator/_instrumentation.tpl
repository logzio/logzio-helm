{{- define "otel-operator.instrumentation" -}}
{{- $metricsEnabled := index .Values "logzio-k8s-telemetry" "metrics" "enabled" -}}
{{- $tracesEnabled := index .Values "logzio-apm-collector" "enabled" -}}
apiVersion: opentelemetry.io/v1alpha1
kind: Instrumentation
metadata:
  name: {{ include "otel-operator.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "otel-operator.labels" . | nindent 4 }}
  annotations:
    {{- include "otel-operator.instrumentationAnnotations" . | nindent 4 }}
    helm.sh/hook-weight: "3"
spec:
  env:
    {{- if $metricsEnabled }}
    - name: OTEL_EXPORTER_OTLP_METRICS_ENDPOINT
      value: {{ include "otel-operator.serviceAddr" (dict "serviceName" .Values.instrumentation.metricsServiceName "releaseNamespace" .Release.Namespace) }}:4318
    {{- end }}
    {{- if $tracesEnabled }}
    - name: OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
      value: {{ include "otel-operator.serviceAddr" (dict "serviceName" .Values.instrumentation.tracesServiceName "releaseNamespace" .Release.Namespace) }}:4318
    {{- end }}
  resource:
    addK8sUIDAttributes: {{ .Values.instrumentation.addK8sUIDAttributes }}
  {{- with .Values.instrumentation.propagators }}
  propagators:
    {{- . | toYaml | nindent 4 }}
  {{- end }}
  {{- with .Values.instrumentation.sampler }}
  sampler:
    {{- . | toYaml | nindent 4 }}
  {{- end }}
  dotnet:
    env:
      - name: OTEL_METRICS_EXPORTER
        value: {{ include "otel-operator.rsourceExporterType" (dict "enabledResource" .Values.instrumentation.dotnet.metrics.enabled "enabledSubChart" $metricsEnabled) }}
      - name: OTEL_TRACES_EXPORTER
        value: {{ include "otel-operator.rsourceExporterType" (dict "enabledResource" .Values.instrumentation.dotnet.traces.enabled "enabledSubChart" $tracesEnabled) }}
    {{- with .Values.instrumentation.dotnet.extraEnv }}
      {{- . | toYaml | nindent 6 }}
    {{- end }}
  java:
    env:
      - name: OTEL_METRICS_EXPORTER
        value: {{ include "otel-operator.rsourceExporterType" (dict "enabledResource" .Values.instrumentation.java.metrics.enabled "enabledSubChart" $metricsEnabled) }}
      - name: OTEL_TRACES_EXPORTER
        value: {{ include "otel-operator.rsourceExporterType" (dict "enabledResource" .Values.instrumentation.java.traces.enabled "enabledSubChart" $tracesEnabled) }}
    {{- with .Values.instrumentation.java.extraEnv }}
      {{- . | toYaml | nindent 6 }}
    {{- end }}
  python:
    env:
      - name: OTEL_METRICS_EXPORTER
        value: {{ include "otel-operator.rsourceExporterType" (dict "enabledResource" .Values.instrumentation.python.metrics.enabled "enabledSubChart" $metricsEnabled) }}
      - name: OTEL_TRACES_EXPORTER
        value: {{ include "otel-operator.rsourceExporterType" (dict "enabledResource" .Values.instrumentation.python.traces.enabled "enabledSubChart" $tracesEnabled) }}
    {{- with .Values.instrumentation.python.extraEnv }}
      {{- . | toYaml | nindent 6 }}
    {{- end }}
  nodejs:
    env:
      - name: OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
        value: {{ include "otel-operator.serviceAddr" (dict "serviceName" .Values.instrumentation.tracesServiceName "releaseNamespace" .Release.Namespace) }}:4317
      - name: OTEL_EXPORTER_OTLP_METRICS_ENDPOINT
        value: {{ include "otel-operator.serviceAddr" (dict "serviceName" .Values.instrumentation.metricsServiceName "releaseNamespace" .Release.Namespace) }}:4317
      - name: OTEL_METRICS_EXPORTER
        value: {{ include "otel-operator.rsourceExporterType" (dict "enabledResource" .Values.instrumentation.nodejs.metrics.enabled "enabledSubChart" $metricsEnabled) }}
      - name: OTEL_TRACES_EXPORTER
        value: {{ include "otel-operator.rsourceExporterType" (dict "enabledResource" .Values.instrumentation.nodejs.traces.enabled "enabledSubChart" $tracesEnabled) }}
    {{- with .Values.instrumentation.nodejs.extraEnv }}
      {{- . | toYaml | nindent 6 }}
    {{- end -}}
{{- end -}}