{{- define "opentelemetry-collector.multicollector-pod" -}}
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
    env:
      - name: MY_POD_IP
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: status.podIP
      - name: K8S_360_METRICS
        valueFrom:
          secretKeyRef:
            name: {{ include "opentelemetry-collector.secretName" $ }}
            key: kubernetes-360-metrics
      - name: LOGZIO_AGENT_VERSION
        value: {{.Chart.Version}}
      - name: REALESE_NAME
        value: {{.Release.Name}}
      - name: REALESE_NS
        value: {{.Release.Namespace}}
      - name: METRICS_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ include "opentelemetry-collector.secretName" $ }}
            key: logzio-metrics-shipping-token
      - name: LISTENER_URL
        valueFrom:
          secretKeyRef:
            name: {{ include "opentelemetry-collector.secretName" $ }}
            key: logzio-metrics-listener
      - name: P8S_LOGZIO_NAME
        valueFrom:
          secretKeyRef:
            name: {{ include "opentelemetry-collector.secretName" $ }}
            key: p8s-logzio-name
      - name: ENV_ID
        valueFrom:
          secretKeyRef:
            name: {{ include "opentelemetry-collector.secretName" $ }}
            key: env_id
      - name: TARGET_NAMESPACE
        value: {{.targetNamespace}}
{{- if .Values.opencost.enabled }}
      - name: OPENCOST_DUPLICATES
        valueFrom:
          secretKeyRef:
            name: {{ include "opentelemetry-collector.secretName" $ }}
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
      {{- if index .Values "namespace" .targetNamespace -}}
        {{- $collectorCustomResources := index .Values "namespace" .targetNamespace "resources" -}}
        {{- if $collectorCustomResources -}}
          {{- $collectorCustomResources | toYaml | nindent 6 }}
        {{- else -}}
          {{- .Values.defaultResources | toYaml | nindent 6 }}
        {{- end -}}
      {{- end }}
    volumeMounts:
      - mountPath: /conf
        name: {{ .Chart.Name }}-configmap-{{ .targetNamespace }}
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
  - name: {{ .Chart.Name }}-configmap-{{ .targetNamespace }}
    configMap:
      name: {{ include "opentelemetry-collector.fullname"  $ }}
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
{{- with .Values.multiCollector.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}