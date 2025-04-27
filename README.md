# Logzio Kubernetes Helm Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) 

Helm is a tool for managing packages of pre-configured Kubernetes resources using Charts.   
This repository contains Helm charts for shipping logs, metrics, and traces to Logz.io. 

## Charts

Please refer to the documentation in each chart directory for more details:

- [Logzio Monitoring](./charts/logzio-monitoring/README.md)  
  A unified chart for shipping logs, metrics, traces, and SPM.
  - [Logzio Trivy](./charts/logzio-trivy/README.md)  
    A chart for integrating Trivy vulnerability scanner with Logz.io.
  - [Logzio K8S Events](./charts/logzio-k8s-events/README.md)  
    A chart for shipping Kubernetes events to Logz.io.
  - [Fluentd](./charts/fluentd/README.md)  
    A chart for shipping logs using Fluentd.
- [Logzio API Fetcher](./charts/logzio-api-fetcher/README.md)  
  A chart to retrive logs from custom apis.
- [Dotnet Monitor](./charts/dotnet-monitor/README.md)  
  A chart for monitoring .NET applications.
- [Fluentbit](./charts/fluentbit/README.md)  
  A chart for shipping logs using Fluent Bit.

## Contributing

Please see [CONTRIBUTING.md](./CONTRIBUTING.md).