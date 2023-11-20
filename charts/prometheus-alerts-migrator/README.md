# Prometheus Alerts Migrator Helm Chart

This Helm chart deploys the Prometheus Alerts Migrator as a Kubernetes controller, which automates the migration of Prometheus alert rules to Logz.io's alert format, facilitating monitoring and alert management in a Logz.io integrated environment.

## Prerequisites

- Helm 3+
- Kubernetes 1.19+
- Logz.io account with API access

## Installing the Chart

To install the chart with the release name `logzio-prometheus-alerts-migrator`:

```sh
helm install \
  --set applicationConfig.annotation="prometheus.io/kube-rules" \
  --set applicationConfig.logzioAPIToken="your-logzio-api-token" \
  --set applicationConfig.logzioAPIURL="https://api.logz.io/" \
  --set applicationConfig.rulesDS="<<logzio_metrics_data_source_name>>" \
  --set applicationConfig.envID="<<env_id>>" \
  --set applicationConfig.workerCount=2 \
  logzio-prometheus-alerts-migrator logzio-helm/prometheus-alerts-migrator
```

## Configuration
The following table lists the configurable parameters of the Prometheus Alerts Migrator chart and their default values.

| Parameter | Description | Default |
|---|---|---|
| replicaCount | Number of controller replicas | 1 |
| image.repository | Container image repository | logzio/prometheus-alerts-migrator |
| image.pullPolicy | Container image pull policy | IfNotPresent |
| image.tag | Container image tag | v1.0.0-test |
| serviceAccount.create | Specifies whether a service account should be created | true |
| serviceAccount.name | The name of the service account to use | "" |
| applicationConfig.annotation | ConfigMap annotation for rules | prometheus.io/kube-rules |
| applicationConfig.logzioAPIToken | Logz.io API token | "" |
| applicationConfig.logzioAPIURL | Logz.io API URL | https://api.logz.io/ |
| applicationConfig.rulesDS | Data source for rules | IntegrationsTeamTesting_metrics |
| applicationConfig.envID | Environment ID | my-env-yotam |
| applicationConfig.workerCount | Number of workers | 2 |
| rbac.rules | Custom rules for the Kubernetes cluster role | [{apiGroups: [""], resources: ["configmaps"], verbs: ["get", "list", "watch"]}] |

### ConfigMap Format
The controller is designed to process ConfigMaps containing Prometheus alert rules. These ConfigMaps must be annotated with a specific key that matches the value of the `ANNOTATION` environment variable for the controller to process them.

### Example ConfigMap

Below is an example of how a ConfigMap should be structured:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logzio-rules
  namespace: monitoring
  annotations:
    prometheus.io/kube-rules: "true"
data:
  all_instances_down_otel_collector: |
    alert: Opentelemetry_Collector_Down
    expr: sum(up{app="opentelemetry-collector", job="kubernetes-pods"}) == 0
    for: 5m
    labels:
      team: sre
      severity: major
    annotations:
      description: "The OpenTelemetry collector has been down for more than 5 minutes."
      summary: "Instance down"
```
- Replace `prometheus.io/kube-rules` with the actual annotation you use to identify relevant ConfigMaps. The data section should contain your Prometheus alert rules in YAML format.
- Deploy the configmap to your cluster `kubectl apply -f <configmap-file>.yml`


## Changelog
- 1.0.0
  - initial release
