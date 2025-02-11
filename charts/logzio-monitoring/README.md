# logzio-monitoring

The `logzio-monitoring` Helm Chart facilitates the process of sending Kubernetes telemetry data—such as logs, metrics, traces, and security reports—to your Logz.io account.

**Note:** This project is currently in *beta* and may undergo changes.

## Overview

This project packages the following Helm Charts:
- [logzio-fluentd](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd) for shipping logs via Fluentd.
- [logzio-logs-collector](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-logs-collector) for shipping logs via opentelemetry.
- [logzio-telemetry](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-telemetry) for metrics and traces via OpenTelemetry Collector.
- [logzio-trivy](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-trivy) for security reports via Trivy operator.
- [logzio-k8s-events](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-k8s-events) for Kubernetes deployment events.
- [logzio-apm-collector](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-apm-collector) for traces, span metrics and service graph via OpenTelemetry Collector.

### Kubernetes versions compatibility

| Chart Version | Kubernetes Version |
|---|---|
| > 3.0.0 | v1.22.0 - v1.28.0 |
| < 2.0.0 | <= v1.22.0 |

## Instructions for standard deployment:

### Before installing the chart

* Verify if any taints are present on your nodes:

```shell
kubectl get nodes -o json | jq '"\(.items[].metadata.name) \(.items[].spec.taints)"'
```

