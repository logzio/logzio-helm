# logzio-trivy

The `logzio-monitoring` Helm Chart deploys the [Trivy operator](https://github.com/aquasecurity/trivy-operator) to your Kubernetes cluster, and sends its reports to Logz.io

**Note:**
- This project is currently in *beta* and is prone to changes.
- Currently only vulnerability is being collected.

## Instructions for standard deployment:

### 1. Add the Helm Chart:

```sh
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

### 2. Deploy the Chart:

Use the following command, and replace the placeholders with your parameters:

```sh
helm install -n monitoring --create-namespace \
--set global.env_id="<<ENV-ID>>" \
--set global.logzioLogsToken="<<LOG-SHIPPING-TOKEN>>" \
--set global.logzioRegion="<<LOGZIO-REGION>>" \
logzio-trivy logzio-helm/logzio-trivy
```

| Parameter | Description |
| --- | --- |
| `<<LOG-SHIPPING-TOKEN>>` | Your [logs shipping token](https://app.logz.io/#/dashboard/settings/general). |
| `<<LOGZIO-REGION>>` | Your account's [region code](https://docs.logz.io/docs/user-guide/admin/hosting-regions/account-region/). For example - `us` |
| `<<ENV-ID>>` | The name for your environment's identifier, to easily identify the telemetry data for each environment. |


### Further configuration

The above `helm install` command will deploy a standard configuration version of the Chart.

However, you can modify the Chart by using the `--set` flag in your `helm install` command:

| Parameter	| Description | Default |
| --- | --- | --- |
| `trivy-operator.trivy.ignoreUnfixed` | Whether to show only fixed vulnerabilities in vulnerabilities reported by Trivy. | `false` |
| `trivy-operator.operator.configAuditScannerEnabled` | The flag to enable configuration audit scanner | `false` |
| `trivy-operator.operator.rbacAssessmentScannerEnabled` | The flag to enable rbac assessment scanner | `false` |
| `trivy-operator.operator.infraAssessmentScannerEnabled` | The flag to enable infra assessment scanner | `false` |
| `trivy-operator.operator.clusterComplianceEnabled` | The flag to enable cluster compliance scanner | `false` |
| `nameOverride` | Overrides the Chart name for resources. | `""` |
| `fullnameOverride` | Overrides the full name of the resources. | `""` |
| `schedule` | Time for daily scanning for security reports and send them to Logz.io, in format "HH:MM" | `"07:00"` |
| `image` | Container image | `logzio/trivy-to-logzio` |
| `imageTag` | Container image tag | `0.2.1` |
| `global.env_id` | The name for your environment's identifier, to easily identify the telemetry data for each environment | `""` |
| `terminationGracePeriodSeconds` | Termination period (in seconds) to wait before killing Fluentd pod process on pod shutdown. | `30` |
| `serviceAccount.create` | Specifies whether to create a service account for the Deployment | `true` |
| `serviceAccount.name` | Name of the service account. | `""` |
| `secret.enabled` | Specifies wheter to create a secret for the deployment | `true` |
| `secret.name` | Secret name | `"logzio-logs-secret-trivy"` |
| `global.logzioLogsToken` | Your logz.io log shipping token | `""` |
| `global.logzioRegion` | Your logz.io region code, for example - `eu` | `"us"` (defaults to us region) |
| `scriptLogLevel` | Log level of the script that sends security risk to Logz.io. Can be one of: `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`. | `INFO` |

### Handling image pull rate limit
In some cases (i.e spot clusters) where the pods/nodes are replaced frequently, the pull rate limit for images pulled from dockerhub might be reached, with an error:
```shell
You have reached your pull rate limit. You may increase the limit by authenticating and upgrading: https://www.docker.com/increase-rate-limits.
```
In these cases we can use the following `--set` command to use an alternative image repository:

```shell
--set image=public.ecr.aws/logzio/trivy-to-logzio
```
