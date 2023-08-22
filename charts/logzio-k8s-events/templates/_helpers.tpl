{{/*
Expand the name of the chart.
*/}}
{{- define "logzio-k8s-events.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "logzio-k8s-events.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "logzio-k8s-events.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "logzio-k8s-events.labels" -}}
helm.sh/chart: {{ include "logzio-k8s-events.chart" . }}
geo_region: {{ required "A valid Values.region is required!" .Values.region }}
service: {{ include "logzio-k8s-events.name" . }}
{{ include "logzio-k8s-events.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}



{{/*
Fin ops labels
*/}}
{{- define "logzio-k8s-events.finopsLabels" -}}
environment: {{ required "A valid Values.finopsLabels.environment is required!" .Values.finopsLabels.environment }}
product: {{ required "A valid Values.finopsLabels.product is required!" .Values.finopsLabels.product }}
traffic: {{ required "A valid Values.finopsLabels.traffic is required!" .Values.finopsLabels.traffic }}
owner: {{ required "A valid Values.finopsLabels.owner is required!" .Values.finopsLabels.owner }}
role: {{ required "A valid Values.finopsLabels.role is required!" .Values.finopsLabels.role }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "logzio-k8s-events.selectorLabels" -}}
{{- if .Values.roleLabel -}}
role: {{ .Values.roleLabel }}
{{- else -}}
role: {{ include "logzio-k8s-events.name" . }}
{{- end }}
helm-release: {{ .Release.Name }}
app.kubernetes.io/name: {{ include "logzio-k8s-events.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "logzio-k8s-events.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "logzio-k8s-events.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Builds the full logzio listener host
*/}}
{{- define "logzio.listenerHost" }}
{{- if or ( eq $.Values.secrets.logzioListener "listener.logz.io" ) ( eq $.Values.secrets.logzioListener " " ) -}}
{{- printf "https://listener.logz.io:8071" }}
{{- else }}
{{- printf "https://%s:8071" .Values.secrets.logzioListener -}}
{{- end -}}
{{- end -}}