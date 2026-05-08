{{/*
Expand the name of the chart.
*/}}
{{- define "kubevirt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kubevirt.fullname" -}}
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
{{- define "kubevirt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kubevirt.labels" -}}
helm.sh/chart: {{ include "kubevirt.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "kubevirt.selectorLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kubevirt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kubevirt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Image tag helper
*/}}
{{- define "kubevirt.image" -}}
{{- $tag := default .Chart.AppVersion .Values.operator.image.tag }}
{{- printf "%s/%s:%s" .Values.operator.image.registry .Values.operator.image.repository $tag }}
{{- end }}

{{/* SA helper name */}}
{{- define "kubevirt.operator.name" -}}
kubevirt-operator
{{- end }}

{{/* Hook SA helper name */}}
{{- define "kubevirt.hook.serviceaccount" -}}
{{ printf "%s-hook" (include "kubevirt.fullname" .) }}
{{- end }}

{{/* Hook RBAC helper name */}}
{{- define "kubevirt.hook.rbac.hook" -}}
{{ printf "%s-hook" (include "kubevirt.fullname" .) }}
{{- end }}

{{/* Hook RBAC cluster helper name */}}
{{- define "kubevirt.hook.rbac.namespace" -}}
{{ printf "%s-namespace" (include "kubevirt.fullname" .) }}
{{- end }}
