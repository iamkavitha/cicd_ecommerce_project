{{/*
Chart name
*/}}

{{- define "shoprupee.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Full application name
*/}}

{{- define "shoprupee.fullname" -}}

{{- if .Values.fullnameOverride }}

{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}

{{- else }}

{{- include "shoprupee.name" . }}

{{- end }}

{{- end }}


{{/*
Selector labels
*/}}

{{- define "shoprupee.selectorLabels" -}}

app: {{ include "shoprupee.name" . }}

{{- end }}
