
# Logzio-cloudwatch-exporter

##  Overview

Use this Helm chart to ship AWS cloudwatch metrics to Logz.io via the OpenTelemetry collector.
The Helm tool is used to manage packages of pre-configured Kubernetes resources that use charts.

**Note:** This chart is a fork of the [prometheus-cloudwatch-exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-cloudwatch-exporter) Helm chart. 
It is also dependent on the [opentelemtry-collector](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector) chart, which is installed by default. 
To disable the dependency during installation, set `openTelemtryCollector.enabled` to `false`.

#### Standard configuration

##### Deploy the Helm chart

To deploy the Helm chart, enter the relevant parameters for the placeholders and run the code. 

###### Configure the parameters in the code

| Helm value | Description |
|---|---|
| `PROMETHEUS-METRICS-SHIPPING-TOKEN` (Required)| Token for shipping metrics to your Logz.io account. Find it under Settings > Manage accounts. [_How do I look up my Metrics account token?_](/user-guide/accounts/finding-your-metrics-account-token/) |
| `LISTENER-HOST` (Required)| Your region’s listener host (for example, `https://listener.logz.io:8053`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html). |
| `AWS-NAMESPACES` (Required) | Comma-separated list of namespaces of the metrics you want to collect. You can find a complete list of namespaces at [_AWS Services That Publish CloudWatch Metrics_](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html). for example: `EC2,RDS` |
| `ENV-TAG` | The value of the `p8s_logzio_name` external label. This variable identifies which Prometheus environment the metrics arriving at Logz.io came from. Default = `logzio-cloudwatch-metrics`.  |
| `AWS-REGION` (Required)| Your AWS cloudwatch region. Default = `us-east-1` |
| `AWS-ACCESS-KEY` (Required)| Your IAM user's access key ID. |
| `AWS-SECRET-KEY` (Required)| Your IAM user's secret key. |

###### Run the Helm deployment code

```
helm install  \
--set logzio-otel-k8s-metrics.secrets.MetricsToken=<<PROMETHEUS-METRICS-SHIPPING-TOKEN>> \
--set logzio-otel-k8s-metrics.secrets.ListenerHost=<<LISTENER-HOST>> \
--set logzio-otel-k8s-metrics.secrets.p8s_logzio_name=<<ENV-TAG>> \
--set aws.aws_access_key_id=<<AWS-ACCESS-KEY>> \
--set aws.aws_secret_access_key=<<AWS-SECRET-KEY>> \
--set config.aws_region=<<AWS-REGION>> \
--set "config.namespaces={<<AWS-NAMESPACES>>}" \
logzio-cloudwatch-exporter logzio-helm/logzio-cloudwatch-exporter
```

##### Check Logz.io for your metrics

Give your metrics some time to get from your system to ours, then open [Logz.io](https://app.logz.io/).


####  Customizing Helm chart parameters


##### Configure customization options

You can use the following options to update the Helm chart parameters: 

* Specify parameters using the `--set key=value[,key=value]` argument to `helm install`

* Edit the `values.yaml`

* Overide default values with your own `my_values.yaml` and apply it in the `helm install` command. 

###### Example:

```
helm install logzio-cloudwatch-exporter logzio-helm/logzio-cloudwatch-exporter -f my_values.yaml 
```

##### Customize the metrics collected by the Helm chart 

You can use a custom cloudwatch exporter configration by adding inline yaml to the `custom_config` section. For example:
```yaml
custom_config: |-
  region: eu-west-1
  period_seconds: 240
  metrics:
  - aws_namespace: AWS/ELB
    aws_metric_name: HealthyHostCount
    aws_dimensions: [AvailabilityZone, LoadBalancerName]
    aws_statistics: [Average]
  - aws_namespace: AWS/ELB
    aws_metric_name: UnHealthyHostCount
    aws_dimensions: [AvailabilityZone, LoadBalancerName]
    aws_statistics: [Average]
```
To learn more about cloudwatch exporter configuration you can refer to the [documantation](https://github.com/prometheus/cloudwatch_exporter#configuration)

#### Uninstalling the Chart

The uninstall command is used to remove all the Kubernetes components associated with the chart and to delete the release.  

To uninstall the `logzio-cloudwatch-exporter` deployment, use the following command:

```shell
helm uninstall logzio-cloudwatch-exporter
```


## Change log

* 0.1.0 - Initial realese
