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
  --set config.configMapAnnotation="prometheus.io/kube-rules" \
  --set config.logzioAPIToken="your-logzio-api-token" \
  --set config.logzioAPIURL="https://api.logz.io/" \
  --set config.rulesDS="<<logzio_metrics_data_source_name>>" \
  --set config.env_id="<<env_id>>" \
  --set config.workerCount=2 \
  logzio-prometheus-alerts-migrator logzio-helm/prometheus-alerts-migrator
```

## Configuration
The following table lists the configurable parameters of the Prometheus Alerts Migrator chart and their default values.

| Parameter | Description | Default |
|---|---|---|
| `replicaCount` | Number of controller replicas | 1 |
| `image.repository` | Container image repository | logzio/prometheus-alerts-migrator |
| `image.pullPolicy` | Container image pull policy | IfNotPresent |
| `image.tag`| Container image tag | v1.0.0-test |
| `serviceAccount.create` | Specifies whether a service account should be created | true |
| `serviceAccount.name` | The name of the service account to use | "" |
| `config.configMapAnnotation` | ConfigMap annotation for rules | prometheus.io/kube-rules |
| `config.logzioAPIToken` | Logz.io API token | "" |
| `config.logzioAPIURL` | Logz.io API URL | https://api.logz.io/ |
| `config.rulesDS` | Data source for rules | IntegrationsTeamTesting_metrics |
| `config.env_id` | Environment ID | my-env-yotam |
| `config.workerCount` | Number of workers | 2 |
| `rbac.rules` | Custom rules for the Kubernetes cluster role | [{apiGroups: [""], resources: ["configmaps"], verbs: ["get", "list", "watch"]}] |

## Secret Management

The chart can optionally create a Kubernetes Secret to store sensitive information like the Logz.io API token. You can control the creation and naming of this Secret through the following configurations in the `values.yaml` file.

| Parameter       | Description                                                        | Default             |
| --------------- | ------------------------------------------------------------------ | ------------------- |
| `secret.enabled` | Determines whether a Secret should be created by the Helm chart.  | `true`              |
| `secret.name`    | Specifies the name of the Secret to be used.                      | `logzio-api-token`  |


### Using an Existing Secret
By default, the chart will create a Secret named `logzio-api-token`. You can change the name by setting `secret.name` to your preferred name. If you enable Secret creation, make sure to provide the actual token value in the `values.yaml` or via the `--set` flag:
```sh
helm install \
  --set logzioAPIToken=your-logzio-api-token \
  logzio-prometheus-alerts-migrator logzio-helm/prometheus-alerts-migrator
```

If you prefer to manage the Secret outside of the Helm chart (e.g., for security reasons or to use an existing Secret), set `secret.enabled` to `false` and provide the name of your existing Secret in `secret.name`.

Example of disabling Secret creation and using an existing Secret:

```sh
helm install \
  --set secret.enabled=false \
  --set secret.name=my-existing-secret \
  logzio-prometheus-alerts-migrator logzio-helm/prometheus-alerts-migrator
```
In this case, ensure that your existing Secret my-existing-secret contains the necessary key (`token` in this context) with the appropriate value (Logz.io API token).


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
