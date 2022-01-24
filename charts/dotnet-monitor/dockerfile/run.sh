#!/bin/sh
otelcontribcol_linux_amd64 --config /etc/opentelemetry/config.yaml &
dotnet-monitor collect