{{- define "apm-collector.pod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "apm-collector.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- with .Values.hostAliases }}
hostAliases:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers:
  - name: {{ include "apm-collector.lowercase_chartname" . }}
    command:
      - /{{ .Values.command.name }}
      {{- if .Values.configMap.create }}
      - --config=/conf/relay.yaml
      {{- end }}
      {{- range .Values.command.extraArgs }}
      - {{ . }}
      {{- end }}
    securityContext:
      {{- toYaml .Values.containerSecurityContext | nindent 6 }}
    {{- if .Values.image.digest }}
    image: "{{ .Values.image.repository }}@{{ .Values.image.digest }}"
    {{- else }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    {{- end }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    {{- $ports := include "apm-collector.podPortsConfig" . }}
    {{- if $ports }}
    ports:
      {{- $ports | nindent 6 }}
    {{- end }}
    env:
      - name: MY_POD_IP
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: status.podIP
      - name: K8S_NODE_NAME
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName
      - name: SPM_SERVICE_ENDPOINT
        value: {{ include "spm-collector.serviceAddr" . | quote }}
      - name: ENV_ID
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secret.name }}
            key: env-id
      - name: LOGZIO_REGION
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secret.name }}
            key: logzio-listener-region
      - name: LOGZIO_TRACES_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secret.name }}
            key: logzio-traces-token
      {{- if .Values.global.customTracesEndpoint }}
      - name: CUSTOM_TRACES_ENDPOINT
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secret.name }}
            key: custom-traces-endpoint
      {{- end }}
      - name: LOG_LEVEL
        value: {{ .Values.otelLogLevel | default "info" | quote }}
      - name: SAMPLING_LATENCY
        value: {{ .Values.SamplingLatency | default 10 | quote}}
      - name: SAMPLING_PROBABILITY
        value: {{ .Values.SamplingProbability | default 500 | quote }}
      {{- if and (.Values.useGOMEMLIMIT) (((.Values.resources).limits).memory) }}
      - name: GOMEMLIMIT
        value: {{ include "apm-collector.gomemlimit" .Values.resources.limits.memory | quote }}
      {{- end }}
      {{- with .Values.extraEnvs }}
      {{- . | toYaml | nindent 6 }}
      {{- end }}
    {{- with .Values.extraEnvsFrom }}
    envFrom:
    {{- . | toYaml | nindent 6 }}
    {{- end }}
    {{- if .Values.lifecycleHooks }}
    lifecycle:
      {{- toYaml .Values.lifecycleHooks | nindent 6 }}
    {{- end }}
    livenessProbe:
      {{- if .Values.livenessProbe.initialDelaySeconds | empty | not }}
      initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
      {{- end }}
      {{- if .Values.livenessProbe.periodSeconds | empty | not }}
      periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
      {{- end }}
      {{- if .Values.livenessProbe.timeoutSeconds | empty | not }}
      timeoutSeconds: {{ .Values.livenessProbe.timeoutSeconds }}
      {{- end }}
      {{- if .Values.livenessProbe.failureThreshold | empty | not }}
      failureThreshold: {{ .Values.livenessProbe.failureThreshold }}
      {{- end }}
      {{- if .Values.livenessProbe.terminationGracePeriodSeconds | empty | not }}
      terminationGracePeriodSeconds: {{ .Values.livenessProbe.terminationGracePeriodSeconds }}
      {{- end }}
      httpGet:
        path: {{ .Values.livenessProbe.httpGet.path }}
        port: {{ .Values.livenessProbe.httpGet.port }}
    readinessProbe:
      {{- if .Values.readinessProbe.initialDelaySeconds | empty | not }}
      initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds }}
      {{- end }}
      {{- if .Values.readinessProbe.periodSeconds | empty | not }}
      periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
      {{- end }}
      {{- if .Values.readinessProbe.timeoutSeconds | empty | not }}
      timeoutSeconds: {{ .Values.readinessProbe.timeoutSeconds }}
      {{- end }}
      {{- if .Values.readinessProbe.successThreshold | empty | not }}
      successThreshold: {{ .Values.readinessProbe.successThreshold }}
      {{- end }}
      {{- if .Values.readinessProbe.failureThreshold | empty | not }}
      failureThreshold: {{ .Values.readinessProbe.failureThreshold }}
      {{- end }}
      httpGet:
        path: {{ .Values.readinessProbe.httpGet.path }}
        port: {{ .Values.readinessProbe.httpGet.port }}
    {{- with .Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
      {{- if .Values.configMap.create }}
      - mountPath: /conf
        name: {{ include "apm-collector.lowercase_chartname" . }}-configmap
      {{- end }}
      {{- if .Values.extraVolumeMounts }}
      {{- toYaml .Values.extraVolumeMounts | nindent 6 }}
      {{- end }}
{{- with .Values.extraContainers }}
{{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.initContainers }}
initContainers:
  {{- tpl (toYaml .Values.initContainers) . | nindent 2 }}
{{- end }}
{{- if .Values.priorityClassName }}
priorityClassName: {{ .Values.priorityClassName | quote }}
{{- end }}
volumes:
  {{- if .Values.configMap.create }}
  - name: {{ include "apm-collector.lowercase_chartname" . }}-configmap
    configMap:
      name: {{ include "apm-collector.fullname" . }}
      items:
        - key: relay
          path: relay.yaml
  {{- end }}
  {{- if .Values.extraVolumes }}
  {{- toYaml .Values.extraVolumes | nindent 2 }}
  {{- end }}
{{- with .Values.nodeSelector }}
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
{{- with .Values.topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
