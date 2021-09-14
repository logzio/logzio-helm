
# Logzio fluentbit helm chart

##  Overview

You can use this Helm chart to ship Kubernetes logs to Logz.io with fluentbit.


**Note:** This chart is based on the [fluent-bit](https://github.com/fluent/helm-charts/tree/main/charts/fluent-bit) Helm chart. 
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


## Change log

* 0.0.1 - Initial realese
