#!/bin/sh
otelcontribcol_linux_amd64 --config /etc/opentelemetry/config.yaml > /dev/null 2>&1 &
dotnet-monitor collect