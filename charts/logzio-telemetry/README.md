# Logzio-k8s-telemetry

**Note**: This chart is specifically designed for shipping metrics and traces only. For a chart that handles all telemetry data—including logs, metrics, traces, and SPM—please use our [Logzio Monitoring chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring).

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
- Replace `<<*ENV-ID*>>` with the name for your environment's identifier, to easily identify the telemetry data for each environment.
- Replace `<<LOGZIO-REGION>>` with the name of your Logz.io region e.g `us`,`eu`.

#### For metrics:
- Enable the metrics configuration for this chart: `--set metrics.enabled=true`
- Replace the Logz-io `<<PROMETHEUS-METRICS-SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping) of the metrics account to which you want to send your data.


#### For traces:
- Enable the traces configuration for this chart: --set traces.enabled=true
- Replace the Logz-io `<<TRACES-SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping) of the traces account to which you want to send your data.



###### Run the Helm deployment code for clusters with no Windows Nodes

#### Deploy the metrics chart:
```
helm install  \
--set metrics.enabled=true \
--set global.logzioMetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set global.logzioRegion=<<LOGZIO-REGION>> \
--set global.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

#### Deploy the traces chart:
```
helm install \
--set traces.enabled=true \
--set global.logzioTracesToken=<<TRACES-SHIPPING-TOKEN>> \
--set global.logzioRegion=<<LOGZIO-REGION>> \
--set global.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

#### Deploy the traces chart with span metrics:
**Note** `spm.enabled=true` will have no effect unless `traces.enabled` is also set to `true`
```
helm install \
--set traces.enabled=true \
--set spm.enabled=true \
--set global.logzioSpmToken=<<SPM-SHIPPING-TOKEN>> \
--set global.logzioTracesToken=<<TRACES-SHIPPING-TOKEN>> \
--set global.logzioRegion=<<LOGZIO-REGION>> \
--set global.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

#### Deploy both charts with span metrics:
**Note** `spm.enabled=true` will have no effect unless `traces.enabled` is also set to `true`
```
helm install  \
--set traces.enabled=true \
--set spm.enabled=true \
--set global.logzioTracesToken=<<TRACES-SHIPPING-TOKEN>> \
--set global.logzioSpmToken=<<SPM-SHIPPING-TOKEN>> \
--set global.logzioRegion=<<LOGZIO-REGION>> \
--set metrics.enabled=true \
--set global.logzioMetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set global.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

#### Deploy both charts with span metrics and service graph
**Note** `serviceGraph.enabled=true` will have no effect unless `traces.enabled` & `spm.enabled=true` is also set to `true`
```
helm install  \
--set traces.enabled=true \
--set spm.enabled=true \
--set serviceGraph.enabled=true \
--set global.logzioTracesToken=<<TRACES-SHIPPING-TOKEN>> \
--set global.logzioSpmToken=<<SPM-SHIPPING-TOKEN>> \
--set global.logzioRegion=<<LOGZIO-REGION>> \
--set metrics.enabled=true \
--set global.logzioMetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set global.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

#### Deploy metrics chart with Kuberenetes object logs correlation
**Note** `k8sObjectsConfig.enabled=true` will have no effect unless `metrics.enabled` is also set to `true`
```
helm install  \
--set metrics.enabled=true \
--set k8sObjectsConfig.enabled=true \
--set global.logzioRegion=<<LOGZIO-REGION>> \
--set global.logzioLogsToken=<<LOGZIO-LOG-SHIPPING-TOKEN>> \
--set global.logzioMetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set global.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

#### Deploy the metrics chart with SignalFx receiver:
The SignalFx receiver allows the chart to accept metrics from SignalFx client libraries and forward them to Logz.io. This is useful when migrating from SignalFx or when you have applications already instrumented with SignalFx libraries.

**Note** `global.signalFx.enabled=true` will have no effect unless `metrics.enabled` is also set to `true`
```
helm install  \
--set metrics.enabled=true \
--set global.signalFx.enabled=true \
--set global.logzioMetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set global.logzioRegion=<<LOGZIO-REGION>> \
--set global.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

The SignalFx receiver will listen on port 9943 for incoming metrics. You can customize the receiver configuration by modifying the `signalFx.config` section in your values file.

#### Deploy the metrics chart with Carbon receiver:
The Carbon receiver allows the chart to accept metrics from Carbon/Graphite client libraries and forward them to Logz.io. This is useful when migrating from Graphite or when you have applications sending metrics in Carbon format.

**Note** `carbon.enabled=true` will have no effect unless `metrics.enabled` is also set to `true`
```
helm install  \
--set metrics.enabled=true \
--set carbon.enabled=true \
--set global.logzioMetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set global.logzioRegion=<<LOGZIO-REGION>> \
--set global.env_id=<<ENV-ID>> \
logzio-k8s-telemetry logzio-helm/logzio-k8s-telemetry
```

The Carbon receiver will listen on port 2003 for incoming metrics. You can customize the receiver configuration by modifying the `carbon.config` section in your values file.

#### Handling image pull rate limit
In some cases (i.e spot clusters) where the pods/nodes are replaced frequently, the pull rate limit for images pulled from dockerhub might be reached, with an error:
`You have reached your pull rate limit. You may increase the limit by authenticating and upgrading: https://www.docker.com/increase-rate-limits`.
In these cases we can use the following `--set` commands to use an alternative image repository:

```shell
--set image.repository=ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib
--set prometheus-pushgateway.image.repository=public.ecr.aws/logzio/prom-pushgateway
```


#### For clusters with Windows Nodes


To extract and scrape metrics from Windows Nodes, a Windows Exporter service must be installed on the node host. This installation is accomplished by authenticating with a username and password via an SSH connection to the node through a job.

By default, the Windows installer job will execute upon deployment and subsequently every 10 minutes, retaining the most recent failed and successful pods.
You can modify these settings in the `values.yaml` file:

```
windowsExporterInstallerJob:
  interval: "*/10 * * * *"           #In CronJob format
  concurrencyPolicy: Forbid          # Future cronjob will run only after current job is finished
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
```

The default username for Windows Node pools is: `azureuser`. (This username and password are shared across all Windows node pools.)

You can change the password for your Windows node pools in the AKS cluster using the following command (this will only affect Windows node pools):

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
--set global.logzioMetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set global.logzioRegion=<<LISTENER-HOST>> \
--set global.env_id=<<ENV-TAG>> \
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
### Using the filters syntax for metrics relabeling

**⚠️ WARNING**: Be extremely careful when filtering infrastructure metrics names as this can break Logz.io K8s 360 dashboard functionality. Always review [FILTERS.md](./FILTERS.md) before implementing custom filters.

You can now use the new `filters` syntax in your `values.yaml` to define flexible include/exclude rules for metrics relabeling in both the infrastructure and applications pipelines. This approach is recommended over the legacy `prometheusFilters` syntax and is fully tested in CI.

**Safe Example** (filtering only application-level metrics):
```yaml
filters:
  applications:
    exclude:
      name: "go_gc_duration_seconds|http_requests_total"
    include:
      namespace: "prod|staging"
      attribute:
        environment: "prod"
```


- Use `include` and `exclude` blocks under each pipeline to specify which metrics, namespaces, or attributes to keep or drop.
- **For infrastructure pipeline filtering**: Please review the essential metrics list in [FILTERS.md](./FILTERS.md) to avoid breaking K8s 360 functionality.
- **For applications pipeline filtering**: Generally safer as it doesn't affect core Kubernetes monitoring.
- For full details and advanced usage, see [FILTERS.md](./FILTERS.md).



### Adding addiotional legacy prometheusFitlers for metrics scraping

To add flexibility for the metrics filtering, you can add custom filters for the following:
- metric name (keep & drop)
- service names (keep & drop - only for infrastructure pipeline)
- namespace names

Added filters should be in the format of regex, i.e: `"metrics1|metric2"` etc.
To add a custom filter, choose to which pipeline the filter is needed, and add the filter under the `custom` key accordingly.
For example, to add a custom `namespace` keep filter to the application metric job, you can set:
```
--set prometheusFilters.namespaces.applications.keep.custom="namesapce_1|namespace_2"
```

For more information, view `prometheusFitlers` in [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/logzio-telemetry/values.yaml).


### Filtering metrics from `kube-system` namesapce

To Filter out metrics from `kube-system` namesapce, set the following flag when deploying the chart.

```
--set enableMetricsFilter.dropKubeSystem=true
```

### Disabling kube-dns scraping for EKS clusters

In the current EKS setup, kube-dns metrics cannot be scraped from the kube-dns system service because the port used for scraping is already in use. This issue generates the following warning in the collector pod logs:

```
	Failed to scrape Prometheus endpoint	{"kind": "receiver", "name": "prometheus", "pipeline": "metrics", "scrape_timestamp": 1659031329447, "target_labels": "map[__name__:up eks_amazonaws_com_component:kube-dns instance:: job:kubernetes-service-endpoints k8s_app:kube-dns kubernetes_io_cluster_service:true kubernetes_io_name:CoreDNS kubernetes_node: namespace:kube-system pod:coredns service:kube-dns]"}
```

A workaround for this issue is to create a separate kube-dns service and add the necessary annotations to enable scraping.
By default, the kube-dns service filter is enabled, using the flag:

```
--set disableKubeDnsScraping=true
```

More informtion can be found in the following GitHub issue:
https://github.com/aws/containers-roadmap/issues/965


### Collector deployment modes
The default collector deployment is as a DaemonSet. This is the recommended deployment method. However, in some cases, such as a small cluster with a low count of metrics/traces, a standalone collector deployment may be more beneficial. For such scenarios, you can use the standalone deployment for the pod:

```
--set collector.mode=standalone
```


### Using pprof extention
The pprof extension in the OpenTelemetry Collector allows you to view and analyze the profile of the collector during runtime. Here's how you can use it:

To download the `go tool pprof` command, you need to install the Go programming language. You can download and install Go from the [official website](https://golang.org/dl/).

Once Go is installed, you can use the `go` command to install pprof and other tools:


```
go get -u golang.org/x/tools/cmd/pprof
```
This command will download and install pprof along with any necessary dependencies. You can then use the `go tool pprof` command.

Alternatively, you can install pprof using a package manager, such as `apt-get` on Ubuntu or `brew` on macOS:


```
sudo apt-get install pprof # on Ubuntu
brew install pprof # on macOS
```

Forward the 1777 pprof port of the collector pod to your local network using the following command:
```
kubectl port-forward <<pod>> 1777:1777
```
Use the `go tool pprof` command to fetch the profile and visualize it in the web UI on port 1212.
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
You can also use the pprof extension to view other types of profiles, such as goroutine, thread creation, and block. To do this, replace the endpoint in the `go tool pprof` command with the appropriate profile type. For example, to view the goroutine profile:

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