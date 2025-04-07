{{- define "logs-collector.loggingPod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "logs-collector.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- with .Values.hostAliases }}
hostAliases:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers:
  - name: {{ include "logs-collector.lowercase_chartname" . }}
    command:
      - /{{ .Values.command.name }}
      {{- if .Values.configMap.create }}
      - --config=/conf/relay.yaml
      {{- end }}
      {{- range .Values.command.extraArgs }}
      - {{ . }}
      {{- end }}
    securityContext:
      {{- if not (.Values.securityContext) }}
      runAsUser: 0
      runAsGroup: 0
      {{- else -}}
      {{- toYaml .Values.securityContext | nindent 6 }}
      {{- end }}
    {{- if .Values.image.digest }}
    image: "{{ ternary "" (print (.Values.global).imageRegistry "/") (empty (.Values.global).imageRegistry) }}{{ .Values.image.repository }}@{{ .Values.image.digest }}"
    {{- else }}
    image: "{{ ternary "" (print (.Values.global).imageRegistry "/") (empty (.Values.global).imageRegistry) }}{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    {{- end }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}

    {{- $ports := include "logs-collector.podPortsConfig" . }}
    {{- if $ports }}
    ports:
      {{- $ports | nindent 6}}
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
      - name: ENV_ID
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secret.name }}
            key: env-id
      - name: LOG_TYPE
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secret.name }}
            key: log-type
      - name: LOGZIO_REGION
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secret.name }}
            key: logzio-listener-region
      - name: LOGZIO_LOGS_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secret.name }}
            key: logzio-logs-token
      {{- if .Values.global.customLogsEndpoint }}
      - name: CUSTOM_ENDPOINT
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secret.name }}
            key: custom-endpoint
      {{- end -}}
      {{- if and (.Values.useGOMEMLIMIT) ((((.Values.resources).limits).memory))  }}
      - name: GOMEMLIMIT
        value: {{ include "logs-collector.gomemlimit" .Values.resources.limits.memory | quote }}
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
        name: {{ include "logs-collector.lowercase_chartname" . }}-configmap
      {{- end }}
      - name: varlogpods
        mountPath: /var/log/pods
        readOnly: true
      - name: varlibdockercontainers
        mountPath: /var/lib/docker/containers
        readOnly: true
      - name: varlibotelcol
        mountPath: /var/lib/otelcol
      - name: varlogcontainers
        mountPath: /var/log/containers
        readOnly: true
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
  - name: {{ include "logs-collector.lowercase_chartname" . }}-configmap
    configMap:
      name: {{ include "logs-collector.fullname" . }}{{ .configmapSuffix }}
      items:
        - key: relay
          path: relay.yaml
  {{- end }}
  - name: varlogpods
    hostPath:
      path: /var/log/pods
  - name: varlibotelcol
    hostPath:
      path: /var/lib/otelcol
      type: DirectoryOrCreate
  - name: varlibdockercontainers
    hostPath:
      path: /var/lib/docker/containers
  - name: varlogcontainers
    hostPath:
      path: /var/log/containers
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
{{- with .Values.tolerations }}
tolerations:
  {{- $globalTolerations := .Values.global.tolerations | default list }}
  {{- $chartTolerations := .Values.tolerations | default list }}
  {{- toYaml (append $globalTolerations $chartTolerations) | nindent 2 }}
{{- end }}
{{- with .Values.topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
