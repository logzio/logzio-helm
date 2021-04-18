
# Logzio-otel-k8s-metrics

Helm is a tool for managing packages of pre-configured Kubernetes resources using Charts.
logzio-otel-k8s-metrics allows you to ship metrics from your Kubernetes cluster using opentelemtry collctor.

**Note:** This chart is a fork of the [opentelemtry-collector](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) helm chart, it is also dependent on the [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics/tree/master/charts/kube-state-metrics) and [prometheus-node-exporter](https://github.com/helm/charts/tree/master/stable/prometheus-node-exporter) charts.

### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed


**Note:** Helm 2 will reach [EOL on November 2020](https://helm.sh/blog/2019-10-22-helm-2150-released/#:~:text=6%20months%20after%20Helm%203's,Helm%202%20will%20formally%20end). This document follows the command syntax recommended for Helm 3, but the Chart will work with both Helm 2 and Helm 3.




### Deployment:

#### 1. Add logzio-otel-k8s-metrics repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm/otel
```

#### 2. Deploy


#### Deploy with standard configuration:  

Replace `<<METRICS-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-HOST>>` with your region’s listener host (for example, `https://listener.logz.io:8053`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

Replace `<<ENV-TAG>>`

```
helm install  \
--set secrets.MetricsToken=<<METRICS-TOKEN>> \
--set secrets.ListenerHost=<<LISTENER-HOST>> \
--set secrets.p8s_logzio_name=<<ENV-TAG>> \
logzio-otel-k8s-metrics logzio-helm/otel
```

#### 3. Check Logz.io for your metrics

Give your metrics some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).


### Configuration

If you wish to change the default values you have few options:

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`

* Edit the `values.yaml`

* Overide deafult values with your own `my_values.yaml` and apply it in the `helm install` command. For exapmle:

```
helm install logzio-otel-k8s-metrics logzio-helm/otel -f my_values.yaml
```
### Collected metrics
The deafult set up is using the prometheus reciver with three scrape jobs:
* Kube state metrics
* Cadvisor: scrapes container metrics
* Kubernetes service endpoints: scrapes metrics from the node exporters, and any other service with `prometheus.io/scrape: true` annotaion that, expose prometheus metrics at `/metrics` endpoint

You can customize your configuration by editing the `config` section in the `values.yaml` file.

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.  
To uninstall the `logzio-otel-k8s-metrics` deployment:

```shell
helm uninstall logzio-otel-k8s-metrics
```


## Change log
