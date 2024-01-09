# Logzio-k8s-telemetry

**Note**: This chart is for shipping metrics and traces only. For a chart that ships all telemetry (logs, metrics, traces, spm) - use our [Logzio Monitoring chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring).

##  Overview

You can use a Helm chart to ship Kubernetes metrics and traces to Logz.io via the OpenTelemetry collector.
The Helm tool is used to manage packages of pre-configured Kubernetes resources that use charts.

**logzio-k8s-telemetry** allows you to ship metrics and traces from your Kubernetes cluster to Logz.io with the OpenTelemetry collector.

**Note:** This chart is a fork of the [opentelemtry-collector](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) Helm chart. 
It is also dependent on the [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics/tree/master/charts/kube-state-metrics) and [prometheus-node-exporter](https://github.com/helm/charts/tree/master/stable/prometheus-node-exporter) charts, which are installed by default. 
To disable the dependency during installation, set any of these values: `kubeStateMetrics.enabled`, `pushGateway.enabled` and `nodeExporter.enabled` to `false`.


### Kubernetes Versions Compatibility
| Chart Version | Kubernetes Version |
|---|---|
| > 2.0.0 | v1.22.0 - v1.28.0 |
| < 1.3.0 | <= v1.22.0 |

#### Before installing the chart
* Check if you have any taints on your nodes:

```
kubectl get nodes -o json | jq '"\(.items[].metadata.name) \(.items[].spec.taints)"'
```
if you do, please add them as tolerations in values.yaml tolerations.

* You are using `Helm` client with version `v3.9.0` or above

#### Standard configuration


##### Deploy the Helm chart
First add `logzio-helm` repo
```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

To deploy the Helm chart, enter the relevant parameters for the placeholders and run the code. 

###### Configure the parameters in the code
Replace `<<*P8S-LOGZIO-NAME*>>` with the name for the environment's metrics, to easily identify the metrics for each environment.
Replace `<<*ENV-ID*>>` with the name for your environment's identifier, to easily identify the telemetry data for each environment.

#### For metrics:
Enable the metrics configuration for this chart: --set metrics.enabled=true

Replace the Logz-io `<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping) of the metrics account to which you want to send your data.

