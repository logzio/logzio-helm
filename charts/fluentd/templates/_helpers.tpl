{{/* vim: set filetype=mustache: */}}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fluentd.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "fluentd.serviceAccount" -}}
{{- if .Values.isRBAC -}}
    {{ default (include "fluentd.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}


{{/*
Builds the full logzio listener host
*/}}
{{- define "logzio.listenerHost" }}
{{- if ne $.Values.global.customLogsEndpoint "" -}}
{{- printf "%s" .Values.global.customLogsEndpoint  }}
{{- else if or ( eq $.Values.global.logzioRegion "us" ) ( eq $.Values.global.logzioRegion " " ) -}}
{{- printf "https://listener.logz.io:8071" }}
{{- else }}
{{- printf "https://listener-%s.logz.io:8071" .Values.global.logzioRegion -}}
{{- end -}}
{{- end -}}

{{/*
Builds the fluent.conf with all the includes
*/}}
{{- define "logzio.includes" }}
{{- printf .Values.configMapIncludes }}
{{- if .Values.configmap.extraConfig -}}
{{- range $key, $value := fromYaml .Values.configmap.extraConfig }}
{{- printf "@include %s\n" $key }}
{{- end -}}
{{- end -}}
{{- printf "%s" .Values.configmap.fluent }}
{{- end -}}


{{/*
Builds the list for exclude paths in the tail for the containers
*/}}
{{- define "logzio.excludePath" }}
{{- if .Values.daemonset.extraExclude }}
{{- cat .Values.daemonset.excludeFluentdPath "," .Values.daemonset.extraExclude | nospace }}
{{- else }}
{{- print .Values.daemonset.excludeFluentdPath }}
{{- end -}}
{{- end -}}

{{/*
Builds the list for exclude paths in the tail for the containers - windows
*/}}
{{- define "logzio.windowsExcludePath" }}
{{- if .Values.windowsDaemonset.enabled }}
{{- if .Values.windowsDaemonset.extraExclude }}
{{- cat .Values.windowsDaemonset.excludeFluentdPath "," .Values.windowsDaemonset.extraExclude | nospace }}
{{- else }}
{{- print .Values.windowsDaemonset.excludeFluentdPath }}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Builds a filter based on log levels
*/}}
{{- define "logzio.logLevelFilter" }}
{{- if .Values.logLevelFilter }}
{{- cat "<filter **>\n    @type grep\n    regexp1 log_level" .Values.logLevelFilter "\n</filter>" | replace "\"" "" }}
{{- end -}}
{{- end -}}


{{/*
Builds the envId.conf to add env id field in the logs
*/}}
{{- define "logzio.envId" }}
{{- printf "%s" .Values.configmap.envId }}
{{- end -}}
