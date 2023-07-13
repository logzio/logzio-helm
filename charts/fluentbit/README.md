# Logz.io FluentBit Helm Chart

##  Overview

You can use this Helm chart to ship Kubernetes logs to Logz.io with fluentbit.
This chart is based on the [fluent-bit](https://github.com/fluent/helm-charts/tree/main/charts/fluent-bit) Helm chart. 

**Note**: This chart is for shipping logs only. For a chart that ships all telemetry (logs, metrics, traces, spm) - use our [Logzio Monitoring chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring).

#### Standard configuration

##### Deploy the Helm chart
First add `logzio-helm` repo
```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```
To deploy the Helm chart, enter the relevant parameters for the placeholders and run the code. 

###### Configure the parameters in the code

Replace the Logz-io `<<LOGZIO_TOKEN>>` (required) with the [token](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping) of the metrics account to which you want to send your data.

Replace `<<LISTENER_HOST>>` (optional) with your region’s listener host (for example, `listener.logz.io`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html). The default value is `listener.logz.io`

Replace `<<LOG_TYPE>>`(optional) with the name for the desired log type, the default value is `fluentbit`.

###### Run the Helm deployment code

```shell
helm install  \
--set logzio.token=<<LOGZIO_TOKEN>> \
--set logzio.listenerHost=<<LISTENER_HOST>> \
--set logzio.logType=<<LOG_TYPE>> \
logzio-fluent-bit logzio-helm/logzio-fluent-bit
```


##### Check Logz.io for your logs

Give your logs some time to get from your system to ours, then open [Logz.io](https://app.logz.io/).


####  Customizing Helm chart parameters


##### Configure customization options

You can use the following options to update the Helm chart parameters: 

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`

* Edit the `values.yaml`

* Overide default values with your own `my_values.yaml` and apply it in the `helm install` command. 

###### Example:

```
helm install logzio-fluent-bit logzio-helm/logzio-fluent-bit -f my_values.yaml 
```

To modify fluentbit configuration edit the `config` section in `values.yaml`.
#### Uninstalling the Chart

The uninstall command is used to remove all the Kubernetes components associated with the chart and to delete the release.  

To uninstall the `logzio-fluent-bit` deployment, use the following command:

```shell
helm uninstall logzio-fluent-bit
```

#### Sending logs using HTTP Proxy server

If you want to ship logs and route them through a Proxy HTTP server please set the following Helm chart parameters:

Replace the parameter `<<PROXY_HOST>>` with your HTTP Proxy server host address. # `<<IP_OR_HOST>>:<<PORT>>`

If you'd like to use basic authentication please replace the parameter `<<PROXY_USERNAME>>` (optional) with the Proxy server username and replace the parameter `<<PROXY_PASSWORD>>` (optional) with the user's password.


**Note that HTTPS is not currently supported. It is recommended not to set this and to configure the [HTTP_PROXY environment variables](https://docs.fluentbit.io/manual/administration/http-proxy) instead as they support both HTTP and HTTPS.** 


###### Run the Helm deployment code with Proxy configuration
```sh
helm install  \
--set logzio.token=<<LOGZIO_TOKEN>> \
--set logzio.listenerHost=<<LISTENER_HOST>> \
--set logzio.logType=<<LOG_TYPE>> \
--set logzio.proxyHost=<<PROXY_HOST>> \
--set logzio.proxyUser=<<PROXY_USERNAME>> \
--set logzio.proxyPass=<<PROXY_PASSWORD>> \
logzio-fluent-bit logzio-helm/logzio-fluent-bit
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
* 0.0.5 - Upgrade docker image to 0.4.0, adding HTTP proxy support in Logzio Output config.
* 0.0.4 - Upgrade docker image to 0.3.0, adding dedot filter in Logzio Output config, added memory and cpu requirements.
* 0.0.3 - Upgrade docker image to 0.1.3.
* 0.0.2 - Upgrade docker image to v0.1.2.
* 0.0.1 - Initial realese
