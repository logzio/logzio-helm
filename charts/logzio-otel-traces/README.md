
# Logzio-otel-traces

##  Overview

You can use a Helm chart to ship Traces to Logz.io via the OpenTelemetry collector.
The Helm tool is used to manage packages of pre-configured Kubernetes resources that use charts.

**logzio-otel-traces** allows you to ship traces from your Kubernetes cluster to Logz.io with the OpenTelemetry collector.

**Note:** This chart is a fork of the [opentelemtry-collector](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) Helm chart.

#### Standard configuration


##### Deploy the Helm chart
First add `logzio-helm` repo
```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

To deploy the Helm chart, enter the relevant parameters for the placeholders and run the code. 

###### Configure the parameters in the code

Replace the Logz-io `<<traces-token>>` with the [token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping) of the tracing account to which you want to send your data.

Replace `<<logzio-region>>` with the name of your logzio region e.g `us`,`eu`.

###### Run the Helm deployment code

```
helm install  \
--set config.exporters.logzio.region=us \
--set config.exporters.logzio.account_token=McvJQAtOrFUZQRFMrvSqnKSEJhjjFZHz \
logzio-otel-traces logzio-helm/logzio-otel-traces
```

##### Check Logz.io for your traces

Give your traces some time to get from your system to ours, then open [Logz.io](https://app.logz.io/).

## Example usage:
* Go to `hotrod.yml` file inside this directory
* Change the `<<otel-cluster-ip>>` parameter to the cluster-ip address of your opentelemetry collector service.
* Deploy the `hotrod.yml` to your kubernetes cluster (example: `kubectl apply -f hotrod.yml`)
* Access the hotrod pod on port 8080 and start sending traces.

####  Customizing Helm chart parameters

##### Configure customization options

You can use the following options to update the Helm chart parameters: 

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`

* Edit the `values.yaml`

* Overide default values with your own `my_values.yaml` and apply it in the `helm install` command. 

###### Example:

```
helm install logzio-otel-traces logzio-helm/logzio-otel-traces -f my_values.yaml 
```
#### Uninstalling the Chart

The uninstall command is used to remove all the Kubernetes components associated with the chart and to delete the release.  

 To uninstall the `logzio-otel-traces` deployment, use the following command:

```shell
helm uninstall logzio-otel-traces
```
## Change log

* 0.0.1 - Initial realese