Replace `<<LISTENER-HOST>>` with your region’s listener host (for example, `https://listener.logz.io:8053`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

#### For traces:
Enable the traces configuration for this chart: --set traces.enabled=true

Replace the Logz-io `<<TRACES-SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping) of the traces account to which you want to send your data.

Replace `<<logzio-region>>` with the name of your Logz.io region e.g `us`,`eu`.



###### Run the Helm deployment code for clusters with no Windows Nodes

#### Deploy the metrics chart:
```
helm install  \
--set metrics.enabled=true \
--set secrets.MetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set secrets.ListenerHost=<<LISTENER-HOST>> \
--set secrets.p8s_logzio_name=<<P8S-LOGZIO-NAME>> \
--set secrets.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

#### Deploy the traces chart:
```
helm install \
--set traces.enabled=true \
--set secrets.TracesToken=<<TRACES-SHIPPING-TOKEN>> \
--set secrets.LogzioRegion=<<logzio-region>> \
--set secrets.p8s_logzio_name=<<P8S-LOGZIO-NAME>> \
--set secrets.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

#### Deploy the traces chart with span metrics:
**Note** `spm.enabled=true` will have no effect unless `traces.enabled` is also set to `true`
```
helm install \
--set traces.enabled=true \
--set spm.enabled=true \
--set secrets.SpmToken=<<SPM-SHIPPING-TOKEN>> \
--set secrets.TracesToken=<<TRACES-SHIPPING-TOKEN>> \
--set secrets.LogzioRegion=<<logzio-region>> \
--set secrets.ListenerHost=<<LISTENER-HOST>> \
--set secrets.p8s_logzio_name=<<P8S-LOGZIO-NAME>> \
--set secrets.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

#### Deploy both charts with span metrics:
**Note** `spm.enabled=true` will have no effect unless `traces.enabled` is also set to `true`
```
helm install  \
--set traces.enabled=true \
--set spm.enabled=true \
--set secrets.TracesToken=<<TRACES-SHIPPING-TOKEN>> \
--set secrets.SpmToken=<<SPM-SHIPPING-TOKEN>> \
--set secrets.LogzioRegion=<<logzio-region>> \
--set metrics.enabled=true \
--set secrets.MetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set secrets.ListenerHost=<<LISTENER-HOST>> \
--set secrets.p8s_logzio_name=<<P8S-LOGZIO-NAME>> \
--set secrets.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```
#### Deploy both charts with span metrics and service graph
**Note** `serviceGraph.enabled=true` will have no effect unless `traces.enabled` & `spm.enabled=true` is also set to `true`
```
helm install  \
--set traces.enabled=true \
--set spm.enabled=true \
--set serviceGraph.enabled=true \
--set secrets.TracesToken=<<TRACES-SHIPPING-TOKEN>> \
--set secrets.SpmToken=<<SPM-SHIPPING-TOKEN>> \
--set secrets.LogzioRegion=<<logzio-region>> \
--set metrics.enabled=true \
--set secrets.MetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set secrets.ListenerHost=<<LISTENER-HOST>> \
--set secrets.p8s_logzio_name=<<P8S-LOGZIO-NAME>> \
--set secrets.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```
#### Handling image pull rate limit
In some cases (i.e spot clusters) where the pods/nodes are replaced frequently, the pull rate limit for images pulled from dockerhub might be reached, with an error:
`You have reached your pull rate limit. You may increase the limit by authenticating and upgrading: https://www.docker.com/increase-rate-limits`.
In these cases we can use the following `--set` commands to use an alternative image repository:

```shell
--set image.repository=ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib
--set prometheus-pushgateway.image.repository=public.ecr.aws/logzio/prom-pushgateway
```


#### For clusters with Windows Nodes

In order to extract and scrape metrics from Windows Nodes, a Windows Exporter service must first be installed on the node host itself. We will do this by authenticating with username and password using SSH connection to the node through a job.

By default, the Windows installer job will run on deployment and every 10 minutes, and will keep the most recent failed and successful pods.
You can change these setting in values.yaml:

```
windowsExporterInstallerJob:
  interval: "*/10 * * * *"           #In CronJob format
  concurrencyPolicy: Forbid          # Future cronjob will run only after current job is finished
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
```

The default username for windows Node pools is: azureuser. (Username and password are shared across all windows nodepools)

You can change your Windows node pool password in AKS cluster with the following command (will only affect Windows node pools):

```
    az aks update \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --windows-admin-password $NEW_PW
```

You can read more information at https://docs.microsoft.com/en-us/azure/aks/windows-faq,
under `How do I change the administrator password for Windows Server nodes on my cluster?` section.


###### Run the Helm deployment code for clusters with Windows Nodes:

```
helm install  \
--set secrets.MetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set secrets.ListenerHost=<<LISTENER-HOST>> \
--set secrets.p8s_logzio_name=<<ENV-TAG>> \
--set secrets.windowsNodeUsername=<<WINDOWS-NODE-USERNAME>> \
--set secrets.windowsNodePassword=<<WINDOWS-NODE-PASSWORD>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

* Replace `<<WINDOWS-NODE-USERNAME>>` with the username for the Node pool you want the Windows exporter to be installed on.

* Replace `<<WINDOWS-NODE-PASSWORD>>` with the password for the Node pool you want the Windows exporter to be installed on.

##### Check Logz.io for your metrics and traces

Give your metrics some time to get from your system to ours, then open [Logz.io](https://app.logz.io/).

## Example usage - traces 

* Go to `hotrod.yml` file inside this directory.
* Change the `<<otel-cluster-ip>>` parameter to the cluster-ip address of your opentelemetry collector **service** on port `14268`
* Deploy the `hotrod.yml` to your kubernetes cluster (example: `kubectl apply -f hotrod.yml`).
* Access the hotrod pod on port 8080 and start sending traces.


####  Customizing Helm chart parameters
See `VALUES.md` for additional information.

##### Configure customization options

You can use the following options to update the Helm chart parameters: 

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`

* Edit the `values.yaml`

* Overide default values with your own `my_values.yaml` and apply it in the `helm install` command. 

###### Example:

```
helm install logzio-k8s-telemetry
 logzio-helm/logzio-k8s-telemetry -f my_values.yaml 
```

##### Customize the metrics collected by the Helm chart 

The default configuration uses the Prometheus receiver with the following scrape jobs:

* Cadvisor: Scrapes container metrics
* Kubernetes service endpoints: These jobs scrape metrics from the node exporters, from Kube state metrics, from any other service for which the `prometheus.io/scrape: true` annotaion is set, and from services that expose Prometheus metrics at the `/metrics` endpoint.

To customize your configuration, edit the `config` section in the `values.yaml` file.

### Adding application metrics

To enable applications metrics scraping set the `applicationMetrics.enabled` value to `true`
```bash
--set applicationMetrics.enabled=true
```
This will enable the `metrics/applications` pipline and will scrape metrics from pods with the `prometheus.io/scrape=true` annotation
### Removing kube-state-metrics metrics

To disable kube-state-metrics metrics scraping set the `kubeStateMetrics.enabled` value to `false`
```bash
--set kubeStateMetrics.enabled=false
```
This will disable the `kube-state-metrics` sub chart installation so it won't scrape its metrics.
### Removing prometheus-pushgateway metrics

To disable prometheus-pushgateway metrics scraping set the `pushGateway.enabled` value to `false`
```bash
--set pushGateway.enabled=false
```
This will disable the `prometheus-pushgateway` sub chart installation so it won't scrape its metrics.
### Removing prometheus-node-exporter metrics

To disable prometheus-node-exporter metrics scraping set the `nodeExporter.enabled` value to `false`
```bash
--set nodeExporter.enabled=false
```
This will disable the `prometheus-node-exporter` sub chart installation so it won't scrape its metrics.
### Using Out of the box metrics filters for Logzio dashboards

You can use predefined metrics filters to prevent unnecessary metrics being sent to Logz.io and reduce usage cost.
These filters will only send the metrics that are being used in Logz.io's Kubernetes dashboard: Cluster Componenets, Cluster Summary, Pods and Nodes.

To enable metrics filtering, set the following flag when deploying the chart, replace: `<<cloud-service>>` with `eks`, `gke` or `aks`.

```
--set enableMetricsFilter.<<cloud-service>>=true
```

### Adding addiotional filters for metrics scraping

To add flexibility for the metrics filtering, you can add custom filters for the following:
- metric name (keep & drop)
- service names (keep & drop - only for infrastructure pipeline)
- namespace names

Added filters should be in the format of regex, i.e: `"metrics1|metric2"` etc.
To add a custom filter, choose to which pipeline the filter is needed, and add the filter under the `custom` key accordingly.
For example, to add a custom `namespace` keep filter to the application metric job, you can set:
```
--set prometheusFilters.namespaces.applications.custom="namesapce_1|namespace_2"
```

For more information, view `prometheusFitlers` in [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/logzio-telemetry/values.yaml).


### Filtering metrics from `kube-system` namesapce

To Filter out metrics from `kube-system` namesapce, set the following flag when deploying the chart.

```
--set enableMetricsFilter.dropKubeSystem=true
```

### Disabling kube-dns scraping for EKS clusters

In the current EKS setup, kube-dns metrics cannot be scraped from the kube-dns system service as the port used for scraping is already in use. This results in the following warning in the collector pod logs:

```
	Failed to scrape Prometheus endpoint	{"kind": "receiver", "name": "prometheus", "pipeline": "metrics", "scrape_timestamp": 1659031329447, "target_labels": "map[__name__:up eks_amazonaws_com_component:kube-dns instance:: job:kubernetes-service-endpoints k8s_app:kube-dns kubernetes_io_cluster_service:true kubernetes_io_name:CoreDNS kubernetes_node: namespace:kube-system pod:coredns service:kube-dns]"}
```

A workaround for this issue is to create a seperate kube-dns service and add the necessary annotations to enable scraping.
By default, the kube-dns service filter is enabled, using the flag:

```
--set disableKubeDnsScraping=true
```

More informtion can be found in the following GitHub issue:
https://github.com/aws/containers-roadmap/issues/965


### Collector deployment modes
The default collector deployment is as a daemonset collector.
This is the recommended deployment method.
In some cases the standalone collector deployment can be more beneficial, e.g a small cluster with low metrics/traces count.
For this case you can use standalone deployment for the pod:
```
--set collector.mode=standalone
```


### Using pprof extention
The pprof extension in OpenTelemetry Collector allows you to view and analyze the profile of the collector during runtime. Here's how you can use it:

To download the go tool pprof command, you will need to install the Go programming language. You can download and install Go from the [official website](https://golang.org/dl/).

Once Go is installed, you can use the go command to install pprof and other tools:

```
go get -u golang.org/x/tools/cmd/pprof
```
This will download and install pprof and any necessary dependencies. You can then use the go tool pprof command.

Alternatively, you can also install pprof using a package manager, such as apt-get on Ubuntu or brew on macOS:

```
sudo apt-get install pprof # on Ubuntu
brew install pprof # on macOS
```

Forward the 1777 pprof port of the collector pod to your local network using the following command:
```
kubectl port-forward <<pod>> 1777:1777
```
Use the go tool pprof command to fetch the profile and visualize it in the web UI on port 1212.
To view the heap memory profile:
```
go tool pprof -http=localhost:1212 http://localhost:1777/debug/pprof/heap
```
To view the CPU profile:
```
go tool pprof -http=localhost:1212 http://localhost:1777/debug/pprof/profile
```
Or to look at a 30-second CPU profile:
```
go tool pprof -http=localhost:1212 http://localhost:1777/debug/pprof/profile?seconds=30

```
You can also use the pprof extension to view other types of profiles, such as goroutine, thread creation, and block. To do this, replace the endpoint in the go tool pprof command with the appropriate profile type. For example, to view the goroutine profile:
```
go tool pprof -http=localhost:1212 http://localhost:1777/debug/pprof/goroutine
```
You can find a complete list of the available profile types and their corresponding endpoints in the pprof [documentation](https://golang.org/pkg/net/http/pprof/).

### Uninstalling the Chart

The uninstall command is used to remove all the Kubernetes components associated with the chart and to delete the release.  

To uninstall the `logzio-k8s-telemetry` deployment, use the following command:

```shell
helm uninstall logzio-k8s-telemetry
```

### Upgrade logzio-telemetry to v2.0.0

Before upgrading your logzio-telemetry Chart to v2.0.0 with `helm upgrade`, note that you may encounter an error for some of its sub-charts.

There are two possible approaches to the upgrade you can choose from:
- Reinstall the chart.
- Before running the `helm upgrade` command, delete the old subcharts resources: `logzio-monitoring-prometheus-pushgateway` deployment and the `logzio-monitoring-prometheus-node-exporter` daemonset.

### Upgrade logzio-telemetry to v3.0.0

Before upgrading your logzio-telemetry Chart to v3.0.0 with `helm upgrade`, note that you may encounter different functionality in the installation of the sub charts as they will be installed by default regardless of the `metrics.enabled` flag.

If you don't want the sub charts to installed add the relevant flag per sub chart and set it to `false`.


## Change log
* 3.1.0
  - Removed the `kubernetes-360-metrics` key from the `logzio-secret`.
    - Populate the pods containers `K8S_360_METRICS` environment variable directly using the opentelemetry-collector.k8s360 definition to inherit the list from values file instead.
  - Added `logzio_app` label with `kubernetes360` value to cadvisor metrics pipeline to avoid dropping specific metrics by matching the k8s 360 filter.
* 3.0.0
  - Updated K360 metrics list in `secrets.yaml` - now created dynamically from OOB filters.
  - Added `job_dummy` relabel and processor - Fixing an issue where duplicate metrics were being sent if the metrics were not in the `K8S_360_METRICS` environment variable.
  - Use attributes processor to create the `unified_status_code` dimension as it supports connectors.
  - **BREAKING CHANGES**:
    - Instead of having the global `metrics.enabled` option of disabling installation of all logzio-telemetry sub charts, each sub chart has its own flag and by default will be installed.
      - `kubeStateMetrics.enabled`
      - `pushGateway.enabled`
      - `nodeExporter.enabled`
* 2.2.0
  - Upgraded SPM collector image to version `0.80.0`.
  - Added service graph connector metrics.
    - `serviceGraph.enabled` option.
  - Refactored span metrics processor to a connector.
    - Added metrics transform processor to modify the data for Logz.io backwards compatibility.
* 2.1.0
  - Update SPM labels
    - Add `rpc_grpc_status_code` dimension
    - Add `unified_status_code` dimension
      - Takes value of `rpc_grpc_status_code` / `http_status_code`
  - Add `containerSecurityContext` configuration option for container based policies. 


<details>
  <summary markdown="span"> Expand to check old versions </summary>

* 2.0.0
  - Upgrade sub charts to their latest versions.
    - `kube-state-metrics` to `4.24.0`
      - Upgraded horizontal pod autoscaler API group version.
    - `prometheus-node-exporter` to `4.23.2`
    - `prometheus-pushgateway` to `2.4.2`
  - Secrets resource name is now changeable via `secrets.name` in `values.yaml`.
  - Fix sub charts conditional installation. 
  - Add conditional creation of `CustomTracingEndpoint` secret key. 
* 1.3.0
  - Upgraded horizontal pod autoscaler API group version.
* 1.2.0
  - Upgraded collector image to `0.80.0`.
  - Changed condition to filter duplicate metrics collected by daemonset collector.
* 1.1.0
  - Add custom tracing endpoint option
* 1.0.3
  - Fixed an issue when enabling dropKubeSystem filter where namespace label values were not filtered.
* 1.0.2
  - Rename `spm` k8s metadata fields
* 1.0.1
  - Fixed `spm` service component name
  - Add `spm` cloud metadata
  - Rename `spm` k8s metadata fields
* 1.0.0 
  - Fixed an issue where when enabling `enableMetricsFilter.kubeSystem` installation failes.
  - **BREAKING CHANGES**:
    - Rename `enableMetricsFilter.kubeSystem` to `enableMetricsFilter.dropKubeSystem`, in order to avoid confusion between functionality of filters.
* 0.2.1
  - Rename k8s attributes for traces pipeline.
  - SPM: add dimension `http.status_code`.
* 0.2.0
  - **BREAKING CHANGES**:
   - Added `applicationMetrics.enabled` value (defaults to `false`)
* 0.1.1
  - Added added resourcedetection processor - added kubernetes spm labels and traces fields.
* 0.1.0 
  - **BREAKING CHANGES**:
    - Split prometheus scrape jobs to separate pipelines:
      - Infrastrucutre: includes kubernetes-service-endpoints, windows-metrics, collector-metrics & cadvisor jobs.
      - Applications: includes applications jobs
    - Improved prometheus filters mechanism:
      - Users can now easily add custom filters for metrics, namesapces & services
      using `prometheusFilters` in `values.yaml`. For more information view [Adding additional filters](#adding-addiotional-filters-for-metrics-scraping) 
    - Added spot labels for kube-state-metrics.
* 0.0.29
  - Upgrade traces and metrics otel image `0.70.0` -> `0.78.0`
  - Upgrade spm image `0.70.0` -> `0.73.0`
  - Added values for seprate spm iamge  
* 0.0.28
  - Change default metrics scrape and export values to handle more cases
  - Reorder processors
  - Remove the `memory_limiter` processor
* 0.0.27
  - Removed duplicate `prometheus.io/scrape` annotation from `kube-state-metrics` (@dlip)
* 0.0.26
  - Added `applications` scrape job for `daemonset` collector mode.
  - Added `secrets.enabled` value.

* 0.0.25
  - Added affinity condition to the daemonset collector.
  - Added opencost duplicate metrics filtering. NOTE: Opencost can be enabled with [Logzio Monitorig Helm Chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring)
  - Fix condition for collector service.
  - Improved naming of the collector deployments:
    - Daemonset pods now have the "ds" suffix.
    - Standalone pod now have the "standalone" suffix.

* 0.0.24
  - Added `collector.mode` flag - now supports `standalone` and `daemonset`, default is `daemonset`.
  - Fixed subchart conditions.
  - Added `VALUES.md`. 
  - Increased minimum memory (`1024Mi`) and cpu (`512m`) requiremts for the collector pods.

* 0.0.23
  - Updated metrics filter (#219)
* 0.0.22
  - **breaking changes:** Add separate span metrics component that includes the following resources:
    - `deployment-spm.yaml`
    - `service-spm.yaml`
    - `configmap-spm.yaml`
  - Updated collector image -> `0.70.0`
* 0.0.21
  - Updated collector image - fixing memory leak crash.
* 0.0.20
  - Change the default port for node exporter `9100` -> `9101` to avoid pods stocking on pending state if a user has `node-exporter` daemon set deployed on the cluster
  - Update otel `0.64.0` -> `0.66.0` 
  - Add `logzio_agent_version` label
  - Add `logz.io/app=kubertnetes360` annotation to `Kube-state-metrics` and `node-exporter`
  - Add `filter/kubernetes360` processor for metrics, to avoid duplicated metrics if a user has `Kube-state-metrics` or `node-exporter` deployed on the cluster
* 0.0.19
  - Drop metrics from `kube-system` namespace
* 0.0.18
  - Add `kube_pod_container_status_terminated_reason` `kube_node_labels` metrics to filters
* 0.0.17
  - Add `kube_pod_container_status_waiting_reason` metric to filters
* 0.0.16
  - Add `kube_deployment_labels` `node_memory_Buffers_bytes` `node_memory_Cached_bytes` metrics to filters
* 0.0.15
  - Add `applications` job
  - Add `collector-metrics` job
  - Replace `$` -> `$$` to escape special char
  - Upgrade otel image `0.60.0`-> `0.64.0`
  - Add `k8s 360` metrics to filters
* 0.0.14
  - Add `k8sattributesprocessor`
  - Require `p8s-logzio-name` only if `metrics` or `spm` are enabled
  - Add `resource/k8s` processor
* 0.0.13
  - Change to `prometheus` exporter for spanmetrics
* 0.0.12
  - Add listener url when `spm` is enabled.
* 0.0.11
  - Change default values of `secrets.SamplingProbability`, `secrets.SamplingLatency`
* 0.0.10
  - `SampelingProbability` -> `SamplingProbability`
* 0.0.9
  - Remove `decision_wait` `num_traces` `expected_new_traces_per_sec` options from the tail sampling proccessor, in order to use the otel default values for the proccessor
  - Fix typos
* 0.0.8
  - Changed default value for `env_id`
* 0.0.7
  - Added default value for `env_id`
* 0.0.6
  - Added span metrics
  - Added sampling
* 0.0.5
  - Upgrade otel collector image -> `otel/opentelemetry-collector-contrib:0.60.0`
* 0.0.4
  - Added basic metrics filtering for gke,aks and eks clusters (via "enableMetricsFilter" parameter).
  - Fixed an issue where windows-metrics scraping job trying to scrape linux nodes on gke.
  - Added an option to disable kube-dns service scraping on eks (via "disableKubeDnsScraping" parameter), to prevent contiunous warning logs.
* 0.0.3
  - Dep: kube-state-metrics -> `4.13.0`
  - Dep: prometheus-node-exporter -> `3.3.0`
  - Dep: prometheus-pushgateway -> `1.18.2`
  - Remove batch processor from metrics pipeline
  - Modify resource limitations
* 0.0.2
  - Add default `nodeAffinity` to prevent node exporter deamonset deploymment on fargate nodes
* 0.0.1 - Initial release
</details>
