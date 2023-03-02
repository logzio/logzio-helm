# logzio-trivy

The logzio-monitoring Helm Chart deploys the [Trivy operator](https://github.com/aquasecurity/trivy-operator) to your k8s cluster, and sends its reports to Logz.io

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
helm install -n monitoring \
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

The above `helm install` command will deploy a standard configuration version of the Chart, for shipping logs, metrics and traces.

However, you can modify the Chart by using the `--set` flag in your `helm install` command:

| Parameter	| Description | Default |
| --- | --- | --- |
| `trivy-operator.trivy.ignoreUnfixed` | Whether to show only fixed vulnerabilities in vulnerabilities reported by Trivy. | `false` |
| `nameOverride` | Overrides the Chart name for resources. | `""` |
| `fullnameOverride` | Overrides the full name of the resources. | `""` |
| `schedule` | Cron expression for scheduling shipping vulnerability report to logz.io | `"0 7 * * *"` |
| `restartPolicy` | Container restart policy | `OnFailure` |
| `image` | Container image | `logzio/trivy-to-logzio` |
| `imageTag` | Container image tag | `0.0.1` |
| `env_id` | The name for your environment's identifier, to easily identify the telemetry data for each environment | `""` |
| `terminationGracePeriodSeconds` | Termination period (in seconds) to wait before killing Fluentd pod process on pod shutdown. | `30` |
| `serviceAccount.create` | Specifies whether to create a service account for the cron job | `true` |
| `serviceAccount.name` | Name of the service account. | `""` |
| `secrets.enabled` | Specifies wheter to create a secret for the cron job | `true` |
| `secrets.name` | Secret name | `"logzio-logs-secret-trivy"` |
| `secrets.logzioShippingToken` | Your logz.io log shipping token | `""` |
| `secrets.logzioListener` | Your logz.io listener host | `""` (defaults to us region) |


## Changelog

- **0.0.2**: Add quotes to schedule expression to avoid errors.
- **0.0.1**: Initial release.