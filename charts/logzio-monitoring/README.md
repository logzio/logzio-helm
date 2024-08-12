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
--set logzio-logs-collector.secrets.logzioLogsToken="<<LOG-SHIPPING-TOKEN>>" \
--set logzio-logs-collector.secrets.logzioRegion="<<LOGZIO-REGION>>" \
--set logzio-logs-collector.secrets.env_id="<<ENV-ID>>" \
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
--set logzio-k8s-telemetry.serviceGraph.enabled=true \
--set logzio-k8s-telemetry.k8sObjectsConfig.enabled=true \
--set logzio-k8s-telemetry.secrets.k8sObjectsLogsToken="<<LOG-SHIPPING-TOKEN>>" \
--set securityReport.enabled=true \
--set logzio-trivy.env_id="<<ENV-ID>>" \
--set logzio-trivy.secrets.logzioShippingToken="<<LOG-SHIPPING-TOKEN>>" \
--set logzio-trivy.secrets.logzioListener="<<LISTENER-HOST>>" \
--set deployEvents.enabled=true \
--set logzio-k8s-events.secrets.env_id="<<ENV-ID>>" \
--set logzio-k8s-events.secrets.logzioShippingToken="<<LOG-SHIPPING-TOKEN>>" \
--set logzio-k8s-events.secrets.logzioListener="<<LISTENER-HOST>>" \
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

The `helm install` command described above deploys a standard configuration of the chart for sending logs, metrics, and traces.

However, you can customize the chart by using the `--set` flag in your `helm install` command:

| Parameter	| Description | Default |
| --- | --- | --- |
| `logs.enabled` | Enable to send Kubernetes logs | `false` |
| `metricsOrTraces.enabled` | Enable to send Kubernetes metrics or traces | `false` |
| `securityReport.enabled` | Enable to send Kubernetes security logs | `false` |
| `deployEvents.enabled` | Enable to send Kubernetes deploy events logs | `false` |

#### To modify the logs chart configuration:

