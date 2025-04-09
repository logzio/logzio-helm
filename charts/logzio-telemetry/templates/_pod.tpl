{{- define "opentelemetry-collector.pod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "opentelemetry-collector.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
containers:
  - name: {{ .Chart.Name }}
    command:
      - /{{ .Values.command.name }}
      - --config=/conf/relay.yaml
      {{- range .Values.command.extraArgs }}
      - {{ . }}
      {{- end }}
    securityContext:
      {{- toYaml .Values.containerSecurityContext | nindent 6 }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
{{- if (or .Values.traces.enabled .Values.metrics.enabled) }}
    ports:
      {{- range $key, $port := .Values.ports }}
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
    env:
      - name: MY_POD_IP
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: status.podIP
      - name: KUBE_NODE_NAME
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName
      - name: K8S_360_METRICS
        value: {{ include "opentelemetry-collector.k360Metrics" . }}
      - name: LOGZIO_AGENT_VERSION
        value: {{.Chart.Version}}
      - name: REALESE_NAME
        value: {{.Release.Name}}
      - name: REALESE_NS
        value: {{.Release.Namespace}}
      - name: SPM_SERVICE_ENDPOINT
        {{- $serviceName := include "opentelemetry-spm.fullname" .}}
        value: {{ printf "http://%s.%s.svc.cluster.local:4317" $serviceName .Release.Namespace }}
{{- if .Values.metrics.enabled }}
      - name: METRICS_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-metrics-shipping-token
      {{ if .Values.k8sObjectsConfig.enabled }}
      - name: OBJECTS_LOGS_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-k8s-objects-logs-token
      {{ end }} 
         
{{- end }}
{{- if or (eq .Values.k8sObjectsConfig.enabled true) (eq .Values.traces.enabled true) }}  
      - name: LOGZIO_LISTENER_REGION
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-listener-region            
{{- end }}
{{- if or (eq .Values.metrics.enabled true) (eq .Values.spm.enabled true) }}
      - name: LISTENER_URL
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-metrics-listener
{{- end }}
{{- if .Values.traces.enabled }}
      - name: TRACES_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-traces-shipping-token
      {{ if .Values.global.CustomTracingEndpoint }}
      - name: CUSTOM_TRACING_ENDPOINT
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: custom-tracing-endpoint
      {{ end }}
      - name: SAMPLING_PROBABILITY
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: sampling-probability
      - name: SAMPLING_LATENCY
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: sampling-latency
{{ if .Values.spm.enabled }}
      - name: SPM_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-spm-shipping-token        
{{ end }}
{{- end }}
      - name: ENV_ID
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: env_id
{{- if .Values.opencost.enabled }}
      - name: OPENCOST_DUPLICATES
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: opencost-duplicates
{{- end }}
      {{- with .Values.extraEnvs }}
      {{- . | toYaml | nindent 6 }}
      {{- end }}
    livenessProbe:
      httpGet:
        path: /
        port: 13133
    readinessProbe:
      httpGet:
        path: /
        port: 13133
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
    volumeMounts:
      - mountPath: /conf
        name: {{ .Chart.Name }}-configmap
      {{- range .Values.extraConfigMapMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        {{- if .subPath }}
        subPath: {{ .subPath }}
        {{- end }}
      {{- end }}
      {{- range .Values.extraHostPathMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        {{- if .mountPropagation }}
        mountPropagation: {{ .mountPropagation }}
        {{- end }}
      {{- end }}
      {{- range .Values.secretMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        {{- if .subPath }}
        subPath: {{ .subPath }}
        {{- end }}
      {{- end }}
{{- if .Values.priorityClassName }}
priorityClassName: {{ .Values.priorityClassName | quote }}
{{- end }}
volumes:
  - name: {{ .Chart.Name }}-configmap
    configMap:
      name: {{ include "opentelemetry-collector.fullname" . }}{{ .configmapSuffix }}
      items:
        - key: relay
          path: relay.yaml
  {{- range .Values.extraConfigMapMounts }}
  - name: {{ .name }}
    configMap:
      name: {{ .configMap }}
  {{- end }}
  {{- range .Values.extraHostPathMounts }}
  - name: {{ .name }}
    hostPath:
      path: {{ .hostPath }}
  {{- end }}
  {{- range .Values.secretMounts }}
  - name: {{ .name }}
    secret:
      secretName: {{ .secretName }}
  {{- end }}
{{- with .Values.linuxNodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if or .Values.tolerations .Values.global.tolerations }}
  {{- $allTolerations := concat (.Values.tolerations | default list) (.Values.global.tolerations | default list) }}
tolerations:
  {{- toYaml $allTolerations | nindent 2 }}
{{- end }}
{{- end }}