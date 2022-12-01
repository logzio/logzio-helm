# Logzio-k8s-telemetry

**Note**: This chart is for shipping metrics and traces only. For a chart that ships all telemetry (logs, metrics, traces, spm) - use our [Logzio Monitoring chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring).

##  Overview

You can use a Helm chart to ship Kubernetes metrics and traces to Logz.io via the OpenTelemetry collector.
The Helm tool is used to manage packages of pre-configured Kubernetes resources that use charts.

**logzio-k8s-telemetry** allows you to ship metrics and traces from your Kubernetes cluster to Logz.io with the OpenTelemetry collector.

**Note:** This chart is a fork of the [opentelemtry-collector](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) Helm chart. 
It is also dependent on the [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics/tree/master/charts/kube-state-metrics) and [prometheus-node-exporter](https://github.com/helm/charts/tree/master/stable/prometheus-node-exporter) charts, which are installed by default. 
To disable the dependency during installation, set `kubeStateMetrics.enabled` and `nodeExporter` to `false`.



#### Before installing the chart
Check if you have any taints on your nodes:

```
kubectl get nodes -o json | jq '"\(.items[].metadata.name) \(.items[].spec.taints)"'
```
if you do, please add them as tolerations in values.yaml tolerations.


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


#### Using Out of the box metrics filters for Logzio dashboards

You can use predefined metrics filters to prevent unnecessary metrics being sent to Logz.io and reduce usage cost.
These filters will only send the metrics that are being used in Logz.io's Kubernetes dashboard: Cluster Componenets, Cluster Summary, Pods and Nodes.

To enable metrics filtering, set the following flag when deploying the chart, replace: `<<cloud-service>>` with `eks`, `gke` or `aks`.

```
--set enableMetricsFilter.<<cloud-service>>=true
```


#### Disabling kube-dns scraping for EKS clusters

In the current EKS setup, kube-dns metrics cannot be scraped from the kube-dns system service as the port used for scraping is already in use. This results in the following warning in the collector pod logs:

```
	Failed to scrape Prometheus endpoint	{"kind": "receiver", "name": "prometheus", "pipeline": "metrics", "scrape_timestamp": 1659031329447, "target_labels": "map[__name__:up eks_amazonaws_com_component:kube-dns instance:: job:kubernetes-service-endpoints k8s_app:kube-dns kubernetes_io_cluster_service:true kubernetes_io_name:CoreDNS kubernetes_node: namespace:kube-system pod:coredns service:kube-dns]"}
```

A workaround for this issue is to create a seperate kube-dns service and add the necessary annotations to enable scraping.
If you do not need the kube-dns metrics (i.e using one of Logz.io metrics filters), enable the following flag:

```
--set disableKubeDnsScraping=true
```

This will disable scraping for the kube-dns service in the prometheus receiver.

More informtion can be found in the following GitHub issue:
https://github.com/aws/containers-roadmap/issues/965


#### Uninstalling the Chart

The uninstall command is used to remove all the Kubernetes components associated with the chart and to delete the release.  

To uninstall the `logzio-k8s-telemetry` deployment, use the following command:

```shell
helm uninstall logzio-k8s-telemetry
```


## Change log
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

<details>
  <summary markdown="span"> Expand to check old versions </summary>


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