You can see a full list of the possible configuration values in the [logzio-fluentd Chart folder](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd#configuration).

If you want to modify one of the values mentioned in the `logzio-fluentd` folder, add it with the `--set` flag, and the `logzio-fluentd` prefix.

For example, to change a value named `someField` in `logzio-fluentd`'s `values.yaml` file, include the following in your `helm install` command:

```shell
--set logzio-fluentd.someField="my new value"
```

You can add `log_type` annotation with a custom value, which will be parsed into a `log_type` field with the same value.


### To modify the metrics and traces Chart configuration:

You can see a full list of the possible configuration values in the [logzio-telemetry Chart folder](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-telemetry).

If you want to modify one of the values mentioned in the `logzio-telemetry` folder, add it with the `--set` flag, and the `logzio-k8s-telemetry` prefix.

For example, to change a value named `someField` in `logzio-telemetry`'s `values.yaml` file, include the following in your `helm install` command:

```shell
--set logzio-k8s-telemetry.someField="my new value"
```

### Migrate to OpenTelemetry for log collection (Migrating to logzio-monitoring 6.0.0)

The `logzio-fluentd` chart is disabled by default in favor of the `logzio-logs-collector` for log collection. To use `logzio-fluentd`, add the following `--set` flags:

```sh
helm install -n monitoring \
--set logs.enabled=true \  
--set logzio-fluentd.enabled=true \  
--set logzio-logs-collector.enabled=false \  
--set logzio-fluentd.secrets.logzioShippingToken="<<LOG-SHIPPING-TOKEN>>" \
--set logzio-fluentd.secrets.logzioListener="<<LISTENER-HOST>>" \
--set logzio-fluentd.env_id="<<ENV-ID>>" \
logzio-monitoring logzio-helm/logzio-monitoring
```

### Sending telemetry data from eks on fargate

To ship logs from pods running on Fargate, set the `fargateLogRouter.enabled` value to `true`. This will deploy a dedicated `aws-observability` namespace and a `configmap` for the Fargate log router. More information about EKS Fargate logging can be found [here](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html)

```shell
helm install -n monitoring \
--set logs.enabled=true \
--set logzio-logs-collector.fargateLogRouter.enabled=true \
--set logzio-logs-collector.secrets.logzioLogsToken="<<LOG-SHIPPING-TOKEN>>" \
--set logzio-logs-collector.secrets.logzioRegion="<<LOGZIO-REGION>>" \
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

Set fluetd `customEndpoint` value to send your logs to a custom endpoint

```shell
--set logzio-fluentd.secrets.customEndpoint="<<CUSTOM_ENDPOINT>>" 
```

### Send Traces to a custom endpoint

Set logzio-k8s-telemetry `CustomTracingEndpoint` value to send your spans to a custom endpoint

```shell
--set logzio-k8s-telemetry.secrets.CustomTracingEndpoint="<<CUSTOM_TRACING_ENDPOINT>>" 
```

### Send metrics to a custom endpoint

Set logzio-k8s-telemetry `ListenerHost` value to send your metrics to a custom endpoint (example: "https://endpoint.com:8080")

```shell
--set logzio-k8s-telemetry.secrets.ListenerHost="<<CUSTOM_ENDPOINT>>"
```

### Upgrade logzio-monitoring to v3.0.0

Before upgrading your logzio-monitoring Chart to v3.0.0 with `helm upgrade`, note that you may encounter an error for some of the logzio-telemetry sub-charts.

There are two possible approaches to the upgrade you can choose from:

- Reinstall the chart.
- Before running the `helm upgrade` command, delete the old subcharts resources: `logzio-monitoring-prometheus-pushgateway` deployment and the `logzio-monitoring-prometheus-node-exporter` daemonset.


## Changelog
- **6.0.7**:
  - Upgrade `logzio-logs-collector` chart to `v1.0.6`
	- Added `varlogcontainers` volume and volume mounts
	- Added new `container` operator instead of complex operator sequence
	- Remove default resources `limits`
	- Add default resources `requests`
  - Upgrade `logzio-k8s-events` chart to `v0.0.6`
    - Upgrade `logzio-k8s-events` to `v0.0.3`
      - Upgrade GoLang version to `v1.22.3`
      - Upgrade docker image to `alpine:3.20`
      - Upgrade GoLang docker image to `golang:1.22.3-alpine3.20`
  - Upgrade `logzio-trivy` chart to `0.3.3`
	- Upgrade to image `logzio/trivy-to-logzio:0.3.3`.
	  - Upgrade python version to 3.12.5.
	  - Re-build image to include the latest version of git(CVE-2024-32002).
	- Bump Trivy-Operator chart version to `0.24.0`.
- **6.0.6**:
  - Upgrade `logzio-k8s-telemetry` chart to `v4.2.7`
    - Fix `cluster-admin` cluster role binding creation condition
- **6.0.5**:
  - Upgrade `logzio-k8s-telemetry` chart to `v4.2.6`
    - Upgrade `otel/opentelemetry-collector-contrib` image to `v0.103.0`
	- Fix standalone self metrics collection for EKS Fargate
  - Upgrade `logzio-logs-collector` chart to `v1.0.5`
    - Upgrade `otel/opentelemetry-collector-contrib` image to `v0.103.0`
  - Upgrade `logzio-fluentd` chart to `v0.30.1`
    - Handle empty etcd `log` field, populated based on `message` field.		
- **6.0.4**:
  - Upgrade `logzio-k8s-telemetry` chart to `4.2.5`
    - Added 'user-agent' header for telemetry data.
  - Upgrade `logzio-trivy` chart to `0.3.2`
    - Added 'user-agent' header for telemetry data.
- **6.0.3**:
  - Upgrade `logzio-k8s-events` chart to `0.0.5`
    - Bugfix/ Remove the duplicate label `app.kubernetes.io/managed-by` @philwelz
- **6.0.2**:
  - Upgrade `logzio-k8s-telemetry` chart to `v4.2.4`
    - Upgrade `otel/opentelemetry-collector-contrib` image to `v0.102.1`
- **6.0.1**:
  - Upgrade `logzio-logs-collector` chart to v1.0.4
    - Add standalone deployment mode
    - Rename `LogzioRegion` to camelCase - `logzioRegion`
    - Add user-agent header
- **6.0.0**:
  - **Breaking changes**:
  	- Make `logzio-logs-collector` default subchart for logging instead of `logzio-fluentd`
- **5.3.6**:
  - Upgrade `logzio-k8s-telemetry` version to `4.2.3`:
	- Disable Kubernetes objects receiver by default.
- **5.3.5**:
  - Upgrade `logzio-k8s-telemetry` version to `4.2.2`:
  	- Fix missing `logzio-k8s-objects-logs-token` key from secret.
- **5.3.4**:
  - Upgrade `logzio-k8s-telemetry` version to `4.2.1`:
  	- Filter in `container_cpu_cfs_throttled_seconds_total` and `kube_pod_container_info` metrics.
- **5.3.3**:
  - Upgrade `logzio-logs-collector` version to `1.0.3`:
  	- Replace dots `.` with underscores `_` in log attributes keys:
      - Added `transform/dedot` proccesor. 
      - Edited `k8sattributes`, `transform/log_type`, `transform/log_level` proccesors.
- **5.3.2**:
  - Upgrade `logzio-fluentd` to version `0.30.0`
  	- Upgrade fluentd version to `1.16.5`
- **5.3.1**:
  - Upgrade `logzio-logs-collector` version to `1.0.2`:
    - Refactor templates function names, to avoid conflicts with other charts templates
- **5.3.0**:
  - Add `logzio-logs-collector.enabled` + `fluentd.enabled` values
  - Upgrade `logzio-k8s-telemetry` to `4.2.0`:
    - Upgraded opentelemetry-collector-contrib image to v0.97.0
    - Added Kubernetes objects receiver
    - Removed servicegraph connector from span metrics configuration
    - Allow env_id & p8s_logzio_name non string values
  - Upgrade `logzio-logs-collector` version to `1.0.1`:
    - Create NOTES.txt for Helm install notes
	- Enhanced env_id handling to support both numeric and string formats
    - Change default log type
	- Update multiline parsing and error detection
	- Update error detection in logs
  - Upgrade `logzio-fluentd` to `0.29.2`:
    - Enhanced env_id handling to support both numeric and string formats
  - Upgrade `logzio-trivy` to `0.4.0`:
    - Enhanced env_id handling to support both numeric and string formats
  - Upgrade `logzio-k8s-events` to `0.0.4`:
    - Enhanced env_id handling to support both numeric and string formats
- **5.2.5**:
  - **Depreciation notice** `logzio-fluentd` chart will be disabled by default in favour of `logzio-logs-collector` for log collection in upcoming releases.
	- Added `logzio-logs-collector` version `1.0.0`:
    - otel collector daemonset designed and configured to function as log collection agent
    - eks fargate support
    - adds logzio required fields (`log_level`, `type`, `env_id` and more)
    - `enabled` value to enable/disable deployment from parent charts
	- Upgrade `logzio-fluentd` to `0.29.1`:
    - Added `enabled` value, to conditianly control the deployment of this chart by a parent chart.
    - Added `daemonset.LogFileRefreshInterval` and `windowsDaemonset.LogFileRefreshInterval` values, to control list of watched log files refresh interval.
- **5.2.4**:
  - Update `logzio-k8s-telemetry` sub chart version to `4.1.3`
- **5.2.3**:
  - Upgrade `logzio-k8s-telemetry` to `4.1.3`:
	- Removed unused prometheus receiver
	- Divide metrics and labels renames to separate processors
	- Disable metric suffix from prometheus exporter
		- Resolves latency metric rename
- **5.2.2**:
  - Upgrade `logzio-k8s-telemetry` to `4.1.2`:
    - Upgrade `.values.spmImage.tag` `0.80` -> `0.97`
      - Add `metrics_expiration` to span metrics configuration, to prevent sending expired time series
      - Add `resource_metrics_key_attributes` to span metrics configuration, to prevent value fluctuation of counter metrics when resource attributes change.
    - Include collector log level configuration in individual components (standalone, daemonset, spanmetrics).
- **5.2.1**:
	- Upgrade `logzio-k8s-telemetry` to `4.1.1`:
  		- Fixed bug with cAdvisor metrics filter.
- **5.2.0**:
	- Upgrade `logzio-k8s-telemetry` to `4.1.0`:
		- Upgraded prometheus-node-exporter version to `4.29.0`
		- Fixed bug with AKS metrics filter
		- Remove unified_status_code label from SPM
- **5.1.0**
  - Upgrade `logzio-fluentd` -> `0.29.0`:
    - EKS Fargate logging: Send logs to port `8070` in logzio listener (instead of port `5050`)
- **5.0.1**:
	- Upgrade `logzio-fluentd` to `0.28.1`:
		- Added `windowsDaemonset.enabled` customization.
- **5.0.0**:
	- Upgrade `logzio-k8s-telemetry` to `4.0.0`:
		- **BREAKING CHANGES**:
			- Removed the `kubernetes-360-metrics` key from the `logzio-secret`.
				- Populate the pods containers `K8S_360_METRICS` environment variable directly using the opentelemetry-collector.k8s360 definition to inherit the list from values file instead.
		- Added `logzio_app` label with `kubernetes360` value to cadvisor metrics pipeline to avoid dropping specific metrics by matching the k8s 360 filter.
- **4.0.0**:
	- Upgrade `logzio-k8s-telemetry` to `3.0.0`:
		- Updated K360 metrics list in `secrets.yaml` - now created dynamically from OOB filters.
		- Added `job_dummy` relabel and processor - Fixing an issue where duplicate metrics were being sent if the metrics were not in the `K8S_360_METRICS` environment variable.
		- Use attributes processor to create the `unified_status_code` dimension as it supports connectors.


<details>
  <summary markdown="span"> Expand to check old versions </summary>

- **3.5.0**:
	- Upgrade `logzio-fluentd` to `0.28.0`:
   - Added `daemonset.initContainerSecurityContext` customization.
   - Added `daemonset.updateStrategy` customization.
- **3.4.0**:
	- Upgrade `logzio-fluentd` to `0.27.0`:
		- Added `daemonset.podSecurityContext`, `daemonset.securityContext` customization.
- **3.3.0**:
	- Upgrade `logzio-k8s-telemetry` to `2.2.0`:
		- Upgraded SPM collector image to version `0.80.0`.
		- Added service graph connector metrics.
			- `serviceGraph.enabled` option.
		- Refactored span metrics processor to a connector.
			- Added metrics transform processor to modify the data for Logz.io backwards compatibility.
- **3.2.0**:
	- Upgrade `logzio-k8s-telemetry` to `2.1.0`:
		- Update SPM labels
			- Add `rpc_grpc_status_code` dimension
			- Add `unified_status_code` dimension
				- Takes value of `rpc_grpc_status_code` / `http_status_code`
		- Add `containerSecurityContext` configuration option for container based policies. 
- **3.1.0**:
	- Upgrade `logzio-fluentd` to `0.26.0`:
		- Bump docker image to `1.5.1`.
	  	- Add the ability to configure pos file for containers logs.
- **3.0.0**:
	- Upgrade `logzio-k8s-telemetry` to `2.0.0`:
		- Upgrade sub charts to their latest versions.
			- `kube-state-metrics` to `4.24.0`
			- Upgraded horizontal pod autoscaler API group version.
			- `prometheus-node-exporter` to `4.23.2`
			- `prometheus-pushgateway` to `2.4.2`
		- Secrets resource name is now changeable via `secrets.name` in `values.yaml`.
		- Fix sub charts conditional installation. 
		- Add conditional creation of `CustomTracingEndpoint` secret key. 
- **2.0.0**:
	- Add `logzio-k8s-events` sub chart version `0.0.3`:
		- Sends Kubernetes deploy events logs.
- **1.8.0**:
	- Upgrade `logzio-k8s-telemetry` to `1.3.0`:
		- Upgraded horizontal pod autoscaler API group version.
	- Remove replicasCount from daemonset.
- **1.7.0**:
	- Upgrade `logzio-fluentd` to `0.25.0`:
   - Add parameter `isPrivileged` to allow running Daemonset with priviliged security context.
   - **Bug fix**: Fix template for `fluentd.serviceAccount`, and fix use of template in service account.
- **1.6.0**:
	- Upgrade `logzio-k8s-telemetry` to `1.2.0`:
	  - Upgraded collector image to `0.80.0`.
	  - Changed condition to filter duplicate metrics collected by daemonset collector.
- **1.5.0**:
	- Upgrade `logzio-fluentd` to `0.24.0`:
		- Add parameter `configmap.customFilterAfter` that allows adding filters AFTER built-in filter configuration.
   	- Added `daemonset.init.containerImage` customization.
   	- Added fluentd image for windows server 2022.
- **1.4.0**:
	- Upgrage `logzio-fluentd` to `0.23.0`:
		- Allow filtering logs by log level with `logLevelFilter`.
	- Upgrade `logzio-trivy` to `0.3.0`:
		- Upgrade to Trivy-Operator 0.15.1.
- **1.3.0**:
  - Add the ability to send logs and traces to custom endpoints:
    - logzio-k8s-telemetry: Added `secrets.CustomTracingEndpoint` value
    - fluentd: Added `secrets.customEndpoint` value
- **1.2.3**:
  - Fixed an issue when enabling dropKubeSystem filter where namespace label values were not filtered.
- **1.2.2**:
  - Rename `spm` k8s metadata fields- 
- **1.2.1**:
  - Fixed `spm` service component name
  - Add `spm` cloud metadata
  - Rename `spm` k8s metadata fields- 
- **1.2.0**:
	- Add `ezkonnect` chart as a dependency
- **1.1.0**:
	- Upgrade `logzio-fluentd` to `0.21.0`:
		- Upgrade fluentd to `1.16`.
		- Upgrade gem `fluent-plugin-logzio` to `0.2.2`:
			- Do not retry on 400 and 401. For 400 - try to fix log and resend.
			- Generate a metric (`logzio_status_codes`) for response codes from Logz.io.
- **1.0.0**:
  - Upgrade `logzio-k8s-telemetry` to `1.0.0`:
	- Fixed an issue where when enabling `enableMetricsFilter.kubeSystem` installation failes.
  - **BREAKING CHANGES**:
    - Rename `enableMetricsFilter.kubeSystem` to `enableMetricsFilter.dropKubeSystem`, in order to avoid confusion between functionality of filters.
- **0.7.1**:
	- Upgrade `logzio-k8s-telemetry` to `0.2.1`:
		- Rename k8s attributes for traces pipeline.
  	- SPM: add dimension `http.status_code`.
- **0.7.0**:
	- Upgrade `logzio-k8s-telemetry` to `0.2.0`:
		- **BREAKING CHANGES**:
   			- Added `applicationMetrics.enabled` value (defaults to `false`)
		- Added resourcedetection processor, span dimensions.
- **0.6.0**:
	- Upgrade `logzio-k8s-telemetry` to `0.1.0`:
		- **BREAKING CHANGES**:
			- Split prometheus scrape jobs to separate pipelines:
				- Infrastrucutre: includes kubernetes-service-endpoints, windows-metrics, collector-metrics & cadvisor jobs.
				- Applications: includes applications jobs
			- Improved prometheus filters mechanism:
			- Users can now easily add custom filters for metrics, namesapces & services
			using `prometheusFilters` in `logzio-k8s-telemetry` `values.yaml`. For more information view [Adding additional filters](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-telemetry#adding-addiotional-filters-for-metrics-scraping) 
			- Added spot labels for kube-state-metrics.
- **0.5.8**:
	- Upgrade `logzio-fluentd` Chart to `0.20.3`:
	 - Added `logz.io/application_type` annotation detection. 
- **0.5.7**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.29`:
    - Upgrade traces and metrics otel image `0.70.0` -> `0.78.0`
    - Upgrade spm image `0.70.0` -> `0.73.0`
    - Added values for seprate spm image
- **0.5.6**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.28`:
		- Change default metrics scrape and export values to handle more cases
    - Reorder processors
    - Remove the memory_limiter processor
- **0.5.5**:
	- Upgrade `logzio-fluentd` Chart to `0.20.2`:
		- Use fluentd's retry instead of retry in code (raise exception on non-2xx response).
- **0.5.4**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.27`:
		- Removed duplicate `prometheus.io/scrape` annotation from `kube-state-metrics`(@dlip)
- **0.5.3**:
	- Upgrade `logzio-trivy` Chart to `0.2.1`:
		- Default to disable unused reports (config audit, rbac assessment, infra assessment, cluster compliance).
		- Bump Trivy-Operator version to 0.13.1.
		- Bump logzio-trivy version to 0.2.1.
- **0.5.2**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.26`:
		- Added `applications` scrape job for `daemonset` collector mode.
    - Added `secrets.enabled` value.
	- Upgrade `logzio-fluentd` Chart to `0.20.1`:
		- Added log level detection for fargate log router.
    - Remove `namespace` value, replaced by `Realese.namespace` in all templates
- **0.5.1**:
	- Upgrade `logzio-trivy` Chart to `0.2.0`:
		- Watch for creation/modification of reports.
- **0.5.0**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.25`:
		- Added affinity selector to the collector daemonset deployment.
		- Improved namings of collector pods.
		- Added opencost conditions.
	- Added Opencost - controlled with `finops.enabled` flag.
- **0.4.0**:
	- Upgrade `logzio-trivy` Chart to `0.1.0`:
		- **Breaking changes:**
			- Deprecation of CronJob, using Deployment instead.
			- Scanning for reports will occur once upon container deployment, then once a day at the scheduled time.
			- Not using cron expressions anymore. Instead, set a time for the daily run in form of HH:MM.
- **0.3.0**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.24`:
	- **breaking changes:** Changes default collector mode to `daemonset`:
      - Controlled using the `logzio-k8s-telemetry.collector.mode` value - supports `daemonset` and `standalone`.
    - Increased memory and cpu limits for the collector pods, to `1024Mi` and `512m`.
- **0.2.1.**:
	- Upgrade `logzio-trivy` Chart to `0.0.2`:
		- Bug fix for cron expression.
- **0.2.0**:
	- Add `logzio-trivy` Chart to scan for security risks on cluster, and send reports to Logz.io.
- **0.1.25**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.23`:
		- Updated metrics filter.
- **0.1.24**:
	- Upgrade `logzio-fluentd` Chart to `0.20.0`:
		- Added support for fluentd monitoring for windows pods.
- **0.1.23**:
	- Upgrade `logzio-fluentd` Chart to `0.19.0`:
		- Added support for fluentd monitoring for arm and amd pods.
- **0.1.22**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.22`:
    - **breaking changes:** Add separate span metrics component that includes the following resources:
      - `deployment-spm.yaml`
      - `service-spm.yaml`
      - `configmap-spm.yaml`
    - Updated collector image -> `0.70.0`
- **0.1.21**:
	- Upgrade `logzio-fluentd` Chart to `0.18.0`:
		- Added `warn` log level detection.
- **0.1.20**:
	- Upgrade `logzio-fluentd` Chart to `0.17.0`:
		- Add `secrets.enabled` to control secret creation and management.

- **0.1.19**:
	- Upgrade `logzio-fluentd` Chart to `0.16.0`:
	  - Increased memory and cpu requests.
- **0.1.18**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.21`:
	  - Updated collector image - fixing memory leak crash
	- Upgrade `logzio-fluentd` Chart to `0.15.0`:
	  - Added dedot processor - replacing `.` with `_` in log fields

- **0.1.17**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.20`:
	  - Change the default port for node exporter `9100` -> `9101` to avoid pods stocking on pending state if a user has `node-exporter` daemon set deployed on the cluster
	  - Update otel `0.64.0` -> `0.66.0` 
	  - Add `logzio_agent_version` label
	  - Add `logz.io/app=kubertneters360` annotation to `Kube-state-metrics` and `node-exporter` 
	  - Add `filter/kubernetes360` processor for metrics, to avoid duplicated metrics if a user has `Kube-state-metrics` or `node-exporter` deployed on the cluster
- **0.1.16**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.19`:
	  - Drop metrics from `kube-system` namespace
- **0.1.15**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.18`:
	  - Add `kube_pod_container_status_terminated_reason` `kube_node_labels` metrics to filters
- **0.1.14**:
	- Upgrade `logzio-fluentd` Chart to `0.14.0`:
	   - Fix typo in `fargateLogRouter`
- **0.1.13**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.17`:
	  - Add `kube_pod_container_status_waiting_reason` metric to filters
- **0.1.12**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.16`:
	  - Add `kube_deployment_labels` `node_memory_Buffers_bytes` `node_memory_Cached_bytes` metrics to filters
- **0.1.11**:
	- Upgrade `logzio-k8s-telemetry` Chart to `0.0.15`:
	  - Add `applications` job
      - Add `collector-metrics` job
      - Replace `$` -> `$$` to escape special char
      - Upgrade otel image `0.60.0`-> `0.64.0`
      - Add `k8s 360` metrics to filters
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
