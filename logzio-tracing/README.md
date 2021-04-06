# Logzio-tracing

Logzio-tracing allows you to ship traces from your Kubernetes cluster to Logz.io.
The chart will deploy tracing agents and/or collector (depends on the brand)

### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed

You can choose your tracing agent and collector brand between:
* OpenTelemetry (otel)
* Jaeger

#### 1. Add logzio-tracing repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm/logzio-tracing
```

#### 2. Deploy

Replace `<<TRACES-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-REGION>>` with your region’s code (for example, `eu`), defaults to `us`. For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

```shell
helm install \
--set=Secrets.TracesToken=VVFGWdpOVBNNluWlDFUDhnbDRDODOxZP \
--set=Configs.Region=<<LISTENER-REGION>> \
k8s-tracing logzio-tracing

```


### Configuration

| Parameter | Description | Default |
|---|---|---|
| `Secrets.TracesToken` | Secret with your [logzio traces token](https://app.logz.io/#/dashboard/settings/general) |  `""` |
| `Configs.Region` | |  `"us"` |
| `Configs.Namespace` | |  `"monitoring` |
| `Configs.AgentBrand` | |  `"otel"` |
| `Configs.CollectorBrand` | |  `"otel"` |
| `Configs.LogLevel` | |  `"INFO"` |
| `Jaeger.Agent.Image` | |  `"jaegertraci` |
| `Jaeger.Agent.Port` | |  `6831` |
| `Jaeger.Collector.Image` | |  `"logzio/jaege` |
| `Jaeger.Collector.Ports.ZipkingReceiver` | |  `9` |
| `Jaeger.Collector.Ports.JaegerReceiverGrpc` | | |` `Otel` | |` | 
| `Otel.Collector.Image` | |  `"otel/opentel` |
| `Otel.Collector.Ports.ZipkingReceiver` | |  `9` |
| `Otel.Collector.Ports.JaegerReceiverHttp` | |  `9` |
| `Otel.Collector.Ports.JaegerReceiverGrpc` | | |` `     ` | | |` `  Agent` | |` | 
| `Otel.Collector.Image` | |  `"otel/opentel` |
| `image` | The Filebeat docker image. | `docker.elastic.co/beats/filebeat` |
| `imageTag` | The Filebeat docker image tag. | `7.8.1` |
| `nameOverride` | Overrides the Chart name for resources. | `""` |
| `fullnameOverride` | Overrides the full name of the resources. | `filebeat` |
| `apiVersions.configMap` | ConfigMap API version. | `v1` |
| `apiVersions.daemonset` | Daemonset API version. | `apps/v1` |
| `apiVersions.clusterRoleBinding` | ClusterRoleBinding API version. | `rbac.authorization.k8s.io/v1` |
| `apiVersions.clusterRole` | ClusterRole API version. | `rbac.authorization.k8s.io/v1` |
| `apiVersions.serviceAccount` | ServiceAccount API version. | `v1` |
| `apiVersions.secret` | Secret API version. | `v1` |
| `namespace` | Chart's namespace. | `kube-system` |
| `managedServiceAccount` | Specifies whether the serviceAccount should be managed by this Helm Chart. Set this to `false` to manage your own service account and related roles. | `true` |
| `clusterRoleRules` | Configurable [cluster role rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole) that Filebeat uses to access Kubernetes resources. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `logzioCert` | Logzio public SSL certificate. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `configType` | Specifies which configuration to use for Filebeat. Set to `autodiscover` to use autodiscover. | `standard` |
| `filebeatConfig.standardConfig` | Standard Filebeat configuration, using `filebeat.input`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `filebeatConfig.autodiscoverConfig` | Autodiscover Filebeat configuration, using `filebeat.autodiscover`. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `filebeatConfig.autoCustomConfig` | Autodiscover Filebeat custom configuration, using `filebeat.autodiscover`. Should be used if you want to use your custimized autodiscover config | {} |
| `serviceAccount.create` | Specifies whether a service account should be created. | `true` |
| `serviceAccount.name` | Name of the service account. | `filebeat` |
| `terminationGracePeriod` | Termination period (in seconds) to wait before killing Filebeat pod process on pod shutdown. | `30` |
| `hostNetwork` | Controls whether the pod may use the node network namespace. | `true` |
| `dnsPolicy` | Specifies pod-specific DNS policies. | `ClusterFirstWithHostNet` |
| `daemonset.ignoreOlder` | Logs older than this will be ignored. | `3h` |
| `daemonset.logzioCodec` | Set to `json` if shipping JSON logs. Otherwise, set to `plain`. | `json` |
| `daemonset.logzioType` | The log type you'll use with this Daemonset. This is shown in your logs under the `type` field in Kibana. Logz.io applies parsing based on type. | `filebeat` |
| `daemonset.fieldsUnderRoot` | If this option is set to true, the custom fields are stored as top-level fields in the output document instead of being grouped under a `fields` sub-dictionary. | `"true"` |
| `daemonset.securityContext` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for Filebeat DaemonSet pod execution environment. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `daemonset.resources` | Allows you to set the resources for Filebeat Daemonset. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `daemonset.tolerations` | Set [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) for all DaemonSet pods. | `{}` |
| `daemonset.volumes` | Templatable string of additional `volumes` to be passed to the DaemonSet. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `daemonset.volumeMounts` | Templatable string of additional `volumeMounts` to be passed to the DaemonSet. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/filebeat/values.yaml) |
| `secrets.logzioShippingToken`| Secret with your [logzio shipping token](https://app.logz.io/#/dashboard/settings/general). | `""` |
| `secrets.logzioRegion`| Secret with your [logzio region](https://docs.logz.io/user-guide/accounts/account-region.html). Defaults to US East. | `" "` |
| `secrets.clusterName`| Secret with your cluster name. | `""` |


If you wish to change the default values, specify each parameter using the `--set key=value` argument to `helm install`. For example,

```shell
helm install --namespace=kube-system logzio-k8s-logs logzio-helm/logzio-k8s-logs \
  --set imageTag=7.7.0 \
  --set terminationGracePeriodSeconds=30
```

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.  
To uninstall the `logzio-k8s-logs` deployment:

```shell
helm uninstall --namespace=kube-system logzio-k8s-logs
```


## Change log
 - **0.0.2**:
    - Added option to set tolerations for daemonset (Thanks [jlewis42lines](https://github.com/jlewis42lines)!).
 - **0.0.1**:
    - Initial release.
