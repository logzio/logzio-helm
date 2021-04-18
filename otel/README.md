
# Logzio-k8s-metrics

Helm is a tool for managing packages of pre-configured Kubernetes resources using Charts.
Logzio-k8s-metrics allows you to ship metrics from your Kubernetes cluster.  

### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed


**Note:** Helm 2 will reach [EOL on November 2020](https://helm.sh/blog/2019-10-22-helm-2150-released/#:~:text=6%20months%20after%20Helm%203's,Helm%202%20will%20formally%20end). This document follows the command syntax recommended for Helm 3, but the Chart will work with both Helm 2 and Helm 3.

<div id="default-config">



### Deployment:

#### 1. Add logzio-k8s-metrics repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm/otel
```

#### 2. Deploy

<div id="standard-config">

#### Deploy with standard configuration:  

Replace `<<METRICS-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-HOST>>` with your region’s listener host (for example, `listener.logz.io`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

Replace `<<ENV-TAG>>`

```shell
helm install  \
--set secrets.MetricsToken=<<METRICS-TOKEN>> \
--set secrets.ListenerHost=<<LISTENER-HOST>> \
--set secrets.p8s_logzio_name=<<ENV-TAG>> \
logzio-k8s-metrics logzio-helm/otel
```
</div>

#### 3. Check Logz.io for your metrics

Give your metrics some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

</div>

### Configuration

If you wish to change the default values, specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```shell
helm install --namespace=kube-system logzio-k8s-metrics logzio-helm/logzio-k8s-metrics \
  --set=imageTag=7.7.0,terminationGracePeriodSeconds=30
```

To override configurations such as `metricbeatConfig.autoCustomConfig`, `deployment.metricbeatConfig.custom` and `daemonset.metricbeatConfig.custom`, use the `--set-file` argument in `helm install`. For example,
```shell
helm install --namespace=kube-system logzio-k8s-metrics logzio-helm/logzio-k8s-metrics \
  --set-file deployment.metricbeatConfig.custom=/path/to/your/config.yaml
```

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.  
To uninstall the `logzio-k8s-metrics` deployment:

```shell
helm uninstall logzio-k8s-metrics
```


## Change log
