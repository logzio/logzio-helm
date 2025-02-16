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
  --set config.rulesConfigMapAnnotation="prometheus.io/kube-rules" \
  --set config.alerManagerConfigMapAnnotation="prometheus.io/kube-alertmanager" \
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
| `image.tag`| Container image tag | v1.0.3 |
| `serviceAccount.create` | Specifies whether a service account should be created | true |
| `serviceAccount.name` | The name of the service account to use | "" |
| `config.rulesConfigMapAnnotation` | ConfigMap annotation for rules | prometheus.io/kube-rules |
| `config.alerManagerConfigMapAnnotation` | ConfigMap annotation for alert manager configuration | prometheus.io/kube-alertmanager |
| `config.logzioAPIToken` | Logz.io API token | "" |
| `config.logzioAPIURL` | Logz.io API URL | https://api.logz.io/ |
| `config.rulesDS` | Data source for rules | IntegrationsTeamTesting_metrics |
| `config.env_id` | Environment ID | my-env-yotam |
| `config.workerCount` | Number of workers | 2 |
| `config.ignoreSlackText` | Ignore slack contact points `title` field. | false |
| `config.ignoreSlackTitle` | Ignore slack contact points `text` field. | false |
| `rbac.rules` | Custom rules for the Kubernetes cluster role | [{apiGroups: [""], resources: ["configmaps"], verbs: ["get", "list", "watch"]},{apiGroups: [""], resources: ["events"], verbs: ["create", "get", "list", "watch"]}] |

## Secret Management

The chart can optionally create a Kubernetes Secret to store sensitive information like the Logz.io API token. You can control the creation and naming of this Secret through the following configurations in the `values.yaml` file.

| Parameter       | Description                                                        | Default             |
| --------------- | ------------------------------------------------------------------ | ------------------- |
| `secret.create` | Determines whether a Secret should be created by the Helm chart.  | `true`              |
| `secret.name`   | Specifies the name of the Secret to be used.                      | `logzio-api-token`  |


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


### Rules configMap Format
The controller is designed to process ConfigMaps containing Prometheus alert rules and promethium alert manager configuration. These ConfigMaps must be annotated with a specific key that matches the value of the `RULES_CONFIGMAP_ANNOTATION` or `ALERTMANAGER_CONFIGMAP_ANNOTATION` environment variables for the controller to process them.


### Example rules ConfigMap

Below is an example of how a rules configMap should be structured:

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

Below is an example of how a alert manager ConfigMap should be structured:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: logzio-rules
  namespace: monitoring
  annotations:
    prometheus.io/kube-alertmanager: "true"
data:
  all_instances_down_otel_collector: |
    global:
      # Global configurations, adjust these to your SMTP server details
      smtp_smarthost: 'smtp.example.com:587'
      smtp_from: 'alertmanager@example.com'
      smtp_auth_username: 'alertmanager'
      smtp_auth_password: 'password'
    # The root route on which each incoming alert enters.
    route:
      receiver: 'default-receiver'
      group_by: ['alertname', 'env']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 1h
      # Child routes
      routes:
        - match:
            env: production
          receiver: 'slack-production'
          continue: true
        - match:
            env: staging
          receiver: 'slack-staging'
          continue: true
    
    # Receivers defines ways to send notifications about alerts.
    receivers:
      - name: 'default-receiver'
        email_configs:
          - to: 'alerts@example.com'
      - name: 'slack-production'
        slack_configs:
          - api_url: 'https://hooks.slack.com/services/T00000000/B00000000/'
            channel: '#prod-alerts'
      - name: 'slack-staging'
        slack_configs:
          - api_url: 'https://hooks.slack.com/services/T00000000/B11111111/'
            channel: '#staging-alerts'

```
- Replace `prometheus.io/kube-alertmanager` with the actual annotation you use to identify relevant ConfigMaps. The data section should contain your Prometheus alert rules in YAML format.
- Deploy the configmap to your cluster `kubectl apply -f <configmap-file>.yml`


## Changelog
- v2.1.1
  - Upgrade `logzio/prometheus-alerts-migrator` image `v1.2.0`->`v1.2.1`:
    - Add support for MS Teams v2 contact points
    - Update `prometheus/alertmanager`: `v0.27.0` -> `v0.28.0`
- v2.1.0
  - Upgrade `logzio/prometheus-alerts-migrator` image `v1.1.0`->`v1.2.0`:
    - Add support for MS Teams contact points
    - Update dependencies:
      - `prometheus/common`: `v0.60.1` -> `v0.61.0`
      - `prometheus/prometheus`: `v0.55.0` -> `v0.301.0`
      - `k8s.io/api`: `v0.31.2` -> `v0.32.0`
      - `k8s.io/apimachinery`: `v0.31.2` -> `v0.32.0`
      - `k8s.io/client-go`: `v0.31.2` -> `v0.32.0`
    - Improve error handling In event handler creation
    - Refactor import alias names to lowercase
- v2.0.3
  - Upgrade `logzio/prometheus-alerts-migrator` image `v1.0.3`->`v1.1.0`
    - Add support for migrating alert rules groups
    - Upgrade GoLang version to 1.23
    - Upgrade dependencies
      - `k8s.io/client-go`: `v0.28.3` -> `v0.31.2`
      - `k8s.io/apimachinery`: `v0.28.3` -> `v0.31.2`
      - `k8s.io/api`: `v0.28.3` -> `v0.31.2`
      - `k8s.io/klog/v2`: `v2.110.1` -> `v2.130.1`
      - `logzio_terraform_client`: `1.20.0` -> `1.22.0`
      - `prometheus/common`: `v0.44.0` -> `v0.60.1`
      - `prometheus/alertmanager`: `v0.26.0` -> `v0.27.0`
      - `prometheus/prometheus`: `v0.47.2` -> `v0.55.0`
- v2.0.2
  - Remove default resources `limits`
- v2.0.1
  - values.yaml:
    - Added rbac permissions to create `events`
- v2.0.0
  - values.yaml:
    - Added: `config.alerManagerConfigMapAnnotation`, `config.ingnoreSlackText`, `config.ingnoreSlackTitle` values
    - Refactor: `config.configMapAnnotation`->`config.rulesConfigMapAnnotation`
  - Upgrade `logzio/prometheus-alerts-migrator` image `v1.0.0`->`v1.0.3`:
    - Handle Prometheus alert manager configuration file
    - Add CRUD operations for contact points and notification policies
    - Add `reduce` query to alerts (grafana alerts can evaluate alerts only from reduced data)
    - Update `logzio_terraform_client`: `1.18.0` -> `1.19.0`
    - Use data source uid instead of name
- v1.0.0
  - initial release
