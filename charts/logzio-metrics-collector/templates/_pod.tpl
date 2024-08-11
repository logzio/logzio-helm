{{- define "metrics-collector.metricsPod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "metrics-collector.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- with .Values.hostAliases }}
hostAliases:
  {{- toYaml . | nindent 2 }}
{{- end }}
containers:
  - name: {{ include "metrics-collector.lowercase_chartname" . }}
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

    {{- $ports := include "metrics-collector.podPortsConfig" . }}
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
      - name: KUBE_NODE_NAME
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName
      - name: K8S_360_METRICS
        value: {{ include "metrics-collector.k360Metrics" . }}
      - name: LOGZIO_AGENT_VERSION
        value: {{.Chart.Version}}
      - name: RELEASE_NAME
        value: {{.Release.Name}}
      - name: RELEASE_NS
        value: {{.Release.Namespace}}            
      {{ if .Values.secrets.enabled}}
      - name: LOGZIO_REGION
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-listener-region
      - name: LOGZIO_METRICS_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-metrics-token
      {{- if .Values.secrets.customEndpoint }}
      - name: CUSTOM_ENDPOINT
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: custom-endpoint
      - name: LISTENER_URL
      valueFrom:
        secretKeyRef:
          name: {{ .Values.secrets.name }}
          key: custom-endpoint            
      {{- end -}}
      {{- if .Values.secrets.k8sObjectsLogsToken }}
      - name: LOGZIO_OBJECTS_LOGS_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: logzio-k8s-objects-logs-token
      {{- end -}}      
      {{- if .Values.secrets.env_id }}
      - name: ENV_ID
        valueFrom:
          secretKeyRef:
            name: {{ .Values.secrets.name }}
            key: env-id       
      {{- end -}}
      {{ end }}
      - name: LISTENER_URL
        value: {{ include "logzio.listenerAddress" . | quote }}    
      {{- if and (.Values.useGOMEMLIMIT) ((((.Values.resources).limits).memory))  }}
      - name: GOMEMLIMIT
        value: {{ include "metrics-collector.gomemlimit" .Values.resources.limits.memory | quote }}
      {{- end }}
      {{- with .Values.extraEnvs }}
      {{- . | toYaml | nindent 6 }}
      {{- end }}
    {{- with .Values.extraEnvsFrom }}
    envFrom:
    {{- . | toYaml | nindent 6 }}
    {{- end }}
    {{- with .Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
      {{- if .Values.configMap.create }}
      - mountPath: /conf
        name: {{ include "metrics-collector.lowercase_chartname" . }}-configmap
      {{- end }}
      - name: varlogpods
        mountPath: /var/log/pods
        readOnly: true
      - name: varlibdockercontainers
        mountPath: /var/lib/docker/containers
        readOnly: true
      - name: varlibotelcol
        mountPath: /var/lib/otelcol
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
  - name: {{ include "metrics-collector.lowercase_chartname" . }}-configmap
    configMap:
      name: {{ include "metrics-collector.fullname" . }}{{ .configmapSuffix }}
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
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
