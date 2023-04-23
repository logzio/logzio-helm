# Cloudwatch Fetcher

With this Helm Chart you can deploy to your K8S cluster the Logz.io's Cloudwatch Fetcher.

The Cloudwatch fetcher allows you to define a time interval to fetch logs from AWS Cloudwatch, and ship them to Logz.io.

Cloudwatch-fetcher's code can be found in the [cloudwatch-fetcher](https://github.com/logzio/cloudwatch-fetcher) Github repo.

## Prerequisites

Before using this tool, you'll need to make sure that you have AWS access keys with permissions to:
* `logs:FilterLogEvents`
* `sts:GetCallerIdentity`


**Note**: This solution can handle one AWS account per container. If you wish to follow multiple accounts, you'll need to create multiple deployments (one deployment per AWS account).


## Standard Deployment

### 1. Add Logz.io's Helm repo:

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

### 2. Create configuration file

Create a configuration file for Cloudwatch fetcher.

**Example:**

```yaml
log_groups:
  - path: '/aws/lambda/my-lambda'
    custom_fields:
      key1: val1
      key2: val2
aws_region: 'us-east-1'
collection_interval: 10
```

| Field                      | Description                                                                                      | Required/Default |
|----------------------------|--------------------------------------------------------------------------------------------------|------------------|
| `log_groups`               | An array of log group configuration                                                              | **Required**     |
| `log_groups.path`          | The AWS Cloudwatch log group you want to tail                                                    | **Required**     |
| `log_groups.custom_fields` | Array of key-value pairs, for adding custom fields to the logs from the log group                | -                |
| `aws_region`               | The AWS region your log groups are in. **Note** that all log groups should be in the same region | **Required**     |
| `collection_interval`      | Interval **IN MINUTES** to fetch logs from Cloudwatch                                            | Default: `5`     |

### 3. Deploy the Chart:

Use the following command, and replace the placeholders with your parameters:

```shell
helm install -n monitoring --create-namespace \                 
--set secrets.logzioShippingToken="<<LOGZIO-LOG-SHIPPING-TOKEN>>" \
--set secrets.logzioListener="<<LOGZIO-LISTENER>>" \
--set secrets.awsAccessKey="<<AWS-ACCESS-KEY>>" \
--set secrets.awsSecretKey="<<AWS-SECRET-KEY>>" \
--set-file fetcherConfig=<<CONFIG-PATH>> \
cloudwatch-fetcher logzio-helm/cloudwatch-fetcher
```

| Parameter | Description |
| --- | --- |
| `<<LOGZIO-LOG-SHIPPING-TOKEN>>` | Your [Logz.io logs shipping token](https://app.logz.io/#/dashboard/settings/general) |
| `<<LOGZIO-LISTENER>>` | Your account's [listener host](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping?product=logs). For example, `listener.logz.io` |
| `<<AWS-ACCESS-KEY>>` | Your AWS access key |
| `<<AWS-SECRET-KEY>>` | Your AWS secret key |
| `<<CONFIG-PATH>>` | Path tho the Cloudwatch Fetcher configuration file you created in the previous step |


### 4. Check Logz.io for your logs

Give your logs some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

**NOTE** that the logs will have the original timestamp from Cloudwatch, so when you're searching for them, make sure that you're viewing the relevant time frame.


## Further Configuration

The above helm install command will deploy a standard configuration version of the Chart.

However, you can modify the Chart by using the --set flag in your helm install command:

| Parameter | Description | Default |
| --- | --- | --- |
| `image` | Container image | `logzio/cloudwatch/fetcher` |
| `imageTag` | Container image tag | `0.0.1` |
| `secrets.enabled` | Specifies whether to create a secret for the deployment | `true` |
| `secrets.name` | Name of the secret | `"logzio-logs-secret-cloudwatch"` |
| `secrets.logzioShippingToken` | Your [Logz.io logs shipping token](https://app.logz.io/#/dashboard/settings/general) | `""`
| `secrets.logzioListener` | Your logz.io [listener url](https://app.logz.io/#/dashboard/settings/manage-tokens/data-shipping?product=logs), for example: `listener.logz.io` | `""` (defaults to us region) |
| `secrets.awsAccessKey` | Your AWS access key | `""` |
| `secrets.awsSecretKey` | Your AWS secret key | `""` |
| `persistentVolume.enabled` | Specifies whether to create a persistent volume and persistent volume claim for this release. Disabling will not allow the fetcher to continue from the last time it ran, in case the pod will be stopped | `true` |
| `persistentVolume.storageClassName` | Storage class name | `"logzio-cloudwatch-fetcher"` |
| `persistentVolume.capacity.storage` | Storage requirement for the PV | `50Mi` |
| `persistentVolume.accessModes` | Access modes for the PV | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/cloudwatch-fetcher/values.yaml) |
| `persistentVolume.resources.requests.storage` | Storage request for the PVC | `30Mi` |
| `loggingConfig` | Configuration for the logging of the fetcher | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/charts/cloudwatch-fetcher/values.yaml) |
| `fetcherConfig` | Configuration for the fetcher | `""` |
| `resetPositionFile` | Delete current position file | `false` |


## Presistent volume

By default, this Helm Chart enables the creation of a Persistent Volume (PV) and a Persisten Volume Claim (PVC). With these resources, the Fetcher saves a position file that allows saving the last time the fetcher extracted logs from Cloudwatch. This is neccessary to prevent data lose in case the pod has stopped. If you choose to disable those resources, or if your cluster does not allow the creation of these resource - some data may be lost in case that the pod will stop.

## Uninstalling the Chart

To uninstall the Cloudwatch Fetcher release:

```shell
helm uninstall -n monitoring cloudwatch-fetcher
```

## Changelog:

- **0.0.1**: Initial release.