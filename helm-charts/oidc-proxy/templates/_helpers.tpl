{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "oidc-proxy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "oidc-proxy.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "oidc-proxy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the names of ConfigMaps and Secrets.
*/}}
{{- define "oidc-proxy.configmapNameConfig" -}}
{{- printf "%s-%s" (include "oidc-proxy.fullname" .) "config" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "oidc-proxy.configmapNameAuth" -}}
{{- printf "%s-%s" (include "oidc-proxy.fullname" .) "auth" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "oidc-proxy.secretName" -}}
{{- printf "%s-%s" (include "oidc-proxy.fullname" .) "secret" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
