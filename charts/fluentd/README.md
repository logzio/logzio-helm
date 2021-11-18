# Logzio-fluentd

[Helm](https://helm.sh/) is a tool for managing packages of pre-configured Kubernetes resources using Charts.
Logzio-fluentd allows you to ship logs from your Kubernetes cluster to Logz.io, using Fluentd.
Fluentd is flexible enough and has the proper plugins to distribute logs to different third parties such as Logz.io.

**Note:** The chart defaults to configuration for Conatinerd CRI. If your cluster uses Docker as CRI, please refer to `daemonset.containerdRuntime` in the [configuration table](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd#configuration).

### Deploying the Chart:

#### 1. Create a monitoring namespace

Your DaemonSet will be deployed under the namespace `monitoring`.

```shell
kubectl create namespace monitoring
```

#### 2. Add logzio-fluentd repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
```

#### 3. Deploy

The following command will install the Chart with the default values.
If you wish to change some of the values, add to this command `--set` flag(s) with the parameter(s) you'd like to change. For more information & example, see the [configuration table](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd#configuration).
You can learn more about the ways you can customise the Chart's values [here](https://helm.sh/docs/helm/helm_install/#synopsis).

Replace `<<LOG-SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-HOST>>` with your account's listener host. You can find your listener in your [manage tokens page](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping?product=logs).

```shell
helm install -n monitoring \
--set secrets.logzioShippingToken='<<LOG-SHIPPING-TOKEN>>' \
--set secrets.logzioListener='<<LISTENER-HOST>>' \
logzio-fluentd logzio-helm/logzio-fluentd
```

#### 4. Check Logz.io for your logs

Give your logs some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).


### Configuration

This table contains all the parameters in `values.yaml`. If you wish to change the default values, specify each parameter using the `--set key=value` argument to `helm install` in step 2. For example:

```shell
helm install -n monitoring \
  --set terminationGracePeriodSeconds=40 \
  --set daemonset.logzioLogLevel=debug \
  --set-file configmap.extraConfig=/path/to/config.yaml \
  logzio-fluentd logzio-helm/logzio-fluentd
```
| Parameter | Description | Default |
|---|---|---|
| `image` | The logzio-fluentd docker image. | `logzio/logzio-fluentd` |
| `imageTag` | The logzio-fluentd docker image tag. | `1.0.1` |
| `nameOverride` | Overrides the Chart name for resources. | `""` |
| `fullnameOverride` | Overrides the full name of the resources. | `""` |
| `apiVersions.daemonset` | Daemonset API version. | `apps/v1` |
| `apiVersions.serviceAccount` | Service Account API version. | `v1` |
| `apiVersions.clusterRole` | Cluster Role API version. | `rbac.authorization.k8s.io/v1` |
| `apiVersions.clusterRoleBinding` | Cluster Role Binding API version. | `rbac.authorization.k8s.io/v1` |
| `apiVersions.configmap` | Configmap API version. | `v1` |
| `apiVersions.secret` | Secret API version. | `v1` |
| `namespace` | Chart's namespace. | `monitoring` |
| `isRBAC` | Specifies whether the Chart should be compatible to a RBAC cluster. If you're running on a non-RBAC cluster, set to `false`.  | `true` |
| `serviceAccount.name` | Name of the service account. | `""` |
| `daemonset.tolerations` | Set [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) for all DaemonSet pods. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `daemonset.fluentdSystemdConf` | Controls whether Fluentd system messages will be enabled. | `disable` |
| `daemonset.fluentdPrometheusConf` | Controls the launch of a prometheus plugin that monitors Fluentd. | `disable` |
| `daemonset.includeNamespace` | Use if you wish to send logs from specific k8s namespaces, space delimited. Should be in the following format: `kubernetes.var.log.containers.**_<<NAMESPACE-TO-INCLUDE>>_** kubernetes.var.log.containers.**_<<ANOTHER-NAMESPACE>>_**`. | `""` |
| `daemonset.kubernetesVerifySsl` | Enables to validate SSL certificates. | `true` |
| `daemonset.auditLogFormat` | Match Fluentd's format for kube-apiserver audit logs. Set to `audit-json` if your audit logs are in json format. | `audit` |
| `daemonset.containerdRuntime` | Determines whether to use a configuration for a Containerd runtime. Set to `true` if your cluster uses Containerd as CRI. | `false` |
| `daemonset.logzioBufferType` | Specifies which plugin to use as the backend. | `file` |
| `daemonset.logzioBufferPath` | Path of the buffer. | `/var/log/fluentd-buffers/stackdriver.buffer` |
| `daemonset.logzioOverflowAction` | Controls the behavior when the queue becomes full. | `block` |
| `daemonset.logzioChunkLimitSize` | Maximum size of a chunk allowed. | `2M` |
| `daemonset.logzioQueueLimitLength` | Maximum length of the output queue. | `6` |
| `daemonset.logzioFlushInterval` | Interval, in seconds, to wait before invoking the next buffer flush. | `5s` |
| `daemonset.logzioRetryMaxInterval` | Maximum interval, in seconds, to wait between retries. | `30` |
| `daemonset.logzioRetryForever` | If true, plugin will retry flushing forever | `true` |
| `daemonset.logzioFlushThreadCount` | Number of threads to flush the buffer. | `2` |
| `daemonset.logzioLogLevel` | The log level for this container. | `info` |
| `daemonset.extraEnv` | If needed, more env vars can be added with this field. | `[]` |
| `daemonset.resources` | Allows you to set the resources for Fluentd Daemonset. |  See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `daemonset.extraVolumeMounts` | If needed, more volume mounts can be added with this field. | `[]` |
| `daemonset.terminationGracePeriodSeconds` | Termination period (in seconds) to wait before killing Fluentd pod process on pod shutdown. | `30` |
| `daemonset.extraVolumes` | If needed, more volumes can be added with this field. | `[]` |
| `daemonset.init.extraVolumeMounts` | If needed, more volume mounts to the init container can be added with this field. | `[]` |
| `clusterRole.rules` | Configurable [cluster role rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole) that Fluentd uses to access Kubernetes resources. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `secrets.logzioShippingToken` | Secret with your [logzio shipping token](https://app.logz.io/#/dashboard/settings/general). | `""` |
| `secrets.logzioListener` | Secret with your logzio listener host. `listener.logz.io`. | `" "` |
| `configmap.extraConfig` | If needed, more Fluentd configuration can be added with this field. | `{}` |
| `configmap.fluent` | Configuration for `fluent.conf`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.kubernetes` | Configuration for `kubernetes.conf`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.system` | Configuration for `system.conf`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.systemd` | Configuration for `systemd.conf`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.kubernetesContainerd` | Configuration for `kubernetes-containerd.conf`. This is the configuration that's being used when `daemonset.containerdRuntime` is set to `true` | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.audit` | Configuration for `audit.conf`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.auditJson` | Configuration for `audit-json.conf`. This is the configuration that's being used when `daemonset.auditLogFormat` is set to `audit-json` | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |

**Note:** If you're adding your own configuration file via `configmap.extraConfig`:
- Add a `--set-file` flag to your `helm install` command, as seen in the [example above](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd#configuration).
- Make sure that the `yaml` file with your configuration is in the following format:

```yaml
my-custom-conf-name.conf: |-
	# .....
	# your config
	# .....
my-custom-conf-name2.conf: |-
	# .....
	# your config
	# .....
```

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.  

To uninstall the `logzio-fluentd` deployment:

```shell
helm uninstall -n monitoring logzio-fluentd
```

## Change log

 - **0.0.3**:
    - Edit configmap template name
 - **0.0.2**:
    - Fix templates name - allow dyncmically change it.
 - **0.0.1**:
    - Initial release.
