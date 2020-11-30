
# Logzio-k8s-metrics

Helm is a tool for managing packages of pre-configured Kubernetes resources using Charts.
Logzio-k8s-metrics allows you to ship metrics from your Kubernetes cluster.  
You can either deploy this Daemonset with the standrad configuration, or with autodiscover configuration. For further information about Metricbeat's autodiscover please see [Autodiscover documentation](https://www.elastic.co/guide/en/beats/metricbeat/7.9/configuration-autodiscover.html).  
*Note*: This integration supports Autodiscover with Metricbeat version 7.6+ and defaults to Metricbeat 7.9.1.


### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed
* [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) installed
* Allow outgoing traffic to destination port 5015
* Kubelet read-only-port 10255 enabled. Kubelet read-only-port 10255 is enabled by default on some cluster versions. If it isn’t enabled, follow Kubernetes’s instructions for enabling 10255 as a read-only-port in Kubelet’s config file

You have two options for deployment:
* [Automated configuration <span class="sm ital">(recommended)</span>](#default-config)
* [Manual configuration](#manual-config)

**Note:** Helm 2 will reach [EOL on November 2020](https://helm.sh/blog/2019-10-22-helm-2150-released/#:~:text=6%20months%20after%20Helm%203's,Helm%202%20will%20formally%20end). This document follows the command syntax recommended for Helm 3, but the Chart will work with both Helm 2 and Helm 3.

<div id="default-config">

### Automatic deployment:

#### 1. Run the automated deployment script
```shell
bash <(curl -s https://raw.githubusercontent.com/logzio/logzio-helm/master/quickstart-metrics.sh)
```
**Note:** The script is currently only compatible with Helm 3.

##### Prompts and answers

| Prompt | Answer |
|---|---|
| Logz.io metrics shipping token (Required) | The [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to. |
| Logz.io region (Default: `Blank (US East)`) | Two-letter region code, or blank for US East (Northern Virginia). This determines your listener URL (where you’re shipping the logs to) and API URL. You can find your region code in the [Regions and URLs](https://docs.logz.io/user-guide/accounts/account-region.html#regions-and-urls) table. |
| Cluster name (Default: `detected by the script`) | The name of the Kubernetes cluster you’re deploying in. |
| Standard or autodiscover deployment (Default: `standard`) | To deploy with [configuration templates](https://www.elastic.co/guide/en/beats/metricbeat/current/configuration-autodiscover.html) answer 'autodiscover'. |

#### 2. Check Logz.io for your metrics
Give your metrics some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

</div>

<div id="manual-config">

### Manual deployment:



#### 1. Add logzio-k8s-metrics repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm/metricbeat
```

#### 2. Deploy

You have three options for deployment:
* [Standard configuration](#standard-config)
* [Autodiscover configuration](#autodiscover-config)
* [Custom configuration](#custom-config)


<div id="standard-config">

#### Deploy with standard configuration:  

Replace `<<METRICS-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-HOST>>` with your region’s listener host (for example, `listener.logz.io`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

Replace `<<KUBE-STATE-METRICS-NAMESPACE>>`, `<<KUBE-STATE-METRICS-PORT>>`, and `<<CLUSTER-NAME>>` in this command to save your cluster details as a Kubernetes secret.

```shell
helm install --namespace=kube-system \
--set=secrets.MetricsToken=<<METRICS-TOKEN>> \
--set=secrets.ListenerHost=<<LISTENER-HOST>> \
--set=secrets.ClusterName=<<CLUSTER-NAME>> \
--set=secrets.KubeStatNamespace=<<KUBE-STATE-METRICS-NAMESPACE>> \
--set=secrets.KubeStatPort=<<KUBE-STATE-METRICS-PORT>> \
logzio-k8s-metrics logzio-helm/logzio-k8s-metrics
```
</div>

<div id="autodiscover-config">

#### Deploy with Autodiscover configuration:  
This Daemonset's default autodiscover configuration is [hints based](https://www.elastic.co/guide/en/beats/metricbeat/current/configuration-autodiscover-hints.html):

```shell
helm install --namespace=kube-system \
--set configType='autodiscover' \
--set=secrets.MetricsToken=<<METRICS-TOKEN>> \
--set=secrets.ListenerHost=<<LISTENER-HOST>> \
--set=secrets.ClusterName=<<CLUSTER-NAME>> \
--set=secrets.KubeStatNamespace=<<KUBE-STATE-METRICS-NAMESPACE>> \
--set=secrets.KubeStatPort=<<KUBE-STATE-METRICS-PORT>> \
logzio-k8s-metrics logzio-helm/logzio-k8s-metrics
```
*For more information about Autodiscover:* [Kubernetes configuration](https://www.elastic.co/guide/en/beats/metricbeat/current/configuration-autodiscover.html#_kubernetes)
, [autodiscover's appenders](https://www.elastic.co/guide/en/beats/metricbeat/current/configuration-autodiscover-advanced.html).

</div>

<div id="custom-config">

#### Deploy with custom configuration:  
```shell
helm install --namespace=kube-system \
--set=secrets.MetricsToken=<<METRICS-TOKEN>> \
--set=secrets.ListenerHost=<<LISTENER-HOST>> \
--set=secrets.ClusterName=<<CLUSTER-NAME>> \
--set=secrets.KubeStatNamespace=<<KUBE-STATE-METRICS-NAMESPACE>> \
--set=secrets.KubeStatPort=<<KUBE-STATE-METRICS-PORT>> \
--set configType='auto-custom' \
--set-file metricbeatConfig.autoCustomConfig=/path/to/your/config.yaml \
logzio-k8s-metrics logzio-helm/logzio-k8s-metrics
```

*Note:* If you're using a custom config, please make sure that you're using a `.yaml` file in the following structure:
```
metricbeat.yml: |-
  metricbeat.config.modules:
    path: ${path.config}/modules.d/*.yml
    reload.enabled: false

  metricbeat.autodiscover:
    # your autodiscover config
    # ...

  processors:
    - add_cloud_metadata: ~
  fields:
    logzio_codec: json
    token: ${LOGZIO_METRICS_SHIPPING_TOKEN}
    cluster: ${CLUSTER_NAME}
    type: metricbeat
  fields_under_root: true
  ignore_older: 3hr
  output:
    logstash:
      hosts: ["${LOGZIO_METRICS_LISTENER_HOST}:5015"]
      ssl:
        certificate_authorities: ['/etc/pki/tls/certs/SectigoRSADomainValidationSecureServerCA.crt']

```

</div>

#### 5. Check Logz.io for your metrics

Give your metrics some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

</div>

### Configuration

| Parameter | Description | Default |
|---|---|---|
| `image` | The Metricbeat Docker image. | `"docker.elastic.co/beats/metricbeat"` |
| `imageTag` | The Metricbeat Docker image tag. | `"7.9.1"` |
| `nameOverride` | Overrides the Chart name for resources. | `""` |
| `fullnameOverride` | Overrides the full name of the resources. | `"metricbeat"` |
| `apiVersions.ConfigMap` | API version of `configmap.yaml`. | `v1` |
| `apiVersions.Deployment` | API version of `deployment.yaml.` | `apps/v1` |
| `apiVersions.DaemonSet` | API version of `daemonset.yaml`. | `apps/v1` |
| `apiVersions.ServiceAccount` | API version of `serviceaccount.yaml`. | `v1` |
| `apiVersions.ClusterRole` | API version of `clusterrole.yaml`. | `rbac.authorization.k8s.io/v1beta1` |
| `apiVersions.ClusterRoleBinding` | API version of `clusterrolebinding.yaml`. | `rbac.authorization.k8s.io/v1beta1` |
| `apiVersions.Secrets` | API version of `secrets.yaml`. | `v1` |
| `shippingProtocol` | Shipping protocol. | `http` |
| `shippingPort` | Shipping port. | `10255` |
| `serviceAccount.create` | Specifies whether a service account should be created. | `true` |
| `serviceAccount.name` | Name of the service account. | `metricbeat` |
| `podSecurityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Metricbeat DaemonSet and Deployment pod execution environment. | `{}` |
| `resources` | Allows you to set the resources for both Metricbeat DaemonSet and Deployment. | `{}` |
| `clusterRoleRules` | Configurable [cluster role rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole) that Metricbeat uses to access Kubernetes resources. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml)..... |
| `managedServiceAccount` | Specifies whether the serviceAccount should be managed by this helm Chart. Set this to false to manage your own service account and related roles. | `true` |
| `secretMounts` | Allows you to easily mount a secret as a file inside DaemonSet and Deployment. Useful for mounting certificates and other secrets. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `terminationGracePeriod` | Termination period (in seconds) to wait before killing Metricbeat pod process on pod shutdown. | `30` |
| `hostPathRoot` | Fully-qualified [hostPath](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath) that will be used to persist Metricbeat registry data. | `/var/lib` |
| `logzioCert` | Logzio public SSL certificate. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `metricbeatConfig` | Metricbeat configuration. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `daemonset.leanConfig` | When set to `true`, sets the Daemonset's Metricbeat modules configuration to the minimal configuration required to populate Logz.io's dashboards. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `daemonset.extraVolumeMounts` | Templatable string of additional `volumeMounts` to be passed to the DaemonSet. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `daemonset.extraVolumes` | Templatable string of additional `volumes` to be passed to the DaemonSet. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `daemonset.metricbeatConfig.default` | Default configuration for Daemonset's Metricbeat modules. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `daemonset.metricbeatConfig.lean` | Lean configuration for Daemonset's Metricbeat modules. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `daemonset.metricbeatConfig.custom` | Allows you to add any config files in `/usr/share/metricbeat` such as `metricbeat.yml` for Metricbeat Daemonset. <br> Please note that the custom config should be formatted and indented as in `daemonset.metricbeat.config.default`. | `{}` |
| `daemonset.securityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Metricbeat DaemonSet pod execution environment. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `daemonset.resources` | Allows you to set the resources for Metricbeat Deployment. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `daemonset.secretMounts` | Allows you to easily mount a secret as a file inside the DaemonSet. Useful for mounting certificates and other secrets. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `daemonset.sslVerificationMode` | Set the ssl verification mode for Metricbeat | `"none"` |
| `daemonset.tolerations` | Set [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) for all DaemonSet pods. Leave empty to remove tolerations and honor all node taints. | `{}` |
| `deployment.leanConfig` | When set to `true`, sets the Deployment's Metricbeat modules to the minimal configuration required to populate Logz.io's dashboards. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `deployment.extraVolumeMounts` | Templatable string of additional volumeMounts to be passed to the Deployment. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `deployment.extraVolumes` | Templatable string of additional `volumes` to be passed to the Deployment. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `deployment.metricbeatConfig.default` | Default configuration for Deployment's Metricbeat modules. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `deployment.metricbeatConfig.lean` | Lean configuration for Deployment's Metricbeat modules. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `deployment.metricbeatConfig.custom` | Allows you to add any config files in `/usr/share/metricbeat` such as `metricbeat.yml` for Metricbeat Deployment. <br> Please note that the custom config should be formatted and indented as in `deployment.metricbeat.config.default`. | `{}` |
| `deployment.securityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Metricbeat Deployment pod execution environment. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `deployment.resources` | Allows you to set the resources for Metricbeat Deployment. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `deployment.secretMounts` | Allows you to easily mount a secret as a file inside the Deployment Useful for mounting certificates and other secrets. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml). |
| `namespace` | Chart's namespace | `kube-system` |
| `secrets.MetricsToken`| Secret with your [logz.io Metrics token](https://docs.logz.io/user-guide/accounts/finding-your-metrics-account-token/). | `""` |
| `secrets.ListenerHost`| Secret with your [logz.io listener host](https://docs.logz.io/user-guide/accounts/account-region.html#available-regions). | `""` |
| `secrets.ClusterName`| Secret with your cluster name. | `""` |
| `secrets.KubeStatNamespace`| Secret with your Kube-Stat-Metrics namespace. | `""` |
| `secrets.KubeStatPort`| Secret with your Kube-Stat-Metrics port. | `""` |

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
helm uninstall --namespace=kube-system logzio-k8s-metrics
```


## Change log
  - **0.0.5**:
    - Mangage Logz.io metrics related secrets in helm
  - **0.0.4**:
    - Support lean configuration for modules in Deployment and Daemonset to match build-in dashboards in Logz.io.
    - Support custom configuration for modules in Deployment and Daemonset.
 - **0.0.3**:
    - Upgrade to Metricbeat version 7.9.1.
    - Support for Autodiscover through Metricbeat 7.6+.
 - **0.0.2**:
    - Supporting dynamic namespace.
 - **0.0.1**:
    - Initial release.
