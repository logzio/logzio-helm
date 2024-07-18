-------------

The table below lists the configurable parameters of the `logzio-metrics-collector` chart and their default values.

| Key                      | Description                                                                      | Default Value                          |
|--------------------------|----------------------------------------------------------------------------------|----------------------------------------|
| enabled                  | Toggle for enabling the Helm chart deployment.                                   | `false`                                 |
| nameOverride             | Override the default name for the deployment.                                    | `""`                                    |
| fullnameOverride         | Set a full name override for the deployment.                                     | `""`               |
| mode                     | Deployment mode ("daemonset" or "standalone").                           | `"daemonset"`                           |
| namespaceOverride        | Override the namespace into which the resources will be deployed.                | `""`                                     |
| secrets.enabled          | Toggle for creating and managing the Logz.io secret by this chart.               | `true`                                   |
| secrets.name             | The name of the secret for Logz.io metrics collector.                                | `"logzio-metric-collector-secrets"`         |
| secrets.env_id           | Environment identifier attribute added to all metrics.                              | `"my_env"`                               |
| secrets.logzioMetricsToken  | Secret with your Logz.io metrics shipping token.                                    | `"token"`                                |
| secrets.logzioRegion     | Secret with your Logz.io region.                                                 | `"us"`                                   |
| secrets.customEndpoint   | Secret with your custom endpoint, overrides Logz.io region listener address.     | `""`                                     |
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