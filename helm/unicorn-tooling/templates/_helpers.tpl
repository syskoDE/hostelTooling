{{- define "unicorn-tooling.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "unicorn-tooling.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "unicorn-tooling.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "unicorn-tooling.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "unicorn-tooling.labels" -}}
helm.sh/chart: {{ include "unicorn-tooling.chart" . }}
app.kubernetes.io/name: {{ include "unicorn-tooling.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "unicorn-tooling.selectorLabels" -}}
app.kubernetes.io/name: {{ include "unicorn-tooling.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "unicorn-tooling.qdrantFullname" -}}
{{- printf "%s-qdrant" (include "unicorn-tooling.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "unicorn-tooling.prometheusFullname" -}}
{{- printf "%s-prometheus" (include "unicorn-tooling.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "unicorn-tooling.grafanaFullname" -}}
{{- printf "%s-grafana" (include "unicorn-tooling.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
