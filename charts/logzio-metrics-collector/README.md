# logzio-metrics-collector

Kubernetes metrics collection agent for Logz.io based on OpenTelemetry Collector.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.9+

Below is the extended README.md, the full configuration table based on the provided `values.yaml` is in [VALUES.md](VALUES.md) file, release updates posted in the [CHANGELOG.md](CHANGELOG.md) file.


* * *

Logz.io Metrics Collector for Kubernetes
========================================

The `logzio-metrics-collector` Helm chart deploys a Kubernetes metrics collection agent designed to forward metrics from Kubernetes clusters to Logz.io. This solution leverages the OpenTelemetry Collector, providing a robust and flexible way to manage metric data, ensuring that your monitoring infrastructure scales with your application needs.

It's pre-configured to send metrics to Logz.io, simplifying setup and integration. It also populates data for prebuilt content in the Logz.io platform. 

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
    helm install logzio-metrics-collector -n monitoring --create-namespace \
    --set enabled=true \
    --set secrets.logzioMetricsToken="<<METRICS-SHIPPING-TOKEN>>" \
    --set secrets.logzioRegion="<<LOGZIO-REGION>>" \
    --set secrets.env_id="<<ENV-ID>>" \
    logzio-helm/logzio-metrics-collector
    ```

    Replace:
    * `logzio-metrics-collector` with your release name
    * `<<METRICS-SHIPPING-TOKEN>>` with your Logz.io metrics shipping token
    * `<<LOGZIO-REGION>>` with your Logz.io [account region code](https://docs.logz.io/docs/user-guide/admin/hosting-regions/account-region/)
    * `<<ENV-ID>>` with a unique name assigned to your environment's identifier, to differentiate telemetry data across various environments

    
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

### Deploy metrics chart with Kuberenetes object logs correlation

**Note**: `k8sObjectsLogs.enabled=true` will have no effect unless `enabled` is also set to `true`

```
helm install logzio-metrics-collector -n monitoring --create-namespace \
--set enabled=true \
--set k8sObjectsLogs.enabled=true \
--set secrets.k8sObjectsLogsToken="<<LOGS-SHIPPING-TOKEN>>"\
--set secrets.logzioMetricsToken="<<METRICS-SHIPPING-TOKEN>>" \
--set secrets.logzioRegion="<<LOGZIO-REGION>>" \
--set secrets.env_id="<<ENV_ID>>" \
logzio-helm/logzio-metrics-collector 
```
    
Replace:
* `logzio-metrics-collector` with your release name
* `<<METRICS-SHIPPING-TOKEN>>` with your Logz.io metrics shipping token
* `<<LOGS-SHIPPING-TOKEN>>` with your Logz.io logs shipping token
* `<<LOGZIO-REGION>>` with your Logz.io [account region code](https://docs.logz.io/docs/user-guide/admin/hosting-regions/account-region/)
* `<<ENV-ID>>` with a unique name assigned to your environment's identifier, to differentiate telemetry data across various environments


### For clusters with Windows Nodes


To extract and scrape metrics from Windows Nodes, a Windows Exporter service must be installed on the node host. This installation is accomplished by authenticating with a username and password via an SSH connection to the node through a job.

By default, the Windows installer job will execute upon deployment and subsequently every 10 minutes, retaining the most recent failed and successful pods.
You can modify these settings in the `values.yaml` file:

```
windowsExporterInstallerJob:
  interval: "*/10 * * * *"           #In CronJob format
  concurrencyPolicy: Forbid          # Future cronjob will run only after current job is finished
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
```

The default username for Windows Node pools is: `azureuser`. (This username and password are shared across all Windows node pools.)

You can change the password for your Windows node pools in the AKS cluster using the following command (this will only affect Windows node pools):

```
    az aks update \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --windows-admin-password $NEW_PW
```

You can read more information at https://docs.microsoft.com/en-us/azure/aks/windows-faq,
under `How do I change the administrator password for Windows Server nodes on my cluster?` section.


###### Run the Helm deployment code for clusters with Windows Nodes:

    ```
    helm install logzio-metrics-collector -n monitoring --create-namespace \
    --set enabled=true \
    --set secrets.windowsNodeUsername="<<WINDOWS-NODE-USERNAME>" \
    --set secrets.windowsNodePassword="<<WINDOWS-NODE-PASSWORD>>" \
    --set secrets.logzioMetricsToken="<<METRICS-SHIPPING-TOKEN>>" \
    --set secrets.logzioRegion="<<LOGZIO-REGION>>" \
    --set secrets.env_id="<<ENV_ID>>" \
    logzio-helm/logzio-metrics-collector
    ```
    Replace:
    * `logzio-metrics-collector` with your release name
    * `<<METRICS-SHIPPING-TOKEN>>` with your Logz.io metrics shipping token
    * `<<LOGZIO-REGION>>` with your Logz.io [account region code](https://docs.logz.io/docs/user-guide/admin/hosting-regions/account-region/)
    * `<<ENV-ID>>` with a unique name assigned to your environment's identifier, to differentiate telemetry data across various environments
    * `<<WINDOWS-NODE-USERNAME>>` with the username for the Node pool you want the Windows exporter to be installed on.
    * `<<WINDOWS-NODE-PASSWORD>>` with the password for the Node pool you want the Windows exporter to be installed on.


### Handling image pull rate limit
In some cases (i.e spot clusters) where the pods/nodes are replaced frequently, the pull rate limit for images pulled from dockerhub might be reached, with an error:
`You have reached your pull rate limit. You may increase the limit by authenticating and upgrading: https://www.docker.com/increase-rate-limits`.
In these cases we can use the following `--set` commands to use an alternative image repository:

```shell
--set image.repository=ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib
```
