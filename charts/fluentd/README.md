
# Logzio-fluentd

[Helm](https://helm.sh/) is a package management tool that uses Charts to deploy pre-configured sets of Kubernetes resources. The Logzio-fluentd chart enables you to transmit logs from your Kubernetes cluster to Logz.io via Fluentd. Fluentd's flexibility and availability of plugins allow for easy distribution of logs to various third-party services, including Logz.io.

The chart defaults to configuration for Conatinerd CRI. If your cluster uses Docker as CRI, please refer to `daemonset.containerdRuntime` in the [configuration table](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd#configuration).

**Note**: This chart is for shipping logs only. 
For a chart that ships all telemetry data, including logs, metrics, traces, and SPM, use our [Logzio Monitoring chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring).

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

The following command installs the Chart using the default values. If you want to modify any settings, append the `--set` flag(s) to this command along with the parameters you wish to change. For more information and examples, refer to the [configuration table](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd#configuration).
You can find additional details on how to customize the Chart's values [here](https://helm.sh/docs/helm/helm_install/#synopsis).

Replace `<<LOG-SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LOGZIO-REGION>>` with your account's [region code](https://docs.logz.io/docs/user-guide/admin/hosting-regions/account-region/#available-regions).

```shell
helm install -n monitoring \
--set global.logzioLogsToken='<<LOG-SHIPPING-TOKEN>>' \
--set global.logzioRegion='<<LOGZIO-REGION>>' \
logzio-fluentd logzio-helm/logzio-fluentd
```

If adding the secret directly through the Helm chart is not possible or secure (for example, due to the absence of secure value-file storage), you can override the secret's name by modifying `secret.name` in the values file. This adjustment allows you to place an external secret containing the keys `logzio-log-shipping-token` and `logzio-log-listener` through alternative methods.

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
| Parameter                                 | Description                                                                                                                                                                                                                              | Default                                                                                          |
|-------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| `image`                                   | The logzio-fluentd docker image.                                                                                                                                                                                                         | `logzio/logzio-fluentd`                                                                          |
| `imageTag`                                | The logzio-fluentd docker image tag.                                                                                                                                                                                                     | `1.4.0`                                                                                          |
| `nameOverride`                            | Overrides the Chart name for resources.                                                                                                                                                                                                  | `""`                                                                                             |
| `fullnameOverride`                        | Overrides the full name of the resources.                                                                                                                                                                                                | `""`                                                                                             |
| `apiVersions.daemonset`                   | Daemonset API version.                                                                                                                                                                                                                   | `apps/v1`                                                                                        |
| `apiVersions.serviceAccount`              | Service Account API version.                                                                                                                                                                                                             | `v1`                                                                                             |
| `apiVersions.clusterRole`                 | Cluster Role API version.                                                                                                                                                                                                                | `rbac.authorization.k8s.io/v1`                                                                   |
| `apiVersions.clusterRoleBinding`          | Cluster Role Binding API version.                                                                                                                                                                                                        | `rbac.authorization.k8s.io/v1`                                                                   |
| `apiVersions.configmap`                   | Configmap API version.                                                                                                                                                                                                                   | `v1`                                                                                             |
| `apiVersions.secret`                      | Secret API version.                                                                                                                                                                                                                      | `v1`                                                                                             |
| `namespace`                               | Chart's namespace.                                                                                                                                                                                                                       | `monitoring`                                                                                     |
| `fargateLogRouter.enabled`                | Boolen to decide if to configure fargate log router                                                                                                                                                                                      | `false`                                                                                          |
| `global.env_id`                                  | Add to your logs field `env_id` with identification of the environment you're shipping logs from.                                                                                                                                        | `""`                                                                                             |
| `isRBAC`                                  | Specifies whether the Chart should be compatible to a RBAC cluster. If you're running on a non-RBAC cluster, set to `false`.                                                                                                             | `true`                                                                                           |
| `isPrivileged`                            | Specifies whether to run the Damonset with priviliged security context                                                                                                                                                                   | `false`                                                                                          |
| `serviceAccount.name`                     | Name of the service account.                                                                                                                                                                                                             | `""`                                                                                             |
| `daemonset.podSecurityContext`            | Security context for the pod level                                                                                                                                                                                                       | `{}`                                                                                             |
| `daemonset.securityContext`               | Security context for the container level                                                                                                                                                                                                 | `{}`                                                                                             |
| `daemonset.initContainerSecurityContext`  | Security context for the init container                                                                                                                                                                                                  | `{}`                                                                                             |
| `daemonset.tolerations`                   | Set [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) for all DaemonSet pods.                                                                                                                 | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `daemonset.nodeSelector`                  | Set [nodeSelector](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) for all DaemonSet pods.                                                                                                                | `{"kubernetes.io/os": "linux"}`                                                                  |
| `daemonset.affinity`                      | Set [affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) rules for the scheduler to determine where all DaemonSet pods can be placed.                                         |                                                                                                  |
| `daemonset.fluentdSystemdConf`            | Controls whether Fluentd system messages will be enabled.                                                                                                                                                                                | `disable`                                                                                        |
| `daemonset.fluentdPrometheusConf`         | Controls the launch of a prometheus plugin that monitors Fluentd.                                                                                                                                                                        | `false`                                                                                          |
| `daemonset.includeNamespace`              | Use if you wish to send logs from specific k8s namespaces, space delimited. Should be in the following format: `kubernetes.var.log.containers.**_<<NAMESPACE-TO-INCLUDE>>_** kubernetes.var.log.containers.**_<<ANOTHER-NAMESPACE>>_**`. | `""`                                                                                             |
| `daemonset.kubernetesVerifySsl`           | Enables to validate SSL certificates.                                                                                                                                                                                                    | `true`                                                                                           |
| `daemonset.auditLogFormat`                | Match Fluentd's format for kube-apiserver audit logs. Set to `audit-json` if your audit logs are in json format.                                                                                                                         | `audit`                                                                                          |
| `daemonset.containerdRuntime`             | **Deprecated from chart version 0.1.0.** Determines whether to use a configuration for a Containerd runtime. Set to `false` if your cluster doesn't use Containerd as CRI.                                                               | `true`                                                                                           |
| `daemonset.cri`                           | Container runtime interface of the cluster. Used to determine which configuration to use when concatenating partial logs. Valid options are: `docker`, `containerd`.                                                                     | `containerd`                                                                                     |
| `daemonset.LogFileRefreshInterval`        | The interval of refreshing the list of watch file for log files..                                                                                                                                                                        | `60s`                                                                                            |
| `daemonset.logzioBufferType`              | Specifies which plugin to use as the backend.                                                                                                                                                                                            | `file`                                                                                           |
| `daemonset.logzioBufferPath`              | Path of the buffer.                                                                                                                                                                                                                      | `/var/log/fluentd-buffers/stackdriver.buffer`                                                    |
| `daemonset.logzioOverflowAction`          | Controls the behavior when the queue becomes full.                                                                                                                                                                                       | `block`                                                                                          |
| `daemonset.logzioChunkLimitSize`          | Maximum size of a chunk allowed.                                                                                                                                                                                                         | `2M`                                                                                             |
| `daemonset.logzioQueueLimitLength`        | Maximum length of the output queue.                                                                                                                                                                                                      | `6`                                                                                              |
| `daemonset.logzioFlushInterval`           | Interval, in seconds, to wait before invoking the next buffer flush.                                                                                                                                                                     | `5s`                                                                                             |
| `daemonset.logzioRetryMaxInterval`        | Maximum interval, in seconds, to wait between retries.                                                                                                                                                                                   | `30`                                                                                             |
| `daemonset.logzioRetryForever`            | If true, plugin will retry flushing forever                                                                                                                                                                                              | `true`                                                                                           |
| `daemonset.logzioFlushThreadCount`        | Number of threads to flush the buffer.                                                                                                                                                                                                   | `2`                                                                                              |
| `daemonset.logzioLogLevel`                | The log level for this container.                                                                                                                                                                                                        | `info`                                                                                           |
| `daemonset.excludeFluentdPath`            | Path to fluentd logs file, to exclude them from the logs that Fluent tails.                                                                                                                                                              | `/var/log/containers/*fluentd*.log`                                                              |
| `daemonset.extraExclude`                  | A comma-seperated list (no spaces), of more paths to exclude from the Fluentd source that tails containers logs. For example - /path/one.log,/path/two.log                                                                               | `""`                                                                                             |
| `daemonset.containersPath`                | Path for containers logs.                                                                                                                                                                                                                | `"/var/log/containers/*.log"`                                                                    |
| `daemonset.posFile`                       | Path for containers logs pos file.                                                                                                                                                                                                       | `"/var/log/fluentd-containers.log.pos"`                                                          |
| `daemonset.logType`                       | Set log type for the logs.                                                                                                                                                                                                               | `"k8s"`                                                                                          |
| `daemonset.extraEnv`                      | If needed, more env vars can be added with this field.                                                                                                                                                                                   | `[]`                                                                                             |
| `daemonset.resources`                     | Allows you to set the resources for Fluentd Daemonset.                                                                                                                                                                                   | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `daemonset.extraVolumeMounts`             | If needed, more volume mounts can be added with this field.                                                                                                                                                                              | `[]`                                                                                             |
| `daemonset.terminationGracePeriodSeconds` | Termination period (in seconds) to wait before killing Fluentd pod process on pod shutdown.                                                                                                                                              | `30`                                                                                             |
| `daemonset.extraVolumes`                  | If needed, more volumes can be added with this field.                                                                                                                                                                                    | `[]`                                                                                             |
| `daemonset.init.extraVolumeMounts`        | If needed, more volume mounts to the init container can be added with this field.                                                                                                                                                        | `[]`                                                                                             |
| `daemonset.init.containerImage`           | Init container image for the fluentd daemonset.                                                                                                                                                                                          | `busybox`                                                                                        |
| `daemonset.priorityClassName`             | Set [priorityClassName](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) for all DaemonSet pods.                                                                                                        | `""`                                                                                             |
| `daemonset.updateStrategy`                | Strategy to use when updating the Daemonset.                                                                                                                                                                                             | `{}`                                                                                             |
| `windowsDaemonset.enabled`                | Enables Fluentd Daemonset for Windows.                                                                                                                                                                                                   | `true`                                                                                           |
| `windowsDaemonset.kubernetesVerifySsl`    | Enables to validate SSL certificates (windows).                                                                                                                                                                                          | `true`                                                                                           |
| `windowsDaemonset.auditLogFormat`         | Match Fluentd's format for kube-apiserver audit logs. Set to `audit-json` if your audit logs are in json format. (windows)                                                                                                               | `audit`                                                                                          |
| `windowsDaemonset.containerdRuntime`      | **Deprecated from chart version 0.1.0.** Determines whether to use a configuration for a Containerd runtime. Set to `false` if your cluster doesn't use Containerd as CRI. (windows)                                                     | `true`                                                                                           |
| `windowsDaemonset.cri`                    | Container runtime interface of the cluster. Used to determine which configuration to use when concatenating partial logs (windows). Valid options are: `docker`, `containerd`.                                                           | `containerd`                                                                                     |
| `windowsDaemonset.LogFileRefreshInterval` | The interval of refreshing the list of watch file for log files..                                                                                                                                                                        | `60s`                                                                                            |
| `windowsDaemonset.logzioBufferType`       | Specifies which plugin to use as the backend.                                                                                                                                                                                            | `file`                                                                                           |
| `windowsDaemonset.logzioBufferPath`       | Path of the buffer. (windows)                                                                                                                                                                                                            | `/var/log/fluentd-buffers/stackdriver.buffer`                                                    |
| `windowsDaemonset.logzioOverflowAction`   | Controls the behavior when the queue becomes full. (windows)                                                                                                                                                                             | `block`                                                                                          |
| `windowsDaemonset.logzioChunkLimitSize`   | Maximum size of a chunk allowed. (windows)                                                                                                                                                                                               | `2M`                                                                                             |
| `windowsDaemonset.logzioQueueLimitLength` | Maximum length of the output queue. (windows)                                                                                                                                                                                            | `6`                                                                                              |
| `windowsDaemonset.logzioFlushInterval`    | Interval, in seconds, to wait before invoking the next buffer flush. (windows)                                                                                                                                                           | `5s`                                                                                             |
| `windowsDaemonset.logzioRetryMaxInterval` | Maximum interval, in seconds, to wait between retries. (windows)                                                                                                                                                                         | `30`                                                                                             |
| `windowsDaemonset.logzioRetryForever`     | If true, plugin will retry flushing forever (windows)                                                                                                                                                                                    | `true`                                                                                           |
| `windowsDaemonset.logzioFlushThreadCount` | Number of threads to flush the buffer. (windows)                                                                                                                                                                                         | `2`                                                                                              |
| `windowsDaemonset.logzioLogLevel`         | The log level for this container. (windows)                                                                                                                                                                                              | `info`                                                                                           |
| `windowsDaemonset.excludeFluentdPath`     | Path to fluentd logs file, to exclude them from the logs that Fluent tails.                                                                                                                                                              | `/var/log/containers/*fluentd*.log`                                                              |
| `windowsDaemonset.extraExclude`           | A comma-seperated list (no spaces), of more paths to exclude from the Fluentd source that tails containers logs. For example - /path/one.log,/path/two.log                                                                               | `""`                                                                                             |
| `windowsDaemonset.containersPath`         | Path for containers logs.                                                                                                                                                                                                                | `"/var/log/containers/*.log"`                                                                    |
| `windowsDaemonset.extraEnv`               | If needed, more env vars can be added with this field. (windows)                                                                                                                                                                         | `[]`                                                                                             |
| `windowsDaemonset.resources`              | Allows you to set the resources for Fluentd Daemonset. (windows)                                                                                                                                                                         | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `windowsDaemonset.extraVolumeMounts`      | If needed, more volume mounts can be added with this field. (windows)                                                                                                                                                                    | `[]`                                                                                             |
| `daemonset.terminationGracePeriodSeconds` | Termination period (in seconds) to wait before killing Fluentd pod process on pod shutdown.                                                                                                                                              | `30`                                                                                             |
| `windowsDaemonset.extraVolumes`           | If needed, more volumes can be added with this field. (windows)                                                                                                                                                                          | `[]`                                                                                             |
| `windowsDaemonset.priorityClassName`      | Set [priorityClassName](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) for all DaemonSet pods. (windows)                                                                                              | `""`                                                                                             |
| `windowsDaemonset.updateStrategy`         | Strategy to use when updating the Daemonset.                                                                                                                                                                                             | `{}`                                                                                             |
| `windowsDaemonset.nodeSelector`           | Set [nodeSelector](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) for all DaemonSet pods.                                                                                                                | `{"kubernetes.io/os": "windows"}`                                                                |                                                               |
| `clusterRole.rules`                       | Configurable [cluster role rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole) that Fluentd uses to access Kubernetes resources.                                                                  | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `global.logzioLogsToken`             | Secret with your [logzio shipping token](https://app.logz.io/#/dashboard/settings/general).                                                                                                                                              | `""`                                                                                             |
| `global.logzioRegion`                  | Secret with your logzio region code.                                                                                                                                                                               | `"us"`                                                                                            |
| `global.customLogsEndpoint`                  | Secret with your custom endpoint, for example:`http://endpoint:8080`. Overrides `global.logzioRegion`                                                                                                                                 | `""`                                                                                             |
| `secret.enabled`                         | When `true`, the logzio secret will be created and managed by this Chart. If you're managing the logzio secret by yourself, set to `false`.                                                                                              | `true`                                                                                           |
| `secret.name`                              | Name of the secret in case it's placed from an external source.                                                                                                                                                                          | `logzio-logs-secret`                                                                             |
| `configMapIncludes`                       | Initial includes for `fluent.conf`.                                                                                                                                                                                                      | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.extraConfig`                   | If needed, more Fluentd configuration can be added with this field.                                                                                                                                                                      | `{}`                                                                                             |
| `configmap.fluent`                        | Configuration for `fluent.conf`.                                                                                                                                                                                                         | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.kubernetes`                    | Configuration for `kubernetes.conf`.                                                                                                                                                                                                     | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.system`                        | Configuration for `system.conf`.                                                                                                                                                                                                         | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.systemd`                       | Configuration for `systemd.conf`.                                                                                                                                                                                                        | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.kubernetesContainerd`          | **Deprecated from chart version 0.1.0.** Configuration for `kubernetes-containerd.conf`. This is the configuration that's being used when `daemonset.containerdRuntime` is set to `true`                                                 | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.partialDocker`                 | Configuration for `partial-docker.conf`. Used to concatenate partial logs that split due to large size, for docker cri.                                                                                                                  | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.partialContainerd`             | Configuration for `partial-containerd.conf`. Used to concatenate partial logs that split due to large size, for containerd cri.                                                                                                          | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.audit`                         | Configuration for `audit.conf`.                                                                                                                                                                                                          | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.auditJson`                     | Configuration for `audit-json.conf`. This is the configuration that's being used when `daemonset.auditLogFormat` is set to `audit-json`                                                                                                  | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.envId`                         | Config snippet for adding `env_id` field to logs                                                                                                                                                                                         | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/fluentd/values.yaml). |
| `configmap.customSources`                 | Add sources to the Fluentd configuration                                                                                                                                                                                                 | `""`                                                                                             |
| `configmap.customFilters`                 | Add filters to the Fluentd configuration                                                                                                                                                                                                 | `""`                                                                                             |
| `configmap.customFilterAfter`             | Add filters to the Fluentd configuration, after default filters                                                                                                                                                                          | `""`                                                                                             |
| `logLevelFilter`                          | Add log level filter. Regex of the log level(s) you want to ship. For example, if you want to ship warning and error logs, use `WARNING\|ERROR`. Possible levels are: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `TRACE`.                      | `""`                                                                                             |

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

### Handling image pull rate limit
In some cases (i.e spot clusters) where the pods/nodes are replaced frequently, the pull rate limit for images pulled from dockerhub might be reached, with an error:
`You have reached your pull rate limit. You may increase the limit by authenticating and upgrading: https://www.docker.com/increase-rate-limits`.
In these cases we can use the following `--set` command to use an alternative image repository:

```shell
--set image=public.ecr.aws/logzio/logzio-fluentd
```

```shell
--set daemonset.init.containerImage=public.ecr.aws/docker/library/busybox
```


### Adding a custom log_type field from attribute
To add a `log_type` field with a custom value to each log, you can use the annotation key `log_type` with a custom value. The annotation will be automatically parsed into a `log_type` field with the provided value.
e.g:
```
...
  metadata:
    annotations:
      log_type: "my_type"
```
Will result with the following log (json):
```
{
...
,"log_type": "my_type"
...
}
```

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.  

To uninstall the `logzio-fluentd` deployment:

```shell
helm uninstall -n monitoring logzio-fluentd
```

### Configuring Fluentd to concatenate multiline logs using a plugin

Fluentd splits multiline logs by default. If your original logs span multiple lines, you may find that they arrive in your Logz.io account split into several partial logs.

The Logz.io Docker image comes with a pre-built Fluentd filter plug-in that can be used to concatenate multiline logs. The plug-in is named `fluent-plugin-concat` and you can view the full list of configuration options in the [GitHub project](https://github.com/fluent-plugins-nursery/fluent-plugin-concat).

#### Example

The following is an example of a multiline log sent from a deployment on a k8s cluster:

```shell
2021-02-08 09:37:51,031 - errorLogger - ERROR - Traceback (most recent call last):
File "./code.py", line 25, in my_func
1/0
ZeroDivisionError: division by zero
```

Fluentd's default configuration will split the above log into 4 logs, 1 for each line of the original log. In other words, each line break (`\n`) causes a split.

To avoid this, you can use the `fluent-plugin-concat` and customize the configuration to meet your needs. The additional configuration is added to:

* `kubernetes.conf` for RBAC/non-RBAC DaemonSet
* `kubernetes-containerd.conf` for Containerd DaemonSet

For the above example, we could use the following regex expressions to demarcate the start and end of our example log:


```shell
<filter **>
  @type concat
  key message # The key for part of multiline log
  multiline_start_regexp /^[0-9]{4}-[0-9]{2}-[0-9]{2}/ # This regex expression identifies line starts.
</filter>
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

## Sending logs from eks on fargate

If you want to ship logs from pods that are running on fargate set the `fargateLogRouter.enabled` value to true, the follwing will deploy a dedicated `aws-observability` namespace and a `configmap` for fargate log router. More information about eks fargate logging can be found [here](https://docs.aws.amazon.com/eks/latest/userguide/fargate-logging.html)
```
helm install \
--set fargateLogRouter.enabled=true \
--set global.logzioLogsToken='<<LOG-SHIPPING-TOKEN>>' \
--set global.logzioRegion='<<LOGZIO-REGION>>' \
logzio-fluentd logzio-helm/logzio-fluentd
```

## Monitoring fluentd with prometheus
In order to monitor fluentd and collect input & output metrics. You can 
enable prometheus configuration with the `daemonset.fluentdPrometheusConf` and `windowsDaemonset.fluentdPrometheusConf` parameter (default to false).
When enabling promehteus configuration, the pod collects and exposes fluentd metrics on port `24231`, `/metrics` endpoint. The templates contains annotations to easly ship when using promehteus shipper or `logzio-telemetry` chart. Monitoring Windows fluentd is not supported.


## Fluentd images for windows server
By default the fluentd image for windows-server supports windows server 2019.
If needed, the fluentd image can be changed to support windows server 2022 with the following commands:

```yaml
--set windowsImage=logzio/fluentd-windows-2022 \
--set windowsImageTag=0.0.5
```
