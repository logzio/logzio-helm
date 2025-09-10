# Migrating to `logzio-monitoring` 7.0.0

## Step 1: Update helm repositories

Run the following command to ensure you have the latest chart versions:

```shell
helm repo update
```

## Step 2: Build the upgrade command

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

### Managing own secret
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