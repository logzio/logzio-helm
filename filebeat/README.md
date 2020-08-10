# Logzio-k8s-logs

Helm is a tool for managing packages of pre-configured Kubernetes resources using Charts.
Logzio-k8s-logs allows you to ship logs from your Kubernetes cluster to Logz.io.
You can either deploy this daemonset with the standrad configuration, or with autodiscover configuration. For further information about Filebeat's autodiscover please see [Autodiscover documentation](https://www.elastic.co/guide/en/beats/filebeat/current/configuration-autodiscover.html).


### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed
* Allow outgoing traffic to destination port 5015

You have two options for deployment:
* [Standard configuration](#standard-config)
* [Autodiscover configuration](#autodiscover-config)

<div id="standard-config">

### Standard configuration deployment:


#### 1. Store your Logz.io credentials
Save your Logz.io shipping credentials as a Kubernetes secret.

Replace `<<SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-HOST>>` with your region’s listener host (for example, `listener.logz.io`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

Replace `<<CLUSTER-NAME>>` with your cluster's name.

```shell
kubectl create secret generic logzio-logs-secret \
  --from-literal=logzio-logs-shipping-token=<<SHIPPING-TOKEN>> \
  --from-literal=logzio-logs-listener=<<LISTENER-HOST>> \
  --from-literal=cluster-name=<<CLUSTER-NAME>> \
  -n kube-system
```

#### 2. Add logzio-k8s-logs repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm/filebeat
```

#### 3. Deploy

```shell
helm install --namespace=kube-system logzio-k8s-logs logzio-helm/logzio-k8s-logs
```

#### 4. Check Logz.io for your logs
Give your logs some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

</div>

<div id="autodiscover-config">

### Autodiscover configuration deployment:

Autodiscover allows you to adapt settings as changes happen. By defining configuration templates, the autodiscover subsystem can monitor services as they start running.

#### 1. Store your Logz.io credentials
Save your Logz.io shipping credentials as a Kubernetes secret.

Replace `<<SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-HOST>>` with your region’s listener host (for example, `listener.logz.io`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

Replace `<<CLUSTER-NAME>>` with your cluster's name.

```shell
kubectl create secret generic logzio-logs-secret \
  --from-literal=logzio-logs-shipping-token=<<SHIPPING-TOKEN>> \
  --from-literal=logzio-logs-listener=<<LISTENER-HOST>> \
  --from-literal=cluster-name=<<CLUSTER-NAME>> \
  -n kube-system
```

#### 2. Add logzio-k8s-logs repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm/filebeat
```

#### 3. Deploy
This daemonset's default autodiscover configuration is [hints based](https://www.elastic.co/guide/en/beats/filebeat/current/configuration-autodiscover-hints.html). If you wish to deploy it use:
```shell
helm install --namespace=kube-system --set=configType=autodiscover logzio-k8s-logs logzio-helm/logzio-k8s-logs
```
If you have a custom configuration, deploy with:
```shell
helm install --namespace=kube-system --set=configType=autodiscover --set-file filebeatConfig.autodiscoverConfig=<<CONFIG-PATH>> logzio-k8s-logs logzio-helm/logzio-k8s-logs
```
Replace `<<CONFIG-PATH>>` to your file's path.

#### 4. Check Logz.io for your logs
Give your logs some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

</div>

### Configuration

| Parameter | Description | Default |
|---|---|---|
| `image` | The Filebeat docker image. | `docker.elastic.co/beats/filebeat` |
| `imageTag` | The Filebeat docker image tag. | `7.8.1` |
| `nameOverride` | Overrides the Chart name for resources. | `""` |
| `fullnameOverride` | Overrides the full name of the resources. | `filebeat` |
| `apiVersions.configMap` | ConfigMap API version. | `v1` |
| `apiVersions.daemonset` | Daemonset API version. | `apps/v1` |
| `apiVersions.clusterRoleBinding` | ClusterRoleBinding API version. | `rbac.authorization.k8s.io/v1` |
| `apiVersions.clusterRole` | ClusterRole API version. | `rbac.authorization.k8s.io/v1` |
| `apiVersions.serviceAccount` | ServiceAccount API version. | `v1` |
| `namespace` | Chart's namespace. | `kube-system` |
| `managedServiceAccount` | Specifies whether the serviceAccount should be managed by this Helm Chart. Set this to `false` to manage your own service account and related roles. | `true` |
| `clusterRoleRules` | Configurable [cluster role rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole) that Filebeat uses to access Kubernetes resources. | See [values.yaml]() |
| `logzioCert` | Logzio public SSL certificate. | See [values.yaml]() |
| `configType` | Specifies which configuration to use for Filebeat. Set to `autodiscover` to use autodiscover. | `standard` |
| `filebeatConfig.standardConfig` | Standard Filebeat configuration, using `filebeat.input`. | See [values.yaml]() |
| `filebeatConfig.autodiscoverConfig` | Autodiscover Filebeat configuration, using `filebeat.autodiscover`. | See [values.yaml]() |
| `serviceAccount.create` | Specifies whether a service account should be created. | `true` |
| `serviceAccount.name` | Name of the service account. | `filebeat` |
| `terminationGracePeriod` | Termination period (in seconds) to wait before killing Filebeat pod process on pod shutdown. | `30` |
| `hostNetwork` | Controls whether the pod may use the node network namespace. | `true` |
| `dnsPolicy` | Specifies pod-specific DNS policies. | `ClusterFirstWithHostNet` |
| `daemonset.ignoreOlder` | Logs older than this will be ignored. | `3h` |
| `daemonset.logzioCodec` | Set to `json` if shipping JSON logs. Otherwise, set to `plain`. | `json` |
| `daemonset.logzioType` | The log type you'll use with this Daemonset. This is shown in your logs under the `type` field in Kibana.
Logz.io applies parsing based on type. | `filebeat` |
| `daemonset.fieldsUnderRoot` | If this option is set to true, the custom fields are stored as top-level fields in the output document instead of being grouped under a `fields` sub-dictionary. | `true` |
| `daemonset.securityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Filebeat DaemonSet pod execution environment. | See [values.yaml]() |
| `daemonset.resources` | Allows you to set the resources for Filebeat Daemonset. | See [values.yaml]() |
| `daemonset.volumes` | Templatable string of additional `volumes` to be passed to the DaemonSet. | See [values.yaml]() |
| `daemonset.volumeMounts` | Templatable string of additional `volumeMounts` to be passed to the DaemonSet. | See [values.yaml]() |



If you wish to change the default values, specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```shell
helm install --namespace=kube-system logzio-k8s-logs logzio-helm/logzio-k8s-logs \
  --set=imageTag=7.7.0,terminationGracePeriodSeconds=30
```

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.  
To uninstall the `logzio-k8s-logs` deployment:

```shell
helm uninstall --namespace=kube-system logzio-k8s-logs
```


## Change log
 - **0.0.1**:
    - Initial release.