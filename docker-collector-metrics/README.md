# Docker-collector-metrics

Helm is a tool for managing packages of pre-configured Kubernetes resources using Charts.
With this Helm Chart, you can deploy to your k8s cluster docker-collector-metrics and send your AWS metrics to Logz.io.
For further information on docker-collector-metrics, see the project's [repo](https://github.com/logzio/docker-collector-metrics).


### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed
* Allow outgoing traffic to destination port 5015
* IAM user with the permissions to fetch the right metrics

### Deployment:

#### 1. Add logzio-k8s-logs repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm/docker-collector-metrics
```

#### 2. Deploy

```shell
helm install -n kube-system \
--set secrets.logzioShippingToken="<<SHIPPING-TOKEN>>" \
--set logzioRegion="<<LOGZIO-REGION>>" \
--set awsRegion="<<AWS-REGION>>" \
--set awsNamespaces="{<<AWS-NAMESPACES>>}" \
--set secrets.awsAccessKey="<<AWS-ACCESS-KEY>>" \
--set secrets.awsSecretKey="<<AWS-SECRET-KEY>>" \
--set logzioType="<<LOGZIO-TYPE>>" \
docker-collector-metrics logzio-helm/docker-collector-metrics .
```

Replace the params in the command above with the following values:

| Parameter | Description |
|---|---|
| `<<SHIPPING-TOKEN>>` | [Token](https://app.logz.io/#/dashboard/settings/general) of the logzio account you want to ship to. |
| `<<LOGZIO-REGION>>` | Two-letter region code. This determines your listener URL (where you're shipping the metrics to) and API URL. <br> You can find your region code in the [Regions and URLs](https://docs.logz.io/user-guide/accounts/account-region.html#regions-and-urls) table. |
| `<<AWS-REGION>>`| Your region's slug. You can find this in the AWS region menu (in the top menu, to the right). |
| `<<AWS-NAMESPACES>>` | Comma-separated list of namespaces of the metrics you want to collect. <br> You can find a complete list of namespaces at [_AWS Services That Publish CloudWatch Metrics_](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html). <br> **Please note** that your namespace list is inside the `"{namespaces}"` format, as it appears in the above command. |
| `<<AWS-ACCESS-KEY>>` | Your IAM user's access key ID. |
| `<<AWS-SECRET-KEY>>` | Your IAM user's secret key. |
| `<<LOGZIO-TYPE>>` | (Optional) This field is needed only if you're shipping metrics to Kibana and you want to override the default value (`docker-collector-metrics`). <br> In Kibana, this is shown in the `type` field. Logz.io applies parsing based on `type`. |


For further variables and settings, see the configuration table below.

#### 3. Check Logz.io for your metrics
Give your metrics some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).


### Configuration

| Parameter | Description | Default |
|---|---|---|
| `image` | The docker-collector-metrics Docker image. | `logzio/docker-collector-metrics` |
| `imageTag` | The docker-collector-metrics Docker image tag. | `0.1.5` |
| `apiVersions.serviceAccount` | API version of `serviceaccount.yaml`. | `v1` |
| `apiVersions.clusterRole` | API version of `clusterrole.yaml`. | `rbac.authorization.k8s.io/v1` |
| `apiVersions.clusterRoleBinding` | API version of `clusterrolebinding.yaml`. | `rbac.authorization.k8s.io/v1` |
| `apiVersions.deployment` | API version of `deployment.yaml`. | `apps/v1` |
| `apiVersions.configMap` | API version of `configmap.yaml`. | `v1` |
| `apiVersions.secret` | API version of `secrets.yaml`. | `v1` |
| `apiGroups.clusterRoleBinding` | API groups of `clusterrolebinding.yaml` | `rbac.authorization.k8s.io` |
| `namespace` | Chart's namespace. | `default` |
| `managedServiceAccount` | Specifies whether the serviceAccount should be managed by this helm Chart. Set this to false to manage your own service account and related roles. | `true` |
| `clusterRoleRules` | Configurable [cluster role rules](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole) that Metricbeat uses to access Kubernetes resources. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/docker-collector-metrics/values.yaml) |
| `serviceAccount.create` | Specifies whether a service account should be created. | `true` |
| `serviceAccount.name` | Name of the service account. | `docker-collector-metrics` |
| `fullNameOverride` | Overrides the full name of the resources. | `"docker-collector-metrics` |
| `nameOverride` | Overrides the Chart name for resources. | `''` |
| `terminationGracePeriodSeconds` | Termination period (in seconds) to wait before killing Metricbeat pod process on pod shutdown. | `30` |
| `hostNetwork` | Controls whether the pod may use the node network namespace. | `true` |
| `dnsPolicy` | Specifies pod-specific DNS policies. | `ClusterFirstWithHostNet` |
| `awsRegion` | **Required**. Your AWS region slug. To find it follow the instructions [here](https://github.com/logzio/docker-collector-metrics#region-configuration). | `''` |
| `awsNamespaces` | **Required**. Comma-separated list of namespaces of the metrics you want to collect. <br> You can find a complete list of namespaces at [_AWS Services That Publish CloudWatch Metrics_](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html). <br> **Please note** that your namespace list is inside the `"{namespaces}"` format, as it appears in the above command. | `''` |
| `logzioRegion` | Two-letter region code. This determines your listener URL (where you're shipping the metrics to) and API URL. <br>You can find your region code in the [Regions and URLs](https://docs.logz.io/user-guide/accounts/account-region.html#regions-and-urls) table.| `us` |
| `logzioType` | This field is needed only if you're shipping metrics to Kibana and you want to override the default value. <br> In Kibana, this is shown in the `type` field. Logz.io applies parsing based on `type`. | `docker-collector-metrics` |
| `logzioLogLevel` | The log level the module startup scripts will generate. | `INFO` |
| `logzioExtraDimension` | Semicolon-separated list of dimensions to be included with your metrics (formatted as `dimensionName1=value1;dimensionName2=value2`). To use an environment variable as a value, format as `dimensionName=$ENV_VAR_NAME`. Environment variables must be the only value in the field. If an environment variable can't be resolved, the field is omitted. | `"-"` |
| `debug` | Set to `true` if you want Metricbeat to run in debug mode. <br> **Note:** Debug mode tends to generate a lot of debugging output, so you should probably enable it temporarily only when an error occurs while running the docker-collector in production. | `false` |
| `hostname` | Insert your host name if you want it to appear in the metrics' `host.name`. If no value entered, `host.name` will show the node name. | `"-"` |
| `securityContext.runAsUser` | Configurable [securityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) for the deployment pod execution environment. | `0` |
| `resources` | Allows you to set the resources for docker-collector-metrics deployment. | See [values.yaml](https://github.com/logzio/logzio-helm/blob/master/docker-collector-metrics/values.yaml) |

If you wish to change the default values, specify each parameter using the `--set key=value` argument to `helm install`. For example,

```shell
helm install --namespace=kube-system docker-collector-metrics logzio-helm/docker-collector-metrics \
  --set imageTag=7.7.0 \
  --set terminationGracePeriodSeconds=30
```

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.  
To uninstall the `docker-collector-metrics` deployment:

```shell
helm uninstall --namespace=kube-system docker-collector-metrics
```


## Change log
 - **0.0.1**:
    - Initial release.