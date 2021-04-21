
# Logzio-otel-k8s-metrics

The Helm tool is used to manage packages of pre-configured Kubernetes resources that use Charts.
logzio-otel-k8s-metrics allows you to ship metrics from your Kubernetes cluster with the OpenTelemetry collector.

**Note:** This chart is a fork of the [opentelemtry-collector](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) helm chart, it is also dependent on the [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics/tree/master/charts/kube-state-metrics) and [prometheus-node-exporter](https://github.com/helm/charts/tree/master/stable/prometheus-node-exporter) charts, that will be installed by default. To disable the dependency during installation, set `kubeStateMetrics.enabled` and `nodeExporter` to `false`.

### Prerequisites:
* [Helm 3](https://helm.sh/docs/intro/install/) installed


### Deployment:

#### 1. Add the logzio-otel-k8s-metrics repo to your Helm repo list

```shell
helm repo add logzio-otel https://logzio.github.io/logzio-helm/opentelemtry/
```

#### 2. Deploy


#### Deploy with standard configuration:  

Replace the Logz-io `<<METRICS-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the metrics account you want to ship to.

Replace `<<LISTENER-HOST>>` with your region’s listener host (for example, `https://listener.logz.io:8053`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

Replace `<<ENV-TAG>>` with the name for the environment's metrics, to easily identify the metrics for each environment.

```
helm install  \
--set secrets.MetricsToken=<<METRICS-TOKEN>> \
--set secrets.ListenerHost=<<LISTENER-HOST>> \
--set secrets.p8s_logzio_name=<<ENV-TAG>> \
logzio-otel-k8s-metrics logzio-otel/logzio-otel-k8s-metrics
```

#### 3. Check Logz.io for your metrics

Give your metrics some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).


### Configuration

You can use the following options to update your default parameter values: 

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`

* Edit the `values.yaml`

* Overide default values with your own `my_values.yaml` and apply it in the `helm install` command. For exapmle:

```
helm install logzio-otel-k8s-metrics logzio-otel/logzio-otel-k8s-metrics -f my_values.yaml 
```
### Collected metrics

The default set up uses the Prometheus receiver with the following scrape jobs:
* Cadvisor: Scrapes container metrics
* Kubernetes service endpoints: These job scrape metrics from the node exporters, Kube state metrics, from any other service for which the `prometheus.io/scrape: true` annotaion is set, and from services that expose Prometheus metrics at the `/metrics` endpoint.

You can customize your configuration by editing the `config` section in the `values.yaml` file.

### Uninstalling the Chart

The uninstall command is used to remove all the Kubernetes components associated with the chart and deletes the release.  
To uninstall the `logzio-otel-k8s-metrics` deployment:

```shell
helm uninstall logzio-otel-k8s-metrics
```


## Change log
