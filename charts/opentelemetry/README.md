
# Logzio-otel-k8s-metrics

##  Overview

You can use a Helm chart to ship Kubernetes logs to Logz.io via the OpenTelemetry collector.
The Helm tool is used to manage packages of pre-configured Kubernetes resources that use charts.

**logzio-otel-k8s-metrics** allows you to ship metrics from your Kubernetes cluster to Logz.io with the OpenTelemetry collector.

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

Replace the Logz-io `<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping) of the metrics account to which you want to send your data.


Replace `<<LISTENER-HOST>>` with your region’s listener host (for example, `https://listener.logz.io:8053`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

Replace `<<ENV-TAG>>` with the name for the environment's metrics, to easily identify the metrics for each environment.

###### Run the Helm deployment code for clusters with no Windows Nodes

```
helm install  \
--set secrets.MetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set secrets.ListenerHost=<<LISTENER-HOST>> \
--set secrets.p8s_logzio_name=<<ENV-TAG>> \
logzio-otel-k8s-metrics logzio-helm/logzio-otel-k8s-metrics
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
logzio-otel-k8s-metrics logzio-helm/logzio-otel-k8s-metrics
```

* Replace `<<WINDOWS-NODE-USERNAME>>` with the username for the Node pool you want the Windows exporter to be installed on.

* Replace `<<WINDOWS-NODE-PASSWORD>>` with the password for the Node pool you want the Windows exporter to be installed on.

##### Check Logz.io for your metrics

Give your metrics some time to get from your system to ours, then open [Logz.io](https://app.logz.io/).


####  Customizing Helm chart parameters


##### Configure customization options

You can use the following options to update the Helm chart parameters: 

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`

* Edit the `values.yaml`

* Overide default values with your own `my_values.yaml` and apply it in the `helm install` command. 

###### Example:

```
helm install logzio-otel-k8s-metrics logzio-helm/logzio-otel-k8s-metrics -f my_values.yaml 
```

##### Customize the metrics collected by the Helm chart 

The default configuration uses the Prometheus receiver with the following scrape jobs:

* Cadvisor: Scrapes container metrics
* Kubernetes service endpoints: These jobs scrape metrics from the node exporters, from Kube state metrics, from any other service for which the `prometheus.io/scrape: true` annotaion is set, and from services that expose Prometheus metrics at the `/metrics` endpoint.

To customize your configuration, edit the `config` section in the `values.yaml` file.

#### Using Out of the box metrics filters for Logzio dashboards

In order to prevent unnecessary metrics being sent to Logzio and reduce usage cost,
you can use predefined metrics filters. These filters will send only the metrics that are being used in Logzio's Kubernetes dashboard: Cluster Componenets, Cluster Summary, Pods and Nodes.

To enable metrics filtering, set the following flag when deploying the chart, replace: ```<<cloud-service>>``` with `eks`, `gke` or `aks`.
```
--set enableMetricsFilter.<<cloud-service>>=true
```


#### Disabling kube-dns scraping for EKS clusters
Currently on EKS, kube-dns metrics cannot be scraped from the kube-dns system service - the port used for scraping is already in use, resulting in a warning in the collector pod logs:
```
	Failed to scrape Prometheus endpoint	{"kind": "receiver", "name": "prometheus", "pipeline": "metrics", "scrape_timestamp": 1659031329447, "target_labels": "map[__name__:up eks_amazonaws_com_component:kube-dns instance:: job:kubernetes-service-endpoints k8s_app:kube-dns kubernetes_io_cluster_service:true kubernetes_io_name:CoreDNS kubernetes_node: namespace:kube-system pod:coredns service:kube-dns]"}
```

 A workaround for this issue is creating a seperate kube-dns service and adding the necessary annotations for it to be scraped.
If you have no need for the kube-dns metrics (i.e using one of logzio metrics filters), the error can by enabling the flag:
```
--set disableKubeDnsScraping=true
```
which will cause the prometheus receiver to no scrape the kube-dns service.

More informtion can be found in github issue:
https://github.com/aws/containers-roadmap/issues/965



#### Uninstalling the Chart

The uninstall command is used to remove all the Kubernetes components associated with the chart and to delete the release.  

To uninstall the `logzio-otel-k8s-metrics` deployment, use the following command:

```shell
helm uninstall logzio-otel-k8s-metrics
```

## Sending logs from nodes with taints

If you want to ship logs from any of the nodes that have a taint, make sure that the taint key values are listed in your in your daemonset/deployment configuration as follows:

```yaml
tolerations:
- key: 
  operator: 
  value: 
  effect: 
```

To determine if a node uses taints as well as to display the taint keys, run:

```sh
kubectl get nodes -o json | jq ".items[]|{name:.metadata.name, taints:.spec.taints}"
```

## Change log
* 0.2.5 -
  <ul>
  <li> Added basic metrics filtering for gke,aks and eks clusters (via "enableMetricsFilter" parameter).
  </li>
    <li> Fixed an issue where windows-metrics scraping job trying to scrape linux nodes on gke.
  </li>
    <li> Added an option to disable kube-dns service scraping on eks (via "disableKubeDnsScraping" parameter), to prevent contiunous warning logs.
  </li>
  <li>Node exporter chart version bump to 3.3.0.</li>
  <li>Kube state metrics chart version bump to 4.13.0.</li>
  <li>Prometheus push gateway chart version bump to 1.18.2.</li>
  </ul>

* 0.2.4 -
  <ul>
  <li>
  Upgraded otel-col-contrib image to 0.55.0.
  </li>
  </ul>

<details>
  <summary markdown="span"> Expand to check old versions </summary>

* 0.2.3 - 
  <ul>
  <li>Fixed an issue where the windows reverse proxy daemonset is listed as a resource when there are no windows nodes. </li>
  <li>Disabled the usage of the depracted PodSecurityPolicy (psp).</li>
  <li>Node exporter chart version bump to 2.0.4.</li>
  <li>Kube state metrics chart version bump to 4.7.0.</li>
  <li>Prometheus push gateway chart version bump to 1.16.1.</li>
  </ul>

* 0.2.2 - Windows exporter installer jobs will now run only when username and password are provided.

* 0.2.1 - Added Windows exporter installer as a scheduled job.

* 0.2.0 -
  <ul>
  <li>Added support for Windows Nodes metrics. </li>
  <li>Updated otel collector image tag and removed deprecated settings. </li>
  </ul>
* 0.1.1 - Add option to enable pushgatway service
* 0.1.0 - Initial release

</details>

