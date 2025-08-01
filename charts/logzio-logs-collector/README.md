# logzio-logs-collector

**In development**

Kubernetes logs collection agent for Logz.io based on OpenTelemetry Collector.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.9+

Below is the extended README.md, including the full configuration table based on the provided `values.yaml`.


* * *

Logz.io Logs Collector for Kubernetes
=====================================

The `logzio-logs-collector` Helm chart deploys a Kubernetes logs collection agent designed to forward logs from Kubernetes clusters to Logz.io. This solution leverages the OpenTelemetry Collector, providing a robust and flexible way to manage log data, ensuring that your logging infrastructure scales with your application needs.

Features
--------

*   **Easy Integration with Logz.io**: Pre-configured to send logs to Logz.io, simplifying setup and integration.
*   **Secure Secret Management**: Option to automatically manage secrets for seamless and secure authentication with Logz.io.
*   **SignalFx Receiver Support**: Accept logs from SignalFx client libraries and forward them to Logz.io.

Getting Started
---------------

### Add Logz.io Helm Repository

Before installing the chart, add the Logz.io Helm repository:

```
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

### Installation

1.  **Create the Logz.io Secret**
    
    If not managing secrets externally, create the Logz.io secret with your shipping token and other relevant information.
    
2.  **Install the Chart**
    
    Install `logzio-logs-collector` from the Logz.io Helm repository, specifying the authentication values:

    ```
    helm install logzio-logs-collector -n monitoring \
    --set enabled=true \
    --set global.logzioLogsToken=<<token>> \
    --set global.logzioRegion=<<region>> \
    --set global.env_id=<<env_id>> \
    --set global.logType=<<logType>> \
    logzio-helm/logzio-logs-collector
    ```

    Replace:
    * `logzio-logs-collector` with your release name
    * `<<token>>` with your Logz.io logs shipping token
    * `<<region>>` with your Logz.io [account region code](https://docs.logz.io/docs/user-guide/admin/hosting-regions/account-region/)
    * `<<env_id>>` with a unique name assigned to your environment's identifier, to differentiate telemetry data across various environments
    * `<<logType>>` with a log type for your logs

### SignalFx Support

The logs collector supports receiving logs from SignalFx client libraries. To enable SignalFx receiver:

```
helm install logzio-logs-collector -n monitoring \
--set enabled=true \
--set global.logzioLogsToken=<<token>> \
--set global.logzioRegion=<<region>> \
--set global.env_id=<<env_id>> \
--set global.logType=<<logType>> \
--set global.signalFx.enabled=true \
logzio-helm/logzio-logs-collector
```

The SignalFx receiver will be available on port 9943 and will accept logs from SignalFx client libraries, forwarding them to Logz.io.

    
### Uninstalling the Chart

To uninstall/delete the `logzio-logs-collector` deployment:

```shell
helm delete -n monitoring logzio-logs-collector
```

Configuration
-------------

The table below lists the configurable parameters of the `logzio-logs-collector` chart and their default values.

| Key                      | Description                                                                      | Default Value                          |
|--------------------------|----------------------------------------------------------------------------------|----------------------------------------|
| enabled                  | Toggle for enabling the Helm chart deployment.                                   | `false`                                 |
| nameOverride             | Override the default name for the deployment.                                    | `""`                                    |
| fullnameOverride         | Set a full name override for the deployment.                                     | `""`                                    |
| mode                     | Deployment mode (currently supports `"daemonset"` and `"standalone"`).           | `"daemonset"`                           |
| namespaceOverride        | Override the namespace into which the resources will be deployed.                | `""`                                     |
| fargateLogRouter.enabled | Boolean to decide if to configure Fargate log router (EKS Fargate environments). | `false`                                  |
| secret.enabled          | Toggle for creating and managing the Logz.io secret by this chart.               | `true`                                   |
| secret.name             | The name of the secret for Logz.io log collector.                                | `"logzio-log-collector-secrets"`         |
| global.env_id           | Environment identifier attribute added to all logs.                              | `"my_env"`                               |
| global.logType          | Default log type field.                                                          | `"k8s"`                                  |
| global.logzioLogsToken  | Secret with your Logz.io logs shipping token.                                    | `"token"`                                |
| global.LogzioRegion     | Secret with your Logz.io region.                                                 | `"us"`                                   |
| global.customLogsEndpoint   | Secret with your custom endpoint, overrides Logz.io region listener address.     | `""`                                     |
| global.signalFx.enabled | Enable SignalFx receiver for accepting logs from SignalFx client libraries.      | `false`                                  |
| configMap.create         | Specifies whether a configMap should be created.                                 | `true`                                   |
| config                   | Base collector configuration, supports templating.                               | Complex structure (see `values.yaml`)    |
| signalFx.enabled | bool | `false` | Local override for enabling SignalFx receiver (takes precedence over global.signalFx.enabled). |
| signalFx.config | object | `{}` | Custom configuration for the SignalFx receiver pipeline, including receiver settings, processors, and exporters. |
| image.repository         | Docker image repository.                                                         | `"otel/opentelemetry-collector-contrib"` |
| image.pullPolicy         | Image pull policy.                                                               | `"IfNotPresent"`                         |
| image.tag                | Overrides the image tag.                                                         | `""`                                     |
| image.digest             | Pull images by digest.                                                           | `""`                                     |
| imagePullSecrets         | Specifies image pull secrets.                                                    | `[]`                                     |
| command.name             | OpenTelemetry Collector executable.                                              | `"otelcol-contrib"`                      |
| command.extraArgs        | Additional arguments for the command.                                            | `[]`                                     |
| serviceAccount.create    | Specifies whether a service account should be created.                           | `true`                                   |
| serviceAccount.name      | The name of the service account to use.                                          | `""`                                     |
| clusterRole.create       | Specifies whether a clusterRole should be created.                               | `true`                                   |
| clusterRole.name         | The name of the clusterRole to use.                                              | `""`                                     |
| podSecurityContext       | Security context policies for the pod.                                           | `{}`                                     |
| securityContext          | Security context policies for the container.                                     | `{}`                                     |
| nodeSelector             | Node labels for pod assignment.                                                  | `{}`                                     |
| tolerations              | Tolerations for pod assignment.                                                  | `[]`                                     |
| affinity                 | Affinity rules for pod assignment.                                               | Complex structure (see `values.yaml`)    |
| priorityClassName        | Scheduler priority class name.                                                   | `""`                                     |
| extraEnvs                | Extra environment variables to set in the pods.                                  | `[]`                                     |
| ports                    | Defines ports configurations.                                                    | Complex structure (see `values.yaml`)    |
| resources                | CPU/memory resource requests/limits.                                             | `limits.cpu:250m` `limits.cpu:512Mi`     |
| podAnnotations           | Annotations to add to the pod.                                                   | `{}`                                     |
| podLabels                | Labels to add to the pod.                                                        | `{}`                                     |
| hostNetwork              | Use the host's network namespace.                                                | `false`                                  |
| dnsPolicy                | Pod DNS policy.                                                                  | `""`                                     |
| livenessProbe            | Liveness probe configuration.                                                    | (see `values.yaml`)                      |
| readinessProbe           | Readiness probe configuration.                                                   | (see `values.yaml`)                      |     
| service.enabled          | Enable the creation of a Service.                                                | `true`                                   |
| ingress.enabled          | Enable ingress resource creation.                                                | `false`                                  |
| podMonitor.enabled       | Enable the creation of a PodMonitor.                                             | `false`                                  |
| networkPolicy.enabled    | Enable NetworkPolicy creation.                                                   | `false`                                  |
| useGOMEMLIMIT            | Set GOMEMLIMIT env var to a percentage of resources.limits.memory.               | `false`                                 |
| filters                  | Include / exclude rules for dropping or keeping logs before shipping (see "Filtering logs" section). | `{}` |

### Configure customization options

You can use the following options to update the Helm chart parameters: 

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`

