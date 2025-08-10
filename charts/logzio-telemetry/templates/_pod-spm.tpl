{{- define "opentelemetry-spm.pod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
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
    image: "{{ .Values.spmImage.repository }}:{{ .Values.spmImage.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.spmImage.pullPolicy }}
    securityContext:
      {{- toYaml .Values.containerSecurityContext | nindent 6 }}    
    ports:
      {{- range $key, $port := .Values.spanMetricsAgregator.ports }}
      {{- if $port.enabled }}
      - name: {{ $key }}
        containerPort: {{ $port.containerPort }}
        protocol: {{ $port.protocol }}
      {{- end }}
      {{- end }}
    env:
      - name: MY_POD_IP
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: status.podIP
      - name: LOGZIO_AGENT_VERSION
        value: {{.Chart.Version}}
      - name: REALESE_NAME
        value: {{.Release.Name}}
      - name: REALESE_NS
        value: {{.Release.Namespace}}
      - name: LISTENER_URL
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-metrics-listener
      - name: SPM_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-spm-shipping-token
      - name: ENV_ID
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: env_id
    {{- include "opentelemetry-collector.resources" .Values.spanMetricsAgregator.resources | nindent 4 }}
    volumeMounts:
      - mountPath: /conf
        name: {{ .Chart.Name }}-configmap-spm    
{{- if .Values.priorityClassName }}
priorityClassName: {{ .Values.priorityClassName | quote }}
{{- end }}
volumes:
  - name: {{ .Chart.Name }}-configmap-spm
    configMap:
      name: {{ include "opentelemetry-spm.fullname" . }}
      items:
        - key: relay
          path: relay.yaml
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
{{ toYaml $allTolerations | nindent 2 }}
{{- end }}
{{- if .Values.topologySpreadConstraints }}
topologySpreadConstraints:
{{ toYaml .Values.topologySpreadConstraints | indent 8 }}
{{- end }}
{{- end}}