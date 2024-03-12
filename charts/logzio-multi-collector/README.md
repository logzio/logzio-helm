# Logzio-multi-collector

**Note**: This chart is for shipping metrics only. For a chart that ships all telemetry (logs, metrics, traces, spm) - use our [Logzio Monitoring chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring).

##  Overview

You can use a Helm chart to ship Kubernetes metrics to Logz.io via the OpenTelemetry collector.
The Helm tool is used to manage packages of pre-configured Kubernetes resources that use charts.

**logzio-multi-collector** allows you to ship metrics from your Kubernetes cluster to Logz.io with multiple instaces of the OpenTelemetry collector, splitting the load between instaces, increasing stabillity and reliability of data collection.

By default, one instace is deployed for cadvisor metrics, and additional instace per defined namespace.


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

Replace the Logz-io `<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping) of the metrics account to which you want to send your data.

Replace `<<LISTENER-HOST>>` with your region’s listener host (for example, `https://listener.logz.io:8053`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).


#### Deploy the chart: An example for a default namespace
```
helm install  \
--set metrics.enabled=true \
--set secrets.MetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set secrets.ListenerHost=<<LISTENER-HOST>> \
--set secrets.p8s_logzio_name=<<P8S-LOGZIO-NAME>> \
--set secrets.env_id=<<ENV-ID>> \
--set "multiCollector.namespace[0]=default" \
logzio-multi-collector logzio-helm/logzio-multi-collector
```

This command above will result on deploying 2 separate collector instances, one will collect metrics from `cadvisor` (all nodes), and the second will collect metrics from all available endpoints in the `default` namespace.


##### Check Logz.io for your metrics

Give your metrics some time to get from your system to ours, then open [Logz.io](https://app.logz.io/).


####  Customizing Helm chart parameters
See `VALUES.md` for additional information.

##### Configure customization options

You can use the following options to update the Helm chart parameters: 

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`

* Edit the `values.yaml`

* Overide default values with your own `my_values.yaml` and apply it in the `helm install` command. 

###### Example:

```
helm install logzio-multi-collector
 logzio-helm/logzio-multi-collector -f my_values.yaml 
```

##### Customize the metrics collected by the Helm chart 

The default configuration uses the Prometheus receiver with the following scrape jobs:

* Cadvisor: Scrapes container metrics
* Kubernetes service endpoints: These jobs scrape metrics from the node exporters, from Kube state metrics, from any other service for which the `prometheus.io/scrape: true` annotaion is set, and from services that expose Prometheus metrics at the `/metrics` endpoint.

To customize your configuration, edit the `config` section in the `values.yaml` file.

### Cadvisor collector instance

By default, an instance of the collector is deployed in order to collect cadvisor metrics.
This instace can be disable with:
`--set multiCollector.cadvisorCollector.enabled=false`


### Defining custom resources for each collector instance

The metrics load between namespaces is evenly dsitributed in rare cases.
In order to provide flexibility between the instaces deployed, you can define custom resource requirements for each instance, memory & cpu.
`--set multiCollector.namespace.<<namespace name>>.resources.limits.memory=<<>>`
`--set multiCollector.namespace.<<namespace name>>.resources.limits.cpu=<<>>`
`--set multiCollector.namespace.<<namespace name>>.resources.requests.memory=<<>>`
`--set multiCollector.namespace.<<namespace name>>.resources.requests.cpu=<<>>`


### Adding application metrics

To enable applications metrics scraping set the `applicationMetrics.enabled` value to `true`.

```sh
--set applicationMetrics.enabled=true
```

This will enable the `metrics/applications` pipline and will scrape metrics from pods with the `prometheus.io/scrape=true` annotation

### Using Out of the box metrics filters for Logzio dashboards

You can use predefined metrics filters to prevent unnecessary metrics being sent to Logz.io and reduce usage cost.
These filters will only send the metrics that are being used in Logz.io's Kubernetes dashboard: Cluster Componenets, Cluster Summary, Pods and Nodes.

To enable metrics filtering, set the following flag when deploying the chart, replace: `<<cloud-service>>` with `eks`, `gke` or `aks`.

```
--set enableMetricsFilter.<<namespace name>>.<<cloud-service>>=true
```

### Adding addiotional filters for metrics scraping

To add flexibility for the metrics filtering, you can add custom filters for the following:
- metric name (keep & drop)
- service names (keep & drop - only for infrastructure pipeline)
- namespace names

Added filters should be in the format of regex, i.e: `"metrics1|metric2"` etc.
To add a custom filter, choose to which pipeline the filter is needed, and add the filter under the `custom` key accordingly.
For example, when deploying a collector instace a namespace, to add a custom `metrics` keep filter to the application metric job, you can set:

```
--set prometheusFilters.<<namespace name>>.metrics.applications.custom="metric_1|metric_2"
```

For more information, view `prometheusFitlers` in [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/logzio-telemetry/values.yaml).


### Filtering metrics from `kube-system` namesapce

To Filter out metrics from `kube-system` namesapce, set the following flag when deploying the chart.

```
--set enableMetricsFilter.<<namespace name>>.dropKubeSystem=true
```

### Disabling kube-dns scraping for EKS clusters

In the current EKS setup, kube-dns metrics cannot be scraped from the kube-dns system service as the port used for scraping is already in use. This results in the following warning in the collector pod logs:

```
	Failed to scrape Prometheus endpoint	{"kind": "receiver", "name": "prometheus", "pipeline": "metrics", "scrape_timestamp": 1659031329447, "target_labels": "map[__name__:up eks_amazonaws_com_component:kube-dns instance:: job:kubernetes-service-endpoints k8s_app:kube-dns kubernetes_io_cluster_service:true kubernetes_io_name:CoreDNS kubernetes_node: namespace:kube-system pod:coredns service:kube-dns]"}
```

A workaround for this issue is to create a seperate kube-dns service and add the necessary annotations to enable scraping.
By default, the kube-dns service filter is enabled, using the flag:

```
--set enableMetricsFilter.<<namespace name>>.disableKubeDns=true
```

More informtion can be found in the following GitHub issue:
https://github.com/aws/containers-roadmap/issues/965


### Uninstalling the Chart

The uninstall command is used to remove all the Kubernetes components associated with the chart and to delete the release.  

To uninstall the `logzio-multi-collector` deployment, use the following command:

```shell
helm uninstall logzio-multi-collector
```


## Change log

* 0.0.1 
  - Initial release

<details>
  <summary markdown="span"> Expand to check old versions </summary>

</details>
