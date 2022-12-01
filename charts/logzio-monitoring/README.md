# logzio-monitoring

The logzio-monitoring Helm Chart ships your Kubernetes logs, metrics and traces to your Logz.io account.

**Note:** this project is currently in *beta* and is prone to changes.

## Overview

This project packages 2 Helm Charts:
- [logzio-fluentd](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd) for logs shipping (via Fluentd).
- [logzio-telemetry](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-telemetry) for metrics and traces (via OpenTelemetry Collector).

## Instructions for standard deployment:

### Before installing the chart
Check if you have any taints on your nodes:

```sh
kubectl get nodes -o json | jq '"\(.items[].metadata.name) \(.items[].spec.taints)"'
```

if you do, please add them as tolerations. For further explenation about modifying the chart, see the [further configuration section](#Further-configuration).


### 1. Add the Helm Chart:

```sh
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

### 2. Deploy the Chart:

Use the following command, and replace the placeholders with your parameters:

```sh
helm install -n monitoring \
--set logs.enabled=true \
--set logzio-fluentd.secrets.logzioShippingToken="<<LOG-SHIPPING-TOKEN>>" \
--set logzio-fluentd.secrets.logzioListener="<<LISTENER-HOST>>" \
--set logzio-fluentd.env_id="<<ENV-ID>>" \
--set metricsOrTraces.enabled=true \
--set logzio-k8s-telemetry.metrics.enabled=true \
--set logzio-k8s-telemetry.secrets.MetricsToken="<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>" \
--set logzio-k8s-telemetry.secrets.ListenerHost="https://<<LISTENER-HOST>>:8053" \
--set logzio-k8s-telemetry.secrets.p8s_logzio_name="<<ENV-TAG>>" \
--set logzio-k8s-telemetry.traces.enabled=true \
--set logzio-k8s-telemetry.secrets.TracesToken="<<TRACES-SHIPPING-TOKEN>>" \
--set logzio-k8s-telemetry.secrets.LogzioRegion="<<LOGZIO-REGION>>" \
--set logzio-k8s-telemetry.spm.enabled=true \
--set logzio-k8s-telemetry.secrets.env_id="<<ENV-ID>>" \
--set logzio-k8s-telemetry.secrets.SpmToken=<<SPM-SHIPPING-TOKEN>> \
logzio-monitoring logzio-helm/logzio-monitoring
```

| Parameter | Description |
| --- | --- |
| `<<LOG-SHIPPING-TOKEN>>` | Your [logs shipping token](https://app.logz.io/#/dashboard/settings/general). |
| `<<LISTENER-HOST>>` | Your account's [listener host](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping?product=logs). |
| `<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>` | Your [metrics shipping token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping). |
| `<<P8S-LOGZIO-NAME>>` | The name for the environment's metrics, to easily identify the metrics for each environment. |
| `<<ENV-ID>>` | The name for your environment's identifier, to easily identify the telemetry data for each environment. |
| `<<TRACES-SHIPPING-TOKEN>>` | Your [traces shipping token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping). |
| `<<SPM-SHIPPING-TOKEN>>` | Your [span metrics shipping token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping). |
| `<<LOGZIO-REGION>>` | Name of your Logz.io traces region e.g `us`, `eu`... |


### Further configuration

The above `helm install` command will deploy a standard configuration version of the Chart, for shipping logs, metrics and traces.

However, you can modify the Chart by using the `--set` flag in your `helm install` command:

| Parameter	| Description | Default |
| --- | --- | --- |
| `logs.enabled` | Enable to send k8s logs | `false` |
| `metricsOrTraces` | Enable to send k8s metrics or traces | `false` |

#### To modify the logs Chart configuration:

You can see a full list of the possible configuration values in the [logzio-fluentd Chart folder](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd#configuration).

If you want to modify one of the values mentioned in the `logzio-fluentd` folder, add it with the `--set` flag, and the `logzio-fluentd` prefix.

For example, if in `logzio-fluentd`'s `values.yaml` file there's a parameter named `someField`, to set it we'll add the following to the `helm install` command:

```sh
--set logzio-fluentd.someField="my new value"
```
You can add `log_type` annotation with a custom value, which will be parsed into a `log_type` field with the same value.


### To modify the metrics and traces Chart configuration:

You can see a full list of the possible configuration values in the [logzio-telemetry Chart folder](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-telemetry).

If you want to modify one of the values mentioned in the `logzio-telemetry` folder, add it with the `--set` flag, and the `logzio-k8s-telemetry` prefix.

For example, if in `logzio-telemetry`'s `values.yaml` file there's a parameter named `someField`, to set it we'll add the following to the `helm install` command:

```sh
--set logzio-k8s-telemetry.someField="my new value"
```

### Sending telemetry data from eks on fargate

If you want to ship logs from pods that are running on fargate set the `fargateLogRouter.enabled` value to true, the follwing will deploy a dedicated `aws-observability` namespace and a `configmap` for fargate log router. More information about eks fargate logging can be found [here](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html)
```sh
helm install -n monitoring \
--set logs.enabled=true \
--set logzio-fluentd.fargateLogRouter.enabled=true \
--set logzio-fluentd.secrets.logzioShippingToken="<<LOG-SHIPPING-TOKEN>>" \
--set logzio-fluentd.secrets.logzioListener="<<LISTENER-HOST>>" \
--set metricsOrTraces.enabled=true \
--set logzio-k8s-telemetry.metrics.enabled=true \
--set logzio-k8s-telemetry.secrets.MetricsToken="<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>" \
--set logzio-k8s-telemetry.secrets.ListenerHost="https://<<LISTENER-HOST>>:8053" \
--set logzio-k8s-telemetry.secrets.p8s_logzio_name="<<ENV-TAG>>" \
--set logzio-k8s-telemetry.traces.enabled=true \
--set logzio-k8s-telemetry.secrets.TracesToken="<<TRACES-SHIPPING-TOKEN>>" \
--set logzio-k8s-telemetry.secrets.LogzioRegion="<<LOGZIO-REGION>>" \
logzio-monitoring logzio-helm/logzio-monitoring
```

## Changelog
- **0.1.14**:
	- Upgrade `logzio-fluentd` Chart to `0.14.0`.
- **0.1.13**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.17`.
- **0.1.12**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.16`.
- **0.1.11**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.15`.


<details>
  <summary markdown="span"> Expand to check old versions </summary>

- **0.1.10**:
	- Upgrade `logzio-fluentd` Chart to `0.13.0`.
- **0.1.9**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.14`.
- **0.1.8**:
	- Upgrade `logzio-fluentd` Chart to `0.0.12`.
- **0.1.7**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.13`.
- **0.1.6**:
	- Upgrade `logzio-fluentd` Chart to `0.11.0`.
- **0.1.5**:
	- Upgrade `logzio-fluentd` Chart to `0.10.0`.

- **0.1.4**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.8`.
	- Upgrade `logzio-fluentd` Chart to `0.9.0`.

- **0.1.3**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.6`.
	- Upgrade `logzio-fluentd` Chart to `0.8.0`.

- **0.1.2**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.4`.
	- Upgrade `logzio-fluentd` Chart to `0.6.1`.
- **0.1.1**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.3`.
- **0.1.0**:
	- Add support for fargate logging
	- Upgrade `logzio-fluentd` Chart to `0.5.0`.
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.2`.
- **0.0.3**:
	- Upgrade `logzio-fluentd` Chart to `0.4.1`.
- **0.0.2**:
	- Upgrade `logzio-fluentd` Chart to `0.4.0`.
	- Set default logs type to `agent-k8s`.
- **0.0.1**: Initial release.

</details>
