# logzio-metrics-collector

**In development**

Kubernetes metrics collection agent for Logz.io based on OpenTelemetry Collector.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.9+

Below is the extended README.md, the full configuration table based on the provided `values.yaml` is in [VALUES.md](VALUES.md) file, release updates posted in the [CHANGELOG.md](CHANGELOG.md) file.

* * *

Logz.io Metrics Collector for Kubernetes
========================================

The `logzio-metrics-collector` Helm chart deploys a Kubernetes metrics collection agent designed to forward metrics from Kubernetes clusters to Logz.io. This solution leverages the OpenTelemetry Collector, providing a robust and flexible way to manage metric data, ensuring that your monitoring infrastructure scales with your application needs.

Features
--------

*   **Easy Integration with Logz.io**: Pre-configured to send metrics to Logz.io, simplifying setup and integration.
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
    
    Install `logzio-metrics-collector` from the Logz.io Helm repository, specifying the authentication values:

    ```
    helm install logzio-metrics-collector -n monitoring \
    --set enabled=true \
    --set secrets.logzioMetricsToken=<<token>> \
    --set secrets.logzioRegion=<<region>> \
    --set secrets.env_id=<<env_id>> \
    logzio-helm/logzio-metrics-collector
    ```

    Replace:
    * `logzio-metrics-collector` with your release name
    * `<<token>>` with your Logz.io metrics shipping token
    * `<<region>>` with your Logz.io [account region code](https://docs.logz.io/docs/user-guide/admin/hosting-regions/account-region/)
    * `<<env_id>>` with a unique name assigned to your environment's identifier, to differentiate telemetry data across various environments

    
### Uninstalling the Chart

To uninstall/delete the `logzio-metrics-collector` deployment:

```shell
helm delete -n monitoring logzio-metrics-collector
```

### Configure customization options

You can use the following options to update the Helm chart values [parameters](VALUES.md): 

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`

* Edit the `values.yaml`

* Overide default values with your own `my_values.yaml` and apply it in the `helm install` command. 