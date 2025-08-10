{{- define "opentelemetry-collector.daemonset-pod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "opentelemetry-collector.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
enableServiceLinks: {{ .Values.enableServiceLinks }}
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
{{- if .Values.metrics.enabled }}
    ports:
      {{- range $key, $port := .Values.ports }}
      {{- $shouldEnable := $port.enabled }}
      {{- if eq $key "signalfx" }}
        {{- $shouldEnable = $.Values.signalFx.enabled }}
      {{- end }}
      {{- if eq $key "carbon" }}
        {{- $shouldEnable = $.Values.carbon.enabled }}
      {{- end }}
      {{- if $shouldEnable }}
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
      - name: LOGZIO_LISTENER_REGION
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-listener-region            
      {{ end }}
      {{ if .Values.global.customLogsEndpoint }}
      - name: CUSTOM_LOGS_ENDPOINT
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: custom-logs-endpoint
      {{ end }}        
      - name: LISTENER_URL
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-metrics-listener
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
    {{- include "opentelemetry-collector.resources" .Values.daemonsetCollector.resources | nindent 4 }}
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
      name: {{ include "opentelemetry-collector.daemonsetFullname" . }}{{ .configmapSuffix }}
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
{{- with .Values.daemonsetCollector.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if or .Values.tolerations .Values.global.tolerations }}
  {{- $allTolerations := concat (.Values.tolerations | default list) (.Values.global.tolerations | default list) }}
tolerations:
{{ toYaml $allTolerations | nindent 2 }}
{{- end }}
{{- if .Values.topologySpreadConstraints }}
topologySpreadConstraints:
{{ toYaml .Values.topologySpreadConstraints | indent 8 }}
{{- end }}
{{- end }}