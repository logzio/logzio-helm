# logzio-metrics-collector

The table below lists the configurable parameters of the `logzio-metrics-collector` chart and their default values.

| Key                      | Description                                                                      | Default Value                          |
|--------------------------|----------------------------------------------------------------------------------|----------------------------------------|
| enabled                  | Toggle for enabling the Helm chart deployment.                                   | `true`                                 |
| nameOverride             | Override the default name for the deployment.                                    | `""`                                    |
| fullnameOverride         | Set a full name override for the deployment.                                     | `""`               |
| mode                     | Deployment mode ("daemonset" or "standalone").                                   | `daemonset`                           |
| namespaceOverride        | Override the namespace into which the resources will be deployed.                | `""`                                     |
| secrets.enabled          | Toggle for creating and managing the Logz.io secret by this chart.               | `true`                                   |
| secrets.name             | The name of the secret for Logz.io metrics collector.                            | `logzio-metric-collector-secrets`         |
| secrets.env_id           | Environment identifier attribute added to all metrics.                           | `my_env`                               |
| secrets.logzioMetricsToken  | Secret with your Logz.io metrics shipping token.                             | `<<METRICS-SHIPPING-TOKEN>>`                                |
| secrets.logzioRegion     | Secret with your Logz.io region.                                                 | `us`                                   |
| secrets.k8sObjectsLogsToken  | Secret with your Logz.io logs shipping token, optional for Kuebrnetes object logs and metrics correlation, set `k8sObjectsLogs.enabled` to `true`.                             | `<<LOGS-SHIPPING-TOKEN>>`                                |
| secrets.customEndpoint   | Secret with your custom endpoint, overrides Logz.io region listener address.     | `""`                                     |
| secrets.windowsNodeUsername | Secret with your Windows node username.                                        | `""`                                 |
| secrets.windowsNodePassword | Secret with your Windows node password.                                        | `""`                                 |
| configMap.create         | Specifies whether a configMap should be created.                                 | `true`                                   |
| baseConfig                   | Base collector configuration, supports templating.                               | Complex structure (see `values.yaml`)    |
| daemonsetConfig            | Configuration for OpenTelemetry Collector DaemonSet.                             | Complex structure (see `values.yaml`)  |
| standaloneConfig           | Configuration for standalone OpenTelemetry Collector.                           | Complex structure (see `values.yaml`)    |
| image.repository         | Docker image repository.                                                         | `otel/opentelemetry-collector-contrib` |
| image.pullPolicy         | Image pull policy.                                                               | `IfNotPresent`                         |
| image.tag                | Overrides the image tag.                                                         | `""`                                     |
| image.digest             | Pull images by digest.                                                           | `""`                                     |
| imagePullSecrets         | Specifies image pull secrets.                                                    | `[]`                                     |
| command.name             | OpenTelemetry Collector executable.                                              | `otelcol-contrib`                      |
| command.extraArgs        | Additional arguments for the command.                                            | `[]`                                     |
| serviceAccount.create    | Specifies whether a service account should be created.                           | `true`                                   |
| serviceAccount.name      | The name of the service account to use.                                          | `""`                                     |
| serviceAccount.annotations      | Annotations to add to the service account.                                          | `{}`                                     |
| clusterRole.create       | Specifies whether a cluster role should be created.                               | `true`                                   |
| clusterRole.name         | The name of the cluster role to use.                                              | `""`                                     |
| clusterRole.rules         | Access rules of the cluster role.                                              | `[]`                                     |
| clusterRole.annotations         | Annotations to add to the cluster role.                                              | `{}`                                     |
| clusterRole.clusterRoleBinding.annotations         | Annotations to add to the cluster role binding.                                              | `{}`                                     |
| clusterRole.clusterRoleBinding.name         | The name of the cluster role binding to use.                                              | `""`                                     |
| podSecurityContext       | Security context policies for the pod.                                           | `{}`                                     |
| securityContext          | Security context policies for the container.                                     | `{}`                                     |
| nodeSelector             | Node labels for pod assignment.                                                  | `{}`                                     |
| tolerations              | Tolerations for pod assignment.                                                  | `[]`                                     |
| affinity                 | Affinity rules for pod assignment.                                               | Complex structure (see `values.yaml`)    |
| priorityClassName        | Scheduler priority class name.                                                   | `""`                                     |
| extraEnvs                | Extra environment variables to set in the pods.                                  | `[]`                                     |
| ports                    | Defines ports configurations.                                                    | Complex structure (see `values.yaml`)    |
| resources                | CPU/memory resource requests/limits.                                             | Default: `limits.cpu:250m`, `limits.cpu:512Mi`     |
| podAnnotations           | Annotations to add to the pod | `{}`                                   |
| daemonsetCollector.configOverride | Configuration override for DaemonSet collector.                               | `{}`                                   |
| daemonsetCollector.affinity| Affinity rules for DaemonSet pod placement.                                       | Complex structure (see `values.yaml`)  |
| daemonsetCollector.resources | CPU/memory resource requests/limits for DaemonSet.                            | Default: `limits.memory: 250Mi`, `requests.cpu: 150m` |
| daemonsetCollector.podLabels | Labels to add to the DaemonSet pod.                                            | `{}`                                   |
| daemonsetCollector.podAnnotations | Annotations to add to the DaemonSet pod.                                  | `{}`                                   |
| standaloneCollector.configOverride | Configuration override for standalone collector.                               | `{}`                                   |
| standaloneCollector.replicas | Number of replicas for the standalone collector.                               | `1`                                    |
| standaloneCollector.resources | CPU/memory resource requests/limits for standalone collector.                 | Default: `limits.memory: 512Mi`, `requests.cpu: 200m` |
| standaloneCollector.podLabels | Labels to add to the standalone pod.                                           | `{}`                                   |
| standaloneCollector.podAnnotations | Annotations to add to the standalone pod.                                 | `{}`                                   |
| applicationMetrics.enabled | Enable sending application metrics.                                              | `false`                                 |
| k8sObjectsLogs.enabled     | Enable Kubernetes objects logging.                                               | `false`                                |
| k8sObjectsLogs.config      | Configuration for Kubernetes objects logging.                                    | Complex structure (see `values.yaml`)  |
| networkPolicy.enabled      | Enable NetworkPolicy creation.                                                   | `false`                                |
| networkPolicy.annotations  | Annotations to add to the NetworkPolicy.                                          | `{}`                                   |
| networkPolicy.allowIngressFrom | Configure the 'from' clause of the NetworkPolicy.                             | `[]`                                   |
| networkPolicy.extraIngressRules | Add additional ingress rules to specific ports.                              | `[]`                                   |
| networkPolicy.egressRules  | Restrict egress traffic from the OpenTelemetry collector pod.                    | `[]`                                   |
| useGOMEMLIMIT              | Set GOMEMLIMIT env var to a percentage of resources.limits.memory.               | `false`                                |
| opencost.enabled           | Enable OpenCost integration.                                                     | `false`                                |
| opencost.config            | Configuration for OpenCost integration.                                          | Complex structure (see `values.yaml`)  |
| enableMetricsFilter.gke    | Enable metrics filtering for Google Kubernetes Engine.                           | `false`                                |
| enableMetricsFilter.eks    | Enable metrics filtering for Amazon Elastic Kubernetes Service.                  | `false`                                |
| enableMetricsFilter.aks    | Enable metrics filtering for Azure Kubernetes Service.                           | `false`                                |
| enableMetricsFilter.dropKubeSystem | Drop kube-system metrics.                                                | `false`                                |
| prometheusFilters.metrics.infrastructure.keep.aks | Metrics to keep for AKS infrastructure pipeline.           | Complex structure (see `values.yaml`)  |
| prometheusFilters.metrics.infrastructure.keep.eks | Metrics to keep for EKS infrastructure pipeline.           | Complex structure (see `values.yaml`)  |
| prometheusFilters.metrics.infrastructure.keep.gke | Metrics to keep for GKE infrastructure pipeline.           | Complex structure (see `values.yaml`)  |
| prometheusFilters.metrics.infrastructure.drop.custom | Custom metrics to drop for infrastructure pipeline.     | `""`                                   |
| prometheusFilters.namespaces.infrastructure.keep.custom | Custom namespaces to keep for infrastructure pipeline. | `""`                                   |
| prometheusFilters.namespaces.infrastructure.drop.kubeSystem | Drop kube-system namespace.                                   | `kube-system`                                   |
| initContainers            | List of init container specs.                                                     | `[]`                                   |
| extraContainers           | List of extra sidecars to add.                                                    | `[]`                                   |
| hostNetwork               | Use the host's network namespace.                                                 | `false`                                |
| dnsPolicy                 | Pod DNS policy.                                                                   | `""`                                   |
| dnsConfig                 | Custom DNS config.                                                                | `{}`                                   |
| hostAliases               | Adding entries to Pod /etc/hosts with HostAliases.                                | `[]`                                   |
| extraEnvsFrom             | Extra environment variables to set in the pods from a source.                     | `[]`                                   |
| extraVolumes              | Extra volumes to add to the pods.                                                 | `[]`                                   |
| extraVolumeMounts         | Extra volume mounts to add to the pods.                                           | `[]`                                   |
| additionalLabels                  | Common labels to add to all otel-collector resources.                            | `{}`                                   |
| podMonitor.enabled        | Enable the creation of a PodMonitor.    | `false`                             | 
| podMonitor.metricsEndpoints       | Metrics endpoints configuration for PodMonitor.                                  | Complex structure (see `values.yaml`)  |
| podMonitor.extraLabels            | Additional labels for the PodMonitor.                                            | `{}`                                   |
| rollout.rollingUpdate             | Rolling update strategy for deployments.                                         | `{}`                                   |
| rollout.strategy                  | Deployment strategy for rolling updates.                            | `RollingUpdate`                                   |
| service.enabled                   | Enable the creation of a Service.                                                | `true`                                 |
| service.type                      | Type of service to create.                                                       | `ClusterIP`                            |
| service.annotations               | Annotations to add to the Service.                                               | `{}`                                   |
| service.externalTrafficPolicy     | External traffic policy for LoadBalancer service.                                | `Cluster`                              |
| service.internalTrafficPolicy     | Internal traffic policy for DaemonSet service.                                   | `Local`                                |
| service.loadBalancerIP            | LoadBalancer IP if `service.type` is `LoadBalancer`.                             | `""`                                   |
| service.loadBalancerSourceRanges  | Source ranges for LoadBalancer service.                                          | `[]`                                   |
| ingress.enabled                   | Enable ingress controller resource.                                              | `false`                                |
| ingress.annotations               | Annotations to add to the ingress.                                               | `{}`                                   |
| ingress.hosts                     | List of ingress hosts.                                                           | `[]`                                   |
| ingress.tls                       | TLS configuration for the ingress.                                               | `[]`                                   |
| ingress.ingressClassName          | Name of the ingress class to use.                                                | `""`                                   |
| ingress.additionalIngresses       | Additional ingress configurations.                                               | `[]`                                   |
| `windowsExporterInstallerJob.interval`                | Interval at which the Windows Exporter Installer Job runs.                  | `"*/10 * * * *"`                                 |
| `windowsExporterInstallerJob.concurrencyPolicy`        | Concurrency policy for the Windows Exporter Installer Job.                  | `"Forbid"`                                 |
| `windowsExporterInstallerJob.successfulJobsHistoryLimit` | Number of successful Windows Exporter Installer jobs to retain.                                      | `1`                                 |
| `windowsExporterInstallerJob.failedJobsHistoryLimit`    | Number of failed Windows Exporter Installer jobs to retain.                                          | `1`                                 |
| `windowsExporterInstallerJob.ttlSecondsAfterFinished`   | Time to live in seconds for the Windows Exporter Installer Job.                      | `3600`                                 |