* Edit the `values.yaml`

* Overide default values with your own `my_values.yaml` and apply it in the `helm install` command. 

Multi line logs configuration
-----------------------------
The collector supports by default various log formats (including multiline logs) such as `CRI-O` `CRI-Containerd` `Docker` formats. You can configure the chart to parse custom multiline logs pattern according to your needs, please read [Customizing Multiline Log Handling](./examples/multiline.md) guide for more details.

Log collection in eks fargate environemnt
-----------------------------
You can use the `fargateLogRouter.enabled` value to enable log collection in eks fargate environemnt via fluentbit log-router
```sh
    helm install logzio-logs-collector -n monitoring \
    --set enabled=true \
    --set global.logzioLogsToken=<<token>> \
    --set global.logzioRegion=<<region>> \
    --set global.env_id=<<env_id>> \
    --set global.logType=<<logType>> \
    --set fargateLogRouter.enabled="true" \
    logzio-helm/logzio-logs-collector
```
### Kubernetes metadata fields naming changes in eks fargate environemnt >= `1.0.9`
Changes in fields names:
  - `kubernetes.*` -> `kubernetes_*`
  - `kubernetes.labels.*` -> `kubernetes_labels_*`
  - `kubernetes.annotations.*` -> `kubernetes_annotations_*`
  
Filtering logs (since 2.2.0)
-----------------------------
You can drop or keep logs **before** they leave the cluster using the new `filters` key in `values.yaml`.

### Syntax overview

```yaml
filters:
  exclude:                  # evaluated first (OR logic)
    namespace: "kube-system|monitoring"
    service: "^synthetic-.*$"
    attribute:
      log.level: "debug|trace"
    resource:
      k8s.pod.name: "^debug-.*$"

  include:                  # evaluated second (AND logic)
    namespace: "prod"
    service: "^app-.*$"
```

Rules use full [RE2 regular expressions](https://github.com/google/re2/wiki/Syntax).  
The available top-level targets are:

* **namespace** – matches `resource.attributes["k8s.namespace.name"]`
* **service** – matches `resource.attributes["service.name"]`
* **attribute.&lt;key&gt;** – matches any log attribute key
* **resource.&lt;key&gt;** – matches any resource attribute key

Processing order:
1. **exclude** – if a log record matches *any* exclude rule it is dropped immediately.
2. **include** – if include rules exist, the remaining records must match *all* of them to be kept.
3. If no include rules exist, everything not excluded is forwarded.

The chart translates these rules into OpenTelemetry `filter` processors and injects them directly **after** the `k8sattributes` processor so Kubernetes metadata is available during matching.
