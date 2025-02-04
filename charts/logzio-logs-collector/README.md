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
| configMap.create         | Specifies whether a configMap should be created.                                 | `true`                                   |
| config                   | Base collector configuration, supports templating.                               | Complex structure (see `values.yaml`)    |
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
  