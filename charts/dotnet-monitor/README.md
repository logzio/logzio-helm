# Logz.io Dotnet-Monitor Helm Chart

[Helm](https://helm.sh/) is a tool for managing packages of pre-configured Kubernetes resources using Charts.
logzio-dotnet-monitor allows you to collect and ship diagnostic metrics of your .Net application in Kubernetes to Logz.io, 
using dotnet-monitor and OTEL.

logzio-dotnet-monitor runs as a sidecar in the same pod as the .Net application.

## Deploying The Chart:

### Add Your .Net Application Container to Deployment Config

Replace the **dotnet-app** container with your .Net application container in deployment.yaml.
Make sure to keep the diagnostics volumeMount:

```yaml
volumeMounts:
  - mountPath: /tmp
    name: diagnostics
```

### Configuration

This table contains all the parameters in values.yaml:

| Parameter | Description | Default |
|---|---|---|
| `nameOverride` | Overrides the Chart name for resources. | `""` |
| `fullnameOverride` | Overrides the full name of the resources. | `""` |
| `apiVersions.deployment` | Deployment API version. | `apps/v1` |
| `apiVersions.configmap` | Configmap API version. | `v1` |
| `apiVersions.secret` | Secret API version. | `v1` |
| `namespace` | Chart's namespace. | `default` |
| `replicaCount` | The number of replicated pods, the deployment creates. | `1` |
| `labels` | Pod's labels. | `{}` |
| `annotations` | Pod's annotations. | `{}` |
| `logzioDotnetMonitor.name` | The name of the container that collects and ships diagnostic metrics of your .Net application to Logz.io (sidecar) | `logzio-dotnet-monitor` |
| `logzioDotnetMonitor.image.name` | The image name that is going to run in `logzioDotnetMonitor.name` container | `logzio/logzio-dotnet-monitor` |
| `logzioDotnetMonitor.image.tag` | The tag of the image that is going to run in `logzioDotnetMonitor.name` container | `latest` |
| `logzioDotnetMonitor.ports` | List of ports the `logzioDotnetMonitor.name` container exposes | `52325` |
| `secrets.logzioURL` | Secret with your logzio url. | `https://listener.logz.io:8053` |
| `secrets.logzioToken` | Secret with your logzio metrics token. | `""` |
| `configMap.dotnetMonitor` | The dotnet-monitor configuration. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/dotnet-monitor/values.yaml). |
| `configMap.opentelemetry` | The opentelemetry  configuration. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/dotnet-monitor/values.yaml). |

- Use this [link](https://github.com/dotnet/dotnet-monitor/blob/main/documentation/configuration.md#metrics-configuration) to get additional information about dotnet-monitor configuration.
- Use this [link](https://docs.microsoft.com/en-us/dotnet/core/diagnostics/available-counters) to see well-known providers and their counters.

### Deploy

Run the following command to install the Chart. Change `<<CHART_FILE_LOCATION>>` to the path to Chart.yaml.
(Make sure to set your `secrets.logzioURL` and `secrets.logzioToken` before installing the Chart)

```shell
helm install logzio-dotnet-monitor <<CHART_FILE_LOCATION>>
```

### Check Logz.io for Your Metrics

Give your metrics some time to get from your system to Logz.io.
You can search for your metrics in Logz.io by searching `{job="dotnet-monitor-collector"}`