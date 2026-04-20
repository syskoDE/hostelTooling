{{- define "hostel-tooling.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hostel-tooling.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "hostel-tooling.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "hostel-tooling.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hostel-tooling.labels" -}}
helm.sh/chart: {{ include "hostel-tooling.chart" . }}
app.kubernetes.io/name: {{ include "hostel-tooling.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "hostel-tooling.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hostel-tooling.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "hostel-tooling.qdrantFullname" -}}
{{- printf "%s-qdrant" (include "hostel-tooling.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hostel-tooling.prometheusFullname" -}}
{{- printf "%s-prometheus" (include "hostel-tooling.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "hostel-tooling.grafanaFullname" -}}
{{- printf "%s-grafana" (include "hostel-tooling.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
