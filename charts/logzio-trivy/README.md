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
--set env_id="<<ENV-ID>>" \
--set secrets.logzioShippingToken="<<LOG-SHIPPING-TOKEN>>" \
--set secrets.logzioListener="<<LISTENER-HOST>>" \
logzio-trivy logzio-helm/logzio-trivy
```

| Parameter | Description |
| --- | --- |
| `<<LOG-SHIPPING-TOKEN>>` | Your [logs shipping token](https://app.logz.io/#/dashboard/settings/general). |
| `<<LISTENER-HOST>>` | Your account's [listener host](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping?product=logs). For example - `listener.logz.io` |
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
| `env_id` | The name for your environment's identifier, to easily identify the telemetry data for each environment | `""` |
| `terminationGracePeriodSeconds` | Termination period (in seconds) to wait before killing Fluentd pod process on pod shutdown. | `30` |
| `serviceAccount.create` | Specifies whether to create a service account for the Deployment | `true` |
| `serviceAccount.name` | Name of the service account. | `""` |
| `secrets.enabled` | Specifies wheter to create a secret for the deployment | `true` |
| `secrets.name` | Secret name | `"logzio-logs-secret-trivy"` |
| `secrets.logzioShippingToken` | Your logz.io log shipping token | `""` |
| `secrets.logzioListener` | Your logz.io listener host, for example - `listener.logz.io` | `""` (defaults to us region) |
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


## Changelog
- **0.3.3**:
  - Upgrade to image `logzio/trivy-to-logzio:0.3.3`.
    - Upgrade python version to 3.12.5.
    - Re-build image to include the latest version of git(CVE-2024-32002).
  - Bump Trivy-Operator version to `0.24.0`.
- **0.3.2**:
  - Added 'user-agent' header for telemetry data.
- **0.3.0**:
  - Bump Trivy-Operator version to `0.15.1`.
- **0.2.1**:
  - Default to disable unused reports (config audit, rbac assessment, infra assessment, cluster compliance).
  - Bump Trivy-Operator version to `0.13.1`.
  - Bump logzio-trivy version to `0.2.1`.
- **0.2.0**:
  - Upgrade to image `logzio/trivy-to-logzio:0.2.0`:
    - Watch for new reports, in addition to daily scan.
- **0.1.0**:
  - Upgrade to image `logzio/trivy-to-logzio:0.1.0`.
  - **Breaking changes**:
    - Deprecation of CronJob, using Deployment instead.
    - Scanning for reports will occur once upon container deployment, then once a day at the scheduled time. 
    - Not using cron expressions anymore. Instead, set a time for the daily run in form of HH:MM. 
- **0.0.2**: Add quotes to schedule expression to avoid errors. 
- **0.0.1**: Initial release.
