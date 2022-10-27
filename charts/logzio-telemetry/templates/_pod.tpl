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
      {{- toYaml .Values.securityContext | nindent 6 }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
{{- if .Values.traces.enabled }}
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
      - name: REALESE_NAME
        value: {{.Release.Name}}
      - name: REALESE_NS
        value: {{.Release.Namespace}}
{{- if .Values.metrics.enabled }}
      - name: METRICS_TOKEN
        valueFrom:
          secretKeyRef:
            name: logzio-secret
            key: logzio-metrics-shipping-token
      - name: LISTENER_URL
        valueFrom:
          secretKeyRef:
            name: logzio-secret
            key: logzio-metrics-listener
{{- end }}
{{- if .Values.traces.enabled }}
      - name: TRACES_TOKEN
        valueFrom:
          secretKeyRef:
            name: logzio-secret
            key: logzio-traces-shipping-token
      - name: LOGZIO_LISTENER_REGION
        valueFrom:
          secretKeyRef:
            name: logzio-secret
            key: logzio-listener-region
      - name: SAMPLING_PROBABILITY
        valueFrom:
          secretKeyRef:
            name: logzio-secret
            key: sampling-probability
      - name: SAMPLING_LATENCY
        valueFrom:
          secretKeyRef:
            name: logzio-secret
            key: sampling-latency
{{ if .Values.spm.enabled }}
      - name: SPM_TOKEN
        valueFrom:
          secretKeyRef:
            name: logzio-secret
            key: logzio-spm-shipping-token
{{ end }}
{{- end }}
      - name: P8S_LOGZIO_NAME
        valueFrom:
          secretKeyRef:
            name: logzio-secret
            key: p8s-logzio-name
      - name: ENV_ID
        valueFrom:
          secretKeyRef:
            name: logzio-secret
            key: env_id
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
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
