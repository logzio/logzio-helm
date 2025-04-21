# logzio-monitoring

The `logzio-monitoring` Helm Chart facilitates the process of sending Kubernetes telemetry data—such as logs, metrics, traces, and security reports—to your Logz.io account.

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

### Table of content
- [Installation instructions](#instructions-for-standard-deployment)
  - [EKS on fargate](#sending-telemetry-data-from-eks-on-fargate)
  - [Custom config](#further-configuration)
    - [Custom endpoint for logs](#send-logs-to-a-custom-endpoint)
    - [Custom endpoint for metrics](#send-metrics-to-a-custom-endpoint)
    - [Custom endpoint for traces](#send-traces-to-a-custom-endpoint)
  - [Image pull rate limit issue](#handling-image-pull-rate-limit)
  - [Add tolerations for tainted nodes](#adding-tolerations-for-tainted-nodes)
- [Migrating to logzio-monitoring v7.0.0](#migrating-to-logzio-monitoring-700)
- [Enabled Auto-Instrumentation](#enable-auto-instrumentation)

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

### Adding Global Tolerations

Global tolerations allow you to define tolerations that apply to all subcharts in the `logzio-monitoring` Helm chart. This simplifies the process of managing tolerations across multiple components.

1. **Identify the taints on your nodes:**
Run the following command to list the taints on your nodes:

```shell
kubectl get nodes -o json | jq '"\(.items[].metadata.name) \(.items[].spec.taints)"'
```

2. **Add globsl tolerations to the Helm install command**:

You can add global tolerations by using the `--set` flag in your `helm install` or `helm upgrade` command. Replace the placeholders with the appropriate values for your taints.

```shell
--set global.tolerations[0].key="<<TAINT-KEY>>" \
--set global.tolerations[0].operator="<<TAINT-OPERATOR>>" \
--set global.tolerations[0].value="<<TAINT-VALUE>>" \
--set global.tolerations[0].effect="<<TAINT-EFFECT>>"
```

For example, to tolerate the `CriticalAddonsOnly:NoSchedule` taint, use the following command:

```shell
helm upgrade -n monitoring \
  --reuse-values \
  --set global.tolerations[0].key="CriticalAddonsOnly" \
  --set global.tolerations[0].operator="Exists" \
  --set global.tolerations[0].effect="NoSchedule" \
  logzio-monitoring logzio-helm/logzio-monitoring
```

> **Note:** Global tolerations are supported in all subcharts starting from version `7.2.0`.

### Adding Tolerations for Tainted Nodes

To ensure that your pods can be scheduled on nodes with taints, you need to add tolerations to the relevant sub-charts. Here is how you can configure tolerations for each sub-chart within the `logzio-monitoring` Helm chart:

1. **Identify the taints on your nodes:**
   ```shell
   kubectl get nodes -o json | jq '"\(.items[].metadata.name) \(.items[].spec.taints)"'
   ```
2. **Add tolerations to the Helm install command**:
You can add tolerations by using the --set flag in your helm install command. Replace the placeholders with your taint and subchart values.

Replace `<SUBCHART>` with one of the following options:
- logzio-logs-collector
- logzio-k8s-telemetry
- logzio-trivy
- logzio-k8s-events

```shell
--set '<SUBCHART>.tolerations[0].key=<<TAINT-KEY>>' \
--set '<SUBCHART>.tolerations[0].operator=<<TAINT-OPERATOR>>' \
--set '<SUBCHART>.tolerations[0].value=<<TAINT-VALUE>>' \
--set '<SUBCHART>.tolerations[0].effect=<<TAINT-EFFECT>>'
```

Replace `<<TAINT-KEY>>`, `<<TAINT-OPERATOR>>`, `<<TAINT-VALUE>>`, and `<<TAINT-EFFECT>>` with the appropriate values for your taints.

For example, if you need to tolerate the CriticalAddonsOnly:NoSchedule taint for the logzio-logs-collector after installation, you could use:

```shell
helm upgrade -n monitoring \
  --reuse-values \
  --set 'logzio-logs-collector.tolerations[0].key=CriticalAddonsOnly' \
  --set 'logzio-logs-collector.tolerations[0].operator=Exists' \
  --set 'logzio-logs-collector.tolerations[0].effect=NoSchedule' \
  logzio-monitoring logzio-helm/logzio-monitoring
```

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

> [!IMPORTANT]
> Make sure to update your Instrumentation service endpoint from `logzio-monitoring-otel-collector.monitoring.svc.cluster.local` to `logzio-apm-collector.monitoring.svc.cluster.local`.

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

> [!IMPORTANT]
> Make sure to update your Instrumentation service endpoint from `logzio-monitoring-otel-collector.monitoring.svc.cluster.local` to `logzio-apm-collector.monitoring.svc.cluster.local`.

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

> [!IMPORTANT]
> Make sure to update your Instrumentation service endpoint from `logzio-monitoring-otel-collector.monitoring.svc.cluster.local` to `logzio-apm-collector.monitoring.svc.cluster.local`.

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

> [!IMPORTANT]
> Make sure to update your Instrumentation service endpoint from `logzio-monitoring-otel-collector.monitoring.svc.cluster.local` to `logzio-apm-collector.monitoring.svc.cluster.local`.

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

## Enable Auto-instrumentation

The Opentelemetry Operator manages auto-instrumentation of workloads using OpenTelemetry instrumentation libraries, automatically generating traces and metrics.

To send the instrumentation data it generates to Logz.io, you need to enable the operator within the `logzio-monitoring` chart, along with either the `logzio-apm-collector` (for traces), `logzio-k8s-telemetry` (for metrics), or both, depending on the type of data you want to forward to the Logz.io platform.

Follow the guide below to enable this feature.

> [!WARNING]
> The Operator does not support Windows nodes at the moment.


- [Step by step guide](#enable-auto-instrumentation)
  - [Multi-container pods](#multi-container-pods)
- [Customize Auto-instrumentation](#customize-auto-instrumentation)
  - [Customize Propagator](#customize-propagator)
  - [Add a custom Sampler](#add-a-custom-sampler)
  - [TLS certificate Requirements](#tls-certificate-requirements)

### Step by step

#### Step 1:
Make sure to enable the OpenTelemetry operator in the chart:
```shell
--set otel-operator.enabled=true \
```

> [!NOTE]
> It can take a few minutes for the OpenTelemetry Operator components to be installed and deployed on your cluster.

#### Step 2:
Add annotations to your relevant Kubernetes object. You can annotate individual resources such as a Deployment, StatefulSet, DaemonSet, or Pod, or apply annotations at the Namespace level to instrument all pods within that namespace. These annotations should specify the programming language used in your application:
```yaml
instrumentation.opentelemetry.io/inject-<APP_LANGUAGE>: "monitoring/logzio-monitoring-instrumentation"
```

> [!TIP]
> `<APP_LANGUAGE>` can be one of `apache-httpd`, `dotnet`, `go`, `java`, `nginx`, `nodejs` or `python`.

> [!IMPORTANT]
> If the chart is deployed in a namespace other than `monitoring`, adjust the annotation to reflect the correct namespace.

### Multi-container pods
By default, in multi-container pods, instrumentation is performed on the first container available in the pod spec.
To fine tune which containers to instrument, add the below annotations to your pod:
```yaml
instrumentation.opentelemetry.io/inject-<APP_LANGUAGE>: "monitoring/logzio-monitoring-instrumentation"
instrumentation.opentelemetry.io/<APP_LANGUAGE>-container-names: "myapp,myapp2"
instrumentation.opentelemetry.io/inject-<APP_LANGUAGE_2>: "monitoring/logzio-monitoring-instrumentation"
instrumentation.opentelemetry.io/<APP_LANGUAGE_2>-container-names: "myapp3"
```

> [!TIP]
> `<APP_LANGUAGE>`, `<APP_LANGUAGE_2>` can be one of `apache-httpd`, `dotnet`, `go`, `java`, `nginx`, `nodejs` or `python`.

> [!WARNING]
> Go auto-instrumentation does not support multicontainer pods.

## Customize Auto-instrumentation
Below you can find multiple ways in which you can customize the OpenTelemetry Operator Auto-instrumentation.

### Customize Propagator
The propagator specifies how context is injected into and extracted from carriers for distributed tracing.
By default, the propagators `tracecontext` (W3C Trace Context) and `baggage` (W3C Correlation Context) are enabled.
You can customize this to include other formats ([full list here](https://opentelemetry.io/docs/languages/sdk-configuration/general/#otel_propagators)) or set it to "none" to disable automatic propagation.
```shell
--set instrumentation.propagator={tracecontext, baggage, b3}
```

### Add a custom Sampler
You can specify a sampler to be used by the instrumentor. You'll need to specify the below:
- Sampler used to sample the traces ([available options](https://opentelemetry.io/docs/languages/sdk-configuration/general/#otel_traces_sampler))
- Sampler arguments ([Sampler type expected input](https://opentelemetry.io/docs/languages/sdk-configuration/general/#otel_traces_sampler_arg))

Example:
```shell
--set instrumentation.sampler.type="parentbased_always_on" \
--set instrumentation.sampler.argument="0.25"
```

### TLS certificate Requirements
Opentelemetry operator requires a TLS certificate. For more details, refer to [OpenTelemetry documentation](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-operator#tls-certificate-requirement).

There are 3 TLS certificate options, by default this chart is using option 2.

**1.** If you have `cert-manager` installed on your cluster, you can set `otel-operator.admissionWebhooks.certManager.enabled` to true and the cert-manager will generate a self-signed certificate for the otel-operator automatically.

```shell
--set otel-operator.admissionWebhooks.certManager.enabled=true \
```

**2.** Helm will automatically create a self-signed cert and secret for you. (Enabled by default by this chart)

**3.** Use your own self-signed certificate, To enable this option, set `otel-operator.admissionWebhooks.autoGenerateCert.enabled` to `false` and provide the necessary `certFile`, `keyFile` and `caFile`.

```shell
--set otel-operator.admissionWebhooks.autoGenerateCert.enabled=false \
--set otel-operator.admissionWebhooks.certFile="<<PEM_CERT_PATH>>" \
--set otel-operator.admissionWebhooks.keyFile="<<PEM_KEY_PATH>>" \
--set otel-operator.admissionWebhooks.caFile="<<CA_CERT_PATH>>" \
```

### Enable Go Instrumentation
Go Instrumentation is disabled by default in the OpenTelemetry Operator. To enable it, follow the below steps:

#### Step 1
Add the following configuration to your `values.yaml`:

```yaml
otel-operator:
  manager:
    extraArgs:
      - "--enable-go-instrumentation=true"
```

#### Step 2
Set the `OTEL_GO_AUTO_TARGET_EXE` environment variable in your Go application to the path of the target executable.

> [!NOTE]
> For further details, refer to the [OpenTelemetry Go Instrumentation documentation](https://github.com/open-telemetry/opentelemetry-go-instrumentation/blob/v0.21.0/docs/how-it-works.md#opentelemetry-go-instrumentation---how-it-works).
