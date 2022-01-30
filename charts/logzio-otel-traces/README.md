
# Logzio-otel-traces

##  Overview

You can use a Helm chart to ship Traces to Logz.io via the OpenTelemetry collector.
The Helm tool is used to manage packages of pre-configured Kubernetes resources that use charts.

**logzio-otel-traces** allows you to ship traces from your Kubernetes cluster to Logz.io with the OpenTelemetry collector.

**Note:** This chart is a fork of the [opentelemtry-collector](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) Helm chart.

#### Standard configuration


##### Deploy the Helm chart

Add `logzio-helm` repo as follows:

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

##### Configure the parameters in the code

Replace the Logz-io `<<traces-token>>` with the [token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping?product=tracing) of the tracing account to which you want to send your data.

Replace `<<logzio-region>>` with the name of your Logz.io region e.g `us`,`eu`.

##### Run the Helm deployment code

```
helm install  \
--set config.exporters.logzio.region=<<logzio-region>> \
--set config.exporters.logzio.account_token=<<traces-token>> \
logzio-otel-traces logzio-helm/logzio-otel-traces
```

##### Check Logz.io for your traces

Give your traces some time to get from your system to ours, then open [Logz.io](https://app.logz.io/).

## Example usage

* Go to `hotrod.yml` file inside this directory.
* Change the `<<otel-cluster-ip>>` parameter to the cluster-ip address of your opentelemetry collector **service** on port `14268`
* Deploy the `hotrod.yml` to your kubernetes cluster (example: `kubectl apply -f hotrod.yml`).
* Access the hotrod pod on port 8080 and start sending traces.

####  Customizing Helm chart parameters

##### Configure customization options

You can use the following options to update the Helm chart parameters: 

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`.

* Edit the `values.yaml`.

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

## Sending logs from nodes with taints

If you want to ship logs from any of the nodes that have a taint, make sure that the taint key values are listed in your in your daemonset/deployment configuration as follows:

```yaml
tolerations:
- key: 
  operator: 
  value: 
  effect: 
```

To determine if a node uses taints as well as to display the taint keys, run:

```sh
kubectl get nodes -o json | jq ".items[]|{name:.metadata.name, taints:.spec.taints}"
```

## Change log

* 0.0.2 - 
  <ul>
  <li>Updated otel version to 0.42</li>
  <li>Updated otlp http port</li>
  <li>update memory limiter script</li>
  </ul>

* 0.0.1 - Initial realese