If so, add them as tolerations. For further explanation on modifying the chart, see the [further configuration section](#Further-configuration).

* You are using `Helm` client with version `v3.9.0` or above.

### 1. Add the Helm chart:

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

### 2. Deploy the chart:

Use the following command, and replace the placeholders with your parameters:

```shell
helm install -n monitoring \
--set logs.enabled=true \
--set global.logzioLogsToken="<<LOG-SHIPPING-TOKEN>>" \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
--set global.env_id="<<ENV-ID>>" \
--set logzio-k8s-telemetry.metrics.enabled=true \
--set global.logzioMetricsToken="<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>" \
--set logzio-apm-collector.enabled=true \
--set global.logzioTracesToken="<<TRACES-SHIPPING-TOKEN>>" \
--set logzio-apm-collector.spm.enabled=true \
--set global.logzioSpmToken=<<SPM-SHIPPING-TOKEN>> \
--set logzio-apm-collector.serviceGraph.enabled=true \
--set logzio-k8s-telemetry.k8sObjectsConfig.enabled=true \
--set securityReport.enabled=true \
--set deployEvents.enabled=true \
logzio-monitoring logzio-helm/logzio-monitoring
```

| Parameter | Description |
| --- | --- |
| `<<LOG-SHIPPING-TOKEN>>` | Your [logs shipping token](https://app.logz.io/#/dashboard/settings/general). |
| `<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>` | Your [metrics shipping token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping). |
| `<<ENV-ID>>` | The name for your environment's identifier, to easily identify the telemetry data for each environment. |
| `<<TRACES-SHIPPING-TOKEN>>` | Your [traces shipping token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping). |
| `<<SPM-SHIPPING-TOKEN>>` | Your [span metrics shipping token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping). |
| `<<LOGZIO-REGION>>` | Your Logz.io region code, e.g `us`, `eu`... |


### Further configuration

The `helm install` command described above deploys a standard configuration of the chart for sending logs, metrics, and traces.

However, you can customize the chart by using the `--set` flag in your `helm install` command:

| Parameter	| Description | Default |
| --- | --- | --- |
| `logs.enabled` | Enable to send Kubernetes logs | `false` |
| `securityReport.enabled` | Enable to send Kubernetes security logs | `false` |
| `deployEvents.enabled` | Enable to send Kubernetes deploy events logs | `false` |

#### Modifying Chart Configurations

For each chart, you can customize configuration values using the `--set` flag during the `helm install` or `helm upgrade` commands. The prefix for the values depends on the chart you're modifying.

Full list of available configuration per sub chart:
- [logzio-logs-collector Chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-logs-collector#configuration)
- [logzio-fluentd Chart](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd#configuration)
- [logzio-k8s-telemetry Chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-telemetry)
- [logzio-apm-collector Chart](https://github.com/logzio/logzio-helm/blob/master/charts/logzio-apm-collector/VALUES.md)
- [logzio-trivy Chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-trivy#further-configuration)
- [logzio-k8s-events Chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-k8s-events)


If you want to modify one of the values, use the `--set` flag, and add the chart name as prefix.

```shell
--set sub-chart-name.someField="my new value"
```

For example, to change a value named `someField` in `logzio-fluentd`'s `values.yaml` file, include the following in your `helm install` command:

```shell
--set logzio-fluentd.someField="my new value"
```

> [!NOTE]
> You can add `log_type` annotation with a custom value, which will be parsed into a `log_type` field with the same value.

### Sending telemetry data from eks on fargate

To ship logs from pods running on Fargate, set the `fargateLogRouter.enabled` value to `true`. This will deploy a dedicated `aws-observability` namespace and a `configmap` for the Fargate log router. More information about EKS Fargate logging can be found [here](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html)

```shell
helm install -n monitoring \
--set logs.enabled=true \
--set global.env_id="<<ENV-ID>>" \
--set logzio-logs-collector.fargateLogRouter.enabled=true \
--set global.logzioLogsToken="<<LOG-SHIPPING-TOKEN>>" \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
--set logzio-k8s-telemetry.metrics.enabled=true \
--set global.logzioMetricsToken="<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>" \
--set logzio-apm-collector.enabled=true \
--set global.logzioTracesToken="<<TRACES-SHIPPING-TOKEN>>" \
logzio-monitoring logzio-helm/logzio-monitoring
```

Then use `kubectl port-forward` to accsess the user intefrace in your browser:

```shell
kubectl port-forward svc/ezkonnect-ui -n monitoring 31032:31032
```

### Handling image pull rate limit

In scenarios (e.g., spot clusters) where pods/nodes are frequently replaced, you may encounter Dockerhub's pull rate limits. In these cases, use the following `--set` commands to use alternative image repositories:

```
You have reached your pull rate limit. You may increase the limit by authenticating and upgrading: https://www.docker.com/increase-rate-limits.
```


In these cases we can use the following `--set` commands to use an alternative image repository:

```shell
--set logzio-k8s-telemetry.image.repository=ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib
--set logzio-k8s-telemetry.prometheus-pushgateway.image.repository=public.ecr.aws/logzio/prom-pushgateway
--set logzio-fluentd.image=public.ecr.aws/logzio/logzio-fluentd
--set logzio-trivy.image=public.ecr.aws/logzio/trivy-to-logzio
```

### Send logs to a custom endpoint

Set `global.customLogsEndpoint` value to send your logs to a custom endpoint

```shell
--set global.customLogsEndpoint="<<CUSTOM_ENDPOINT>>" 
```

### Send Traces to a custom endpoint

Set `global.customTracesEndpoint` value to send your traces to a custom endpoint, or `global.customSpmEndpoint` to send your span metrics to a custom endpoint

```shell
--set global.customTracesEndpoint="<<CUSTOM_TRACING_ENDPOINT>>" \
--set global.customSpmEndpoint="<<CUSTOM_SPM_ENDPOINT>>" 
```

### Send metrics to a custom endpoint

Set logzio-k8s-telemetry `ListenerHost` value to send your metrics to a custom endpoint (example: "https://endpoint.com:8080")

```shell
--set global.customMetricsEndpoint="<<CUSTOM_METRICS_ENDPOINT>>"
```

### Adding Tolerations for Tainted Nodes

To ensure that your pods can be scheduled on nodes with taints, you need to add tolerations to the relevant sub-charts. Here is how you can configure tolerations for each sub-chart within the `logzio-monitoring` Helm chart:

1. **Identify the taints on your nodes:**
   ```shell
   kubectl get nodes -o json | jq '"\(.items[].metadata.name) \(.items[].spec.taints)"'
   ```
2. **Add tolerations to the Helm install command**:
You can add tolerations by using the --set flag in your helm install command. Replace the placeholders with your taint values.
- For `logzio-logs-collector`:
```shell
--set logzio-logs-collector.tolerations[0].key="<<TAINT-KEY>>" \
--set logzio-logs-collector.tolerations[0].operator="<<TAINT-OPERATOR>>" \
--set logzio-logs-collector.tolerations[0].value="<<TAINT-VALUE>>" \
--set logzio-logs-collector.tolerations[0].effect="<<TAINT-EFFECT>>"
```
- For `logzio-k8s-telemetry`:
```shell
--set logzio-k8s-telemetry.tolerations[0].key="<<TAINT-KEY>>" \
--set logzio-k8s-telemetry.tolerations[0].operator="<<TAINT-OPERATOR>>" \
--set logzio-k8s-telemetry.tolerations[0].value="<<TAINT-VALUE>>" \
--set logzio-k8s-telemetry.tolerations[0].effect="<<TAINT-EFFECT>>"
```
- For `logzio-trivy`:
```shell
--set logzio-trivy.tolerations[0].key="<<TAINT-KEY>>" \
--set logzio-trivy.tolerations[0].operator="<<TAINT-OPERATOR>>" \
--set logzio-trivy.tolerations[0].value="<<TAINT-VALUE>>" \
--set logzio-trivy.tolerations[0].effect="<<TAINT-EFFECT>>"
```
- For `logzio-k8s-events`:
```shell
--set logzio-k8s-events.tolerations[0].key="<<TAINT-KEY>>" \
--set logzio-k8s-events.tolerations[0].operator="<<TAINT-OPERATOR>>" \
--set logzio-k8s-events.tolerations[0].value="<<TAINT-VALUE>>" \
--set logzio-k8s-events.tolerations[0].effect="<<TAINT-EFFECT>>"
```
Replace `<<TAINT-KEY>>`, `<<TAINT-OPERATOR>>`, `<<TAINT-VALUE>>`, and `<<TAINT-EFFECT>>` with the appropriate values for your taints.

By following these steps, you can ensure that your pods are scheduled on nodes with taints by adding the necessary tolerations to the Helm chart configuration.

## Migrating to `logzio-monitoring` 7.0.0

### Step 1: Update helm repositories

Run the following command to ensure you have the latest chart versions:

```shell
helm repo update
```

### Step 2: Build the upgrade command

Choose the appropriate upgrade command for your current setup. If you're unsure of your configuration, use the following command to retrieve the current values

```shell
helm get values logzio-monitoring -n monitoring
```

> [!IMPORTANT]
> If you have enabled any of the following
> - `logzio-k8s-events` (`deployEvents`)
> - `logzio-trivy` (`securityReport`)
> - `logzio-k8s-telemetry.k8sObjectsConfig`
> You must use one of the Logs command options as part of the upgrade process.

<details>
  <summary>Logs, Metrics and Traces:</summary>

```shell
helm upgrade logzio-monitoring logzio-helm/logzio-monitoring -n monitoring \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
--set global.env_id="<<ENV-ID>>" \
--set global.logzioLogsToken="<<LOG-SHIPPING-TOKEN>>" \
--set global.logzioMetricsToken="<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>" \
--set logzio-k8s-telemetry.traces.enabled=false \
--set logzio-apm-collector.enabled=true \
--set global.logzioTracesToken="<<TRACES-SHIPPING-TOKEN>>" \

# If you also send SPM or ServiceGraph, add the relevant enable flag for them and the token
--set logzio-apm-collector.spm.enabled=true \
--set logzio-apm-collector.serviceGraph.enabled=true \
--set global.logzioSpmToken="<<SPM-SHIPPING-TOKEN>>" \

--reuse-values
```

> [!NOTE]
> If you were using `logzio-logs-collector.secrets.logType`, add to your command `--set global.logType=<<LOG-TYPE>> \`

</details>

<details>
  <summary>Logs and Metrics:</summary>

```shell
helm upgrade logzio-monitoring logzio-helm/logzio-monitoring -n monitoring \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
--set global.env_id="<<ENV-ID>>" \
--set global.logzioLogsToken="<<LOG-SHIPPING-TOKEN>>" \
--set global.logzioMetricsToken="<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>" \

--reuse-values
```

> [!NOTE]
> If you were using `logzio-logs-collector.secrets.logType`, add to your command `--set global.logType=<<LOG-TYPE>> \`

</details>

<details>
  <summary>Metrics and Traces:</summary>

```shell
helm upgrade logzio-monitoring logzio-helm/logzio-monitoring -n monitoring \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
--set global.env_id="<<ENV-ID>>" \
--set global.logzioMetricsToken="<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>" \
--set logzio-k8s-telemetry.traces.enabled=false \
--set logzio-apm-collector.enabled=true \
--set global.logzioTracesToken="<<TRACES-SHIPPING-TOKEN>>" \

# If you also send SPM or ServiceGraph, add the relevant enable flag for them and the token
--set logzio-apm-collector.spm.enabled=true \
--set logzio-apm-collector.serviceGraph.enabled=true \
--set global.logzioSpmToken="<<SPM-SHIPPING-TOKEN>>" \

--reuse-values
```

</details>

<details>
  <summary>Logs and Traces:</summary>

```shell
helm upgrade logzio-monitoring logzio-helm/logzio-monitoring -n monitoring \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
--set global.env_id="<<ENV-ID>>" \
--set global.logzioLogsToken="<<LOG-SHIPPING-TOKEN>>" \
--set logzio-k8s-telemetry.traces.enabled=false \
--set logzio-apm-collector.enabled=true \
--set global.logzioTracesToken="<<TRACES-SHIPPING-TOKEN>>" \

# If you also send SPM or ServiceGraph, add the relevant enable flag for them and the token
--set logzio-apm-collector.spm.enabled=true \
--set logzio-apm-collector.serviceGraph.enabled=true \
--set global.logzioSpmToken="<<SPM-SHIPPING-TOKEN>>" \

--reuse-values
```

> [!NOTE]
> If you were using `logzio-logs-collector.secrets.logType`, add to your command `--set global.logType=<<LOG-TYPE>> \`

</details>


<details>
  <summary>Only Logs:</summary>

```shell
helm upgrade logzio-monitoring logzio-helm/logzio-monitoring -n monitoring \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
--set global.env_id="<<ENV-ID>>" \
--set global.logzioLogsToken="<<LOG-SHIPPING-TOKEN>>" \

--reuse-values
```

> [!NOTE]
> If you were using `logzio-logs-collector.secrets.logType`, add to your command `--set global.logType=<<LOG-TYPE>> \`

</details>

<details>
  <summary>Only Metrics:</summary>

```shell
helm upgrade logzio-monitoring logzio-helm/logzio-monitoring -n monitoring \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
--set global.env_id="<<ENV-ID>>" \
--set global.logzioMetricsToken="<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>" \
--reuse-values
```

</details>

<details>
  <summary>Only Traces:</summary>

```shell
helm upgrade logzio-monitoring logzio-helm/logzio-monitoring -n monitoring \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
--set global.env_id="<<ENV-ID>>" \
--set logzio-k8s-telemetry.traces.enabled=false \
--set logzio-apm-collector.enabled=true \
--set global.logzioTracesToken="<<TRACES-SHIPPING-TOKEN>>" \

# If you also send SPM or ServiceGraph, add the relevant enable flag for them and the token
--set logzio-apm-collector.spm.enabled=true \
--set logzio-apm-collector.serviceGraph.enabled=true \
--set global.logzioSpmToken="<<SPM-SHIPPING-TOKEN>>" \

--reuse-values
```

</details>

#### Managing own secret
If you manage your own secret for the Logz.io charts, please also add to your command:

 ```shell
--set sub-chart-name.secret.name="<<NAME-OF-SECRET>>" \
--set sub-chart-name.secret.enabled=false \
```

> [!IMPORTANT]
> This change is not relevant for the `logzio-k8s-telemetry` chart.

Replace `sub-chart-name` with the name of the sub chart which you manage the secrets for.

For example, if you manage secret for both `logzio-logs-collector` and for `logzio-trivy`, use:

 ```shell
helm upgrade logzio-monitoring logzio-helm/logzio-monitoring -n monitoring \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
--set global.env_id="<<ENV-ID>>" \
--set logzio-logs-collector.secret.name="<<NAME-OF-SECRET>>" \
--set logzio-logs-collector.secret.enabled=false \
--set logzio-trivy.secret.name="<<NAME-OF-SECRET>>" \
--set logzio-trivy.secret.enabled=false \
--reuse-values
```
