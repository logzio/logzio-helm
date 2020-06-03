# Logzio-k8s-metrics

Helm is a tool for managing Charts. Charts are packages of pre-configured Kubernetes resources.  
Logzio-k8s-metrics allows you to ship metrics from your Kubernetes cluster.

### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed
* [kube-state-metrics](https://github.com/kubernetes/kube-state-metrics) installed
* Allow outgoing traffic to destination port 5015

You have two options for deployment:
* [Default configuration <span class="sm ital">(recommended)</span>](#default-config)
* [Custom configuration](#custom-config)

<div id="default-config">

### Automatic deployment:

#### 1. Run the automated deployment script
```shell
bash <(curl -s https://raw.githubusercontent.com/logzio/logzio-helm/master/quickstart-metrics.sh)
```

##### Prompts and answers

| Prompt | Answer |
|---|---|
| Logz.io metrics shipping token (Required) | The [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to. |
| Logz.io region (Default: `Blank (US East)`) | Two-letter region code, or blank for US East (Northern Virginia). This determines your listener URL (where you’re shipping the logs to) and API URL. You can find your region code in the [Regions and URLs](https://docs.logz.io/user-guide/accounts/account-region.html#regions-and-urls) table. |
| Cluster name (Default: `detected by the script` | The name of the Kubernetes cluster you’re deploying in. |

#### 2. Check Logz.io for your metrics
Give your metrics some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

</div>

<div id="custom-config">

### Manually deployment:

#### 1. Store your Logz.io credentials
Save your Logz.io shipping credentials as a Kubernetes secret.

Replace `<<SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-HOST>>` with your region’s listener host (for example, `listener.logz.io`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

```shell
kubectl --namespace=kube-system create secret generic logzio-metrics-secret \
  --from-literal=logzio-metrics-shipping-token=<<SHIPPING-TOKEN>> \
  --from-literal=logzio-metrics-listener-host=<<LISTENER-HOST>>
```

#### 2. Store your cluster details

Replace `<<KUBE-STATE-METRICS-NAMESPACE>>`, `<<KUBE-STATE-METRICS-PORT>>`, and `<<CLUSTER-NAME>>` in this command to save your cluster details as a Kubernetes secret.

```shell
kubectl --namespace=kube-system create secret generic cluster-details \
--from-literal=kube-state-metrics-namespace=<<KUBE-STATE-METRICS-NAMESPACE>> \
--from-literal=kube-state-metrics-port=<<KUBE-STATE-METRICS-PORT>> \
--from-literal=cluster-name=<<CLUSTER-NAME>>
```

#### 3. Add logzio-k8s-metrics repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm/metricbeat
```

#### 4. Deploy

```shell
helm install --namespace=kube-system logzio-k8s-metrics logzio-helm/logzio-k8s-metrics
```

#### 5. Check Logz.io for your metrics

Give your metrics some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

</div>

### Configuration

| Parameter | Description | Default |
|---|---|---|
| `image` | The Metricbeat Docker image. | `"docker.elastic.co/beats/metricbeat"` |
| `imageTag` | The Metricbeat Docker image tag. | `"7.3.2"` |
| `nameOverride` | Overrides the chart name for resources. | `""` |
| `fullnameOverride` | Overrides the full name of the resources. | `"metricbeat"` |
| `apiVersions.ConfigMap` | Api version of `configmap.yaml`. | `v1` |
| `apiVersions.Deployment` | Api version of `deployment.yaml.` | `apps/v1` |
| `apiVersions.DaemonSet` | Api version of `daemonset.yaml`. | `apps/v1` |
| `apiVersions.ServiceAccount` | Api version of `serviceaccount.yaml`. | `v1` |
| `apiVersions.ClusterRole` | Api version of `clusterrole.yaml`. | `rbac.authorization.k8s.io/v1beta1` |
| `apiVersions.ClusterRoleBinding` | Api version of `clusterrolebinding.yaml`. | `rbac.authorization.k8s.io/v1beta1` |
| `shippingProtocol` | Shipping protocol. | `http` |
| `shippingPort` | Shipping port. | `10255` |
| `serviceAccount.create` | Specifies whether a service account should be created. | `true` |
| `serviceAccount.name` | Name of the service account. | `metricbeat` |
| `podSecurityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Metricbeat DaemonSet and Deployment pod execution environment. | `{}` |
| `resources` | Allows you to set the resources for both Metricbeat DaemonSet and Deployment. | `{}` |
| `clusterRoleRules` | Configurable [cluster role rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole) that Metricbeat uses to access Kubernetes resources. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `managedServiceAccount` | Whether the serviceAccount should be managed by this helm chart. Set this to false in order to manage your own service account and related roles. | `true` |
| `secretMounts` | Allows you easily mount a secret as a file inside DaemonSet and Deployment Useful for mounting certificates and other secrets. | `see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml)` |
| `terminationGracePeriod` | Termination period (in seconds) to wait before killing Metricbeat pod process on pod shutdown. | `30` |
| `hostPathRoot` | Fully-qualified [hostPath](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath) that will be used to persist Metricbeat registry data. | `/var/lib` |
| `logzioCert` | Logzio public SSL certificate. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `metricbeatConfig` | Metricbeat configuration. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `daemonset.extraVolumeMounts` | Templatable string of additional `volumeMounts` to be passed to the DaemonSet. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `daemonset.extraVolumes` | Templatable string of additional `volumes` to be passed to the DaemonSet. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `daemonset.metricbeatConfig` | Allows you to add any config files in `/usr/share/metricbeat` such as `metricbeat.yml` for Metricbeat Daemonset. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `daemonset.securityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Metricbeat DaemonSet pod execution environment. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `daemonset.resources` | Allows you to set the resources for Metricbeat Deployment. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `daemonset.secretMounts` | Allows you easily mount a secret as a file inside the DaemonSet. Useful for mounting certificates and other secrets. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `deployment.extraVolumeMounts` | Templatable string of additional volumeMounts to be passed to the Deployment. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `deployment.extraVolumes` | Templatable string of additional `volumes` to be passed to the Deployment. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `deployment.metricbeatConfig` | Allows you to add any config files in `/usr/share/metricbeat` such as `metricbeat.yml` for Metricbeat Deployment. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `deployment.securityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Metricbeat Deployment pod execution environment. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `deployment.resources` | Allows you to set the resources for Metricbeat Deployment. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |
| `deployment.secretMounts` | Allows you easily mount a secret as a file inside the Deployment Useful for mounting certificates and other secrets. | see [values.yaml](https://github.com/logzio/logzio-helm/blob/master/metricbeat/values.yaml) |

If you wish to change the default values, specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```shell
helm install --namespace=kube-system logzio-k8s-metrics logzio-helm/logzio-k8s-metrics \
  --set=imageTag=7.7.0,terminationGracePeriodSeconds=30
```

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.  
To uninstall the `logzio-k8s-metrics` deployment:

```shell
helm uninstall --namespace=kube-system logzio-k8s-metrics
```