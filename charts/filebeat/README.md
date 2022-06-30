# Logzio-k8s-logs

Helm is a tool for managing packages of pre-configured Kubernetes resources using Charts.
Logzio-k8s-logs allows you to ship logs from your Kubernetes cluster to Logz.io.
You can either deploy this Daemonset with the standrad configuration, or with autodiscover configuration. For further information about Filebeat's autodiscover please see [Autodiscover documentation](https://www.elastic.co/guide/en/beats/filebeat/current/configuration-autodiscover.html).


### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed
* Allow outgoing traffic to destination port 5015

You have two options for deployment:
* [Standard configuration](#standard-config)
* [Autodiscover configuration](#autodiscover-config) (Not supported with winlogbeat)

**Note:** Helm 2 will reach [EOL on November 2020](https://helm.sh/blog/2019-10-22-helm-2150-released/#:~:text=6%20months%20after%20Helm%203's,Helm%202%20will%20formally%20end). This document follows the command syntax recommended for Helm 3, but the Chart will work with both Helm 2 and Helm 3. 
<div id="standard-config">

### Standard configuration deployment:

#### 1. Add logzio-k8s-logs repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

#### 2. Deploy

Replace `<<SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-REGION>>` with your region’s code (for example, `eu`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

Replace `<<CLUSTER-NAME>>` with your cluster's name.

```shell
helm install --namespace=kube-system \
--set secrets.logzioShippingToken='<<SHIPPING-TOKEN>>' \
--set secrets.logzioRegion='<<LISTENER-REGION>>' \
--set secrets.clusterName='<<CLUSTER-NAME>>' \
logzio-k8s-logs logzio-helm/logzio-k8s-logs
```

#### 3. Check Logz.io for your logs
Give your logs some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

</div>

<div id="autodiscover-config">

### Autodiscover configuration deployment:

Autodiscover allows you to adapt settings as changes happen. By defining configuration templates, the autodiscover subsystem can monitor services as they start running.

#### 1. Add logzio-k8s-logs repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

#### 3. Deploy
In the following commands, make the following changes:
* Replace `<<SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

* Replace `<<LISTENER-REGION>>` with your region’s code (for example, `eu`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

* Replace `<<CLUSTER-NAME>>` with your cluster's name.

* Use `--set configType='<<TYPE>>'` for linux based filebeat and/or `--set filebeatWindowsConfigType='<<TYPE>>'` for windows based filebeat.

This Daemonset's default autodiscover configuration is [hints based](https://www.elastic.co/guide/en/beats/filebeat/current/configuration-autodiscover-hints.html). If you wish to deploy it use:
```shell
helm install --namespace=kube-system \
--set configType='autodiscover' \
--set secrets.logzioShippingToken='<<SHIPPING-TOKEN>>' \
--set secrets.logzioRegion='<<LISTENER-REGION>>' \
--set secrets.clusterName='<<CLUSTER-NAME>>' \
logzio-k8s-logs logzio-helm/logzio-k8s-logs
```
If you have a custom configuration, deploy with:
```shell
helm install --namespace=kube-system \
--set configType='auto-custom' \
--set secrets.logzioShippingToken='<<SHIPPING-TOKEN>>' \
--set secrets.logzioRegion='<<LISTENER-REGION>>' \
--set secrets.clusterName='<<CLUSTER-NAME>>' \
--set-file filebeatConfig.autoCustomConfig=/path/to/your/config.yaml \
logzio-k8s-logs logzio-helm/logzio-k8s-logs
```

*Note:* If you're using a custom config, please make sure that you're using a `.yaml` file in the following structure:
```
filebeat.yml: |-
  filebeat.autodiscover:
  #....
    # your autodiscover config
    # ...
  processors:
    - add_cloud_metadata: ~
  fields:
    logzio_codec: ${LOGZIO_CODEC}
    token: ${LOGZIO_LOGS_SHIPPING_TOKEN}
    cluster: ${CLUSTER_NAME}
    type: ${LOGZIO_TYPE}
  fields_under_root: ${FIELDS_UNDER_ROOT}
  ignore_older: ${IGNORE_OLDER}
  output:
    logstash:
      hosts: ["${LOGZIO_LOGS_LISTENER_HOST}:5015"]
      ssl:
        certificate_authorities: ['/etc/pki/tls/certs/SectigoRSADomainValidationSecureServerCA.crt']
        # for windows based filebeat: certificate_authorities: ['C:\cert.crt']
```

#### 4. Check Logz.io for your logs
Give your logs some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

</div>

### Configuration

| Parameter | Description | Default |
|---|---|---|
| `image` | The linux based Filebeat docker image. | `docker.elastic.co/beats/filebeat` |
| `imageTag` | The linux based Filebeat docker image tag. | `7.8.1` |
| `filebeatWindowsImage` | The windows based Filebeat docker image. | `docker.io/logzio/logzio-filebeat-win` |
| `filebeatWindowsImageTag` | The windows based Filebeat docker image tag. | `0.0.1` |
| `winglogbeatImage` | The winlogbeat docker image. | `docker.io/logzio/logzio-winlogbeat` |
| `winglogbeatImageTag` | The winlogbeat docker image tag. | `0.0.1` |
| `nameOverride` | Overrides the Chart name for resources. | `""` |
| `fullnameOverride` | Overrides the full name of the resources. | `filebeat` |
| `apiVersions.configMap` | ConfigMap API version. | `v1` |
| `apiVersions.daemonset` | Daemonset API version. | `apps/v1` |
| `apiVersions.clusterRoleBinding` | ClusterRoleBinding API version. | `rbac.authorization.k8s.io/v1` |
| `apiVersions.clusterRole` | ClusterRole API version. | `rbac.authorization.k8s.io/v1` |
| `apiVersions.serviceAccount` | ServiceAccount API version. | `v1` |
| `apiVersions.secret` | Secret API version. | `v1` |
| `managedServiceAccount` | Specifies whether the serviceAccount should be managed by this Helm Chart. Set this to `false` to manage your own service account and related roles. | `true` |
| `clusterRoleRules` | Configurable [cluster role rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole) that Filebeat uses to access Kubernetes resources. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `logzioCert` | Logzio public SSL certificate. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `configType` | Specifies which configuration to use for Filebeat. Set to `autodiscover` to use autodiscover (available only for filebeat). | `standard` |
| `filebeatConfig.standardConfig` | Standard linux based Filebeat configuration, using `filebeat.input`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `filebeatConfig.autodiscoverConfig` | Autodiscover linux based Filebeat configuration, using `filebeat.autodiscover`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `filebeatConfig.autoCustomConfig` | Autodiscover linux based Filebeat custom configuration, using `filebeat.autodiscover`. Should be used if you want to use your customized autodiscover config | {} |
| `filebeatWindowsConfig.standardConfig` | Standard windows based Filebeat configuration, using `filebeat.input`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `filebeatConfig.autodiscoverConfig` | Autodiscover windows based Filebeat configuration, using `filebeat.autodiscover`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `filebeatConfig.autoCustomConfig` | Autodiscover windows based Filebeat custom configuration, using `filebeat.autodiscover`. Should be used if you want to use your customized autodiscover config | {} |
| `winlogbeatConfig.standardConfig` | Standard Winlogbeat configuration, using `winlogbeat.event_logs`. (Currently this is the only available option)| See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `serviceAccount.create` | Specifies whether a service account should be created. | `true` |
| `serviceAccount.name` | Name of the service account. | `filebeat` |
| `terminationGracePeriod` | Termination period (in seconds) to wait before killing Filebeat pod process on pod shutdown. | `30` |
| `hostNetwork` | Controls whether the pod may use the node network namespace. | `true` |
| `windowsHostNetwork` | Controls whether the pod may use the Windows node network namespace. | `false` |
| `dnsPolicy` | Specifies pod-specific DNS policies. | `ClusterFirstWithHostNet` |
| `daemonset.ignoreOlder` | Logs older than this will be ignored. (linux based Filebeat)| `3h` |
| `daemonset.logzioCodec` | Set to `json` if shipping JSON logs. Otherwise, set to `plain`. (linux based Filebeat)| `json` |
| `daemonset.logzioType` | The log type you'll use with this Daemonset. This is shown in your logs under the `type` field in Kibana. Logz.io applies parsing based on type. (linux based Filebeat)| `filebeat` |
| `daemonset.fieldsUnderRoot` | If this option is set to true, the custom fields are stored as top-level fields in the output document instead of being grouped under a `fields` sub-dictionary. (linux based Filebeat)| `"true"` |
| `daemonset.securityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Filebeat DaemonSet pod execution environment. (linux based Filebeat)| See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `daemonset.resources` | Allows you to set the resources for Filebeat Daemonset. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) (linux based Filebeat)|
| `daemonset.tolerations` | Set [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) for all DaemonSet pods. (linux based Filebeat)| `{}` |
| `daemonset.volumes` | Templatable string of additional `volumes` to be passed to the DaemonSet. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) (linux based Filebeat)|
| `daemonset.volumeMounts` | Templatable string of additional `volumeMounts` to be passed to the DaemonSet. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) (linux based Filebeat)|
| `winlogbeatDaemonset.ignoreOlder` | Logs older than this will be ignored. (Winlogbeat)| `3h` |
| `winlogbeatDaemonset.logzioCodec` | Set to `json` if shipping JSON logs. Otherwise, set to `plain`. (Winlogbeat)| `json` |
| `winlogbeatDaemonset.logzioType` | The log type you'll use with this Daemonset. This is shown in your logs under the `type` field in Kibana. Logz.io applies parsing based on type. (Winlogbeat)| `winlogbeat` |
| `winlogbeatDaemonset.fieldsUnderRoot` | If this option is set to true, the custom fields are stored as top-level fields in the output document instead of being grouped under a `fields` sub-dictionary. (Winlogbeat)| `"true"` |
| `winlogbeatDaemonset.securityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Filebeat DaemonSet pod execution environment. (Winlogbeat)| See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `winlogbeatDaemonset.resources` | Allows you to set the resources for Filebeat Daemonset. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) (Winlogbeat)|
| `winlogbeatDaemonset.tolerations` | Set [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) for all DaemonSet pods. (Winlogbeat)| `{}` |
| `winlogbeatDaemonset.volumes` | Templatable string of additional `volumes` to be passed to the DaemonSet. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) (Winlogbeat)|
| `winlogbeatDaemonset.volumeMounts` | Templatable string of additional `volumeMounts` to be passed to the DaemonSet. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) (Winlogbeat)|
| `filebeatWindowsDaemonset.ignoreOlder` | Logs older than this will be ignored. (Windows based Filebeat)| `3h` |
| `filebeatWindowsDaemonset.logzioCodec` | Set to `json` if shipping JSON logs. Otherwise, set to `plain`. (Windows based Filebeat)| `json` |
| `filebeatWindowsDaemonset.logzioType` | The log type you'll use with this Daemonset. This is shown in your logs under the `type` field in Kibana. Logz.io applies parsing based on type. (Windows based Filebeat)| `filebeat-win` |
| `filebeatWindowsDaemonset.fieldsUnderRoot` | If this option is set to true, the custom fields are stored as top-level fields in the output document instead of being grouped under a `fields` sub-dictionary. (Windows based Filebeat)| `"true"` |
| `filebeatWindowsDaemonset.securityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Filebeat DaemonSet pod execution environment. (Windows based Filebeat)| See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `filebeatWindowsDaemonset.resources` | Allows you to set the resources for Filebeat Daemonset. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) (Windows based Filebeat)|
| `filebeatWindowsDaemonset.tolerations` | Set [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) for all DaemonSet pods. (Windows based Filebeat)| `{}` |
| `filebeatWindowsDaemonset.volumes` | Templatable string of additional `volumes` to be passed to the DaemonSet. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) (Windows based Filebeat)|
| `filebeatWindowsDaemonset.volumeMounts` | Templatable string of additional `volumeMounts` to be passed to the DaemonSet. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) (Windows based Filebeat)|
| `secrets.create` | Boolean to toggle secrets creation. Set to false to disable secrets generation.| `true` |
| `secrets.logzioShippingToken`| Secret with your [logzio shipping token](https://app.logz.io/#/dashboard/settings/general). | `""` |
| `secrets.logzioRegion`| Secret with your [logzio region](https://docs.logz.io/user-guide/accounts/account-region.html). Defaults to US East. | `" "` |
| `secrets.clusterName`| Secret with your cluster name. | `""` |


If you wish to change the default values, specify each parameter using the `--set key=value` argument to `helm install`. For example,

```shell
helm install --namespace=kube-system logzio-k8s-logs logzio-helm/logzio-k8s-logs \
  --set imageTag=7.7.0 \
  --set terminationGracePeriodSeconds=30
```

Some values, like `daemonset.tolerations`, should be set like this:
```shell
--set daemonset.tolerations[0].key='value' \
--set daemonset.tolerations[0].operator='Equal' \
```

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.
To uninstall the `logzio-k8s-logs` deployment:

```shell
helm uninstall --namespace=kube-system logzio-k8s-logs
```

## Sending logs from nodes with taints

If you want to ship logs from any of the nodes that have a taint, make sure that the taint key values are listed in your in your daemonset configuration as follows:

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
 - **0.0.5**:
    - Allow ability to toggle secrets creation, with new parameter `secrets.create`.
 - **0.0.4**:
    - Added support for log shipping from Windows Nodes, and event log shipping with winlogbeat.
 - **0.0.3**:
    - Added CI workflow for automated testing
 - **0.0.2**:
    - Added option to set tolerations for daemonset (Thanks [jlewis42lines](https://github.com/jlewis42lines)!).
 - **0.0.1**:
    - Initial release.
