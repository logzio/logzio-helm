# Logzio Kubernetes Helm Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) 

Helm is a tool for managing packages of pre-configured Kubernetes resources using Charts.   
This repository contains Helm charts for shipping logs, metrics, and traces to Logz.io. 

## Charts

Please refer to the documentation in each chart directory for more details:

- [Logzio Monitoring](./charts/logzio-monitoring/README.md)  
  A unified chart for shipping logs, metrics, traces, and SPM.
  - [Logzio Logs collector](./charts/logzio-logs-collector/README.md)  
  A chart for shipping logs using OpenTelemetry to Logz.io.
  - [Logzio APM collector](./charts/logzio-apm-collector/README.md)  
  A chart for shipping traces and span metrics to Logz.io.
  - [Logzio Telemetry collector](./charts/logzio-telemetry/README.md)  
  A chart for sending metrics to Logz.io.
  - [Logzio Trivy](./charts/logzio-trivy/README.md)  
    A chart for integrating Trivy vulnerability scanner with Logz.io.
  - [Logzio K8S Events](./charts/logzio-k8s-events/README.md)  
    A chart for shipping Kubernetes events to Logz.io.
- [Logzio API Fetcher](./charts/logzio-api-fetcher/README.md)  
  A chart to retrive logs from custom apis.
- [Dotnet Monitor](./charts/dotnet-monitor/README.md)  
  A chart for monitoring .NET applications.
- [Prometheus alerts migrator](./charts/prometheus-alerts-migrator/README.md)  
  A chart for migrating Prometheus alert rules to Logz.io's alert format.
- [OBI](./charts/obi/README.md) OpenTelemetry eBPF Instrumentation (OBI) for Kubernetes zero-code auto-instrumentation


## Contributing

Please see [CONTRIBUTING.md](./CONTRIBUTING.md).