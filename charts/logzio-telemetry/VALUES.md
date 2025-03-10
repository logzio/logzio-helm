# logzio-k8s-telemetry

![Version: 2.0.0](https://img.shields.io/badge/Version-2.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.70.0](https://img.shields.io/badge/AppVersion-0.80.0-informational?style=flat-square)

logzio-k8s-telemetry allows you to ship metrics and traces from your Kubernetes cluster using the OpenTelemetry collector.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| yotamloe | <yotam.loewenbach@logz.io> |  |
| tamirmich | <tamir.michaeli@logz.io> |  |

## Source Code

* <https://github.com/prometheus/node_exporter>
* <https://github.com/kubernetes/kube-state-metrics>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://prometheus-community.github.io/helm-charts | kube-state-metrics | 4.24.0 |
| https://prometheus-community.github.io/helm-charts | prometheus-node-exporter | 4.23.2 |
| https://prometheus-community.github.io/helm-charts | prometheus-pushgateway | 2.4.2 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| collector.mode | string | `"daemonset"` | The mode in which that collector will be deployed. Possible values: `"standalone"`,`"daemonset"` Large scale clusters should use `daemonset`.|
| baseCollectorConfig.exporters.logging.loglevel | string | `"info"` | log level that will be used with the collector. The value must be updated for the service telemetry in order to take effect. |
| baseCollectorConfig.service.telemetry.logs.level | string | `"info"` | log level that will be used with the collector. The value must be updated for the exporter logging in order to take effect. |
| tracesConfig.exporters.logging.loglevel | string | `"info"` | log level that will be used with the collector. The value must be updated for the service telemetry in order to take effect. |
| tracesConfig.service.telemetry.logs.level | string | `"info"` | log level that will be used with the collector. The value must be updated for the exporter logging in order to take effect. |
| command.extraArgs | list | `[]` | Additional arguments for the opentelemetry collector. |
| command.name | string | `"otelcol-contrib"` | Command name for the opentelemetry collector executable. |
| disableKubeDnsScraping | bool | `false` | Enabling this flag will disable kube-dns service scraping. |
| enableMetricsFilter.aks | bool | `false` | Enable metric filtering for aks clusters - only base metrics will be sent. (general cluster,nodes,pods and container metrics)|
| enableMetricsFilter.eks | bool | `false` | Enable metric filtering for eks clusters - only base metrics will be sent. (general cluster,nodes,pods and container metrics) |
| enableMetricsFilter.gke | bool | `false` | Enable metric filtering for gke clusters - only base metrics will be sent. (general cluster,nodes,pods and container metrics) |
| enableMetricsFilter.dropKubeSystem | bool | `false` | Enable metric filtering for kube system metrics. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy for the opentelemetry collector image. |
| image.repository | string | `"otel/opentelemetry-collector-contrib"` | Opentelemetry collector image repository. |
| image.tag | string | `"0.78.0"` |  Opentelemetry collector image tag. |
| kubeStateMetrics.enabled | bool | `true` | Controlles the deployment of the kube-state-metrics sub chart. |
| applicationMetrics.enabled | bool | `false` | wheter or not to enable `applications` scrape job. |
| metrics.enabled | bool | `false` | Controlles the activation of metrics collection. |
| traces.enabled | bool | `false` | Controlles the activation of traces collection. |
| nameOverride | string | `"otel-collector"` | Name override for the opentelemetry collector. |
| nodeExporter.enabled | bool | `true` | Controlles the deployment of the node-exporter sub chart. |
| pushGateway.enabled | bool | `true` | Controlles the deployment of the prometheus-pushgateway sub chart. |
| global.logzioRegion | string | `"us"` | Logzio listener region. |
| global.logzioMetricsToken | string | `""` | Logzio metrics token. |
| global.logzioSpmToken | string | `""` | Logzio spm metrics token. |
| global.logzioTracesToken | string | `""` | Logzio traces token. |
| global.env_id | string | `"my_environment"` | Env id to be used with k8s 360. |
| secrets.windowsNodePassword | string | `""` | Windows node password - will be used to install node-exporter for windows nodes. |
| secrets.windowsNodeUsername | string | `""` | Windows username - will be used to install node-exporter for windows nodes. |
| standaloneCollector.resources.limits.cpu | string | `"200m"` | Cpu limit for the opentelemetry collector pod. |
| standaloneCollector.resources.limits.memory | string | `"512Mi"` | Memory limit for the opentelemetry colletor pods. |
| standaloneCollector.podLabels | string | `nil` | Selector labels that will be added to the collector pods. |
| standaloneCollector.podAnnotations | string | `nil` | Selector labels that will be added to the collector pods. |
| daemonsetCollector.resources.limits.cpu | string | `"150m"` | Cpu limit for the opentelemetry colletor pods. |
| daemonsetCollector.resources.limits.memory | string | `"250Mi"` | Memory limit for the opentelemetry colletor pods. |
| daemonsetCollector.podLabels | string | `nil` | Selector labels that will be added to the collector pods. |
| daemonsetCollector.podAnnotations | string | `nil` | Selector annotations that will be added to the collector pods. |
| windowsExporterInstallerJob.interval | string | `"*/10 * * * *"` | Cronjob expression for the windows exporter installer job. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
