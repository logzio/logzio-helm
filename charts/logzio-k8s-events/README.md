# Logz.io Kubernetes Events

Helm is a tool for managing packages of pre-configured Kubernetes resources using Charts.
Logzio-K8S-Events helm chart allows you to deploy a daemonset that will ship deployment event logs from your Kubernetes cluster to Logz.io.


**Note**: This chart is specifically for shipping Kubernetes deployment event logs only. For a chart that handles all telemetry data—including logs, metrics, traces, and SPM—please use our [Logzio Monitoring chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring).


### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed
* Allow outgoing traffic to destination port 8071


### Configuration deployment:

#### 1. Add logzio-helm repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

#### 2. Deploy

Replace `<<SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-HOST>>` with your region’s host address (for example, `listener-eu.logz.io`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

Replace `<<ENV-ID>>` with your Kubernetes cluster name.

```shell
helm install --namespace=monitoring \
--set secrets.logzioShippingToken='<<SHIPPING-TOKEN>>' \
--set secrets.logzioListener='<<LISTENER-HOST>>' \
--set secrets.env_id='<<ENV-ID>>' \
logzio-k8s-events logzio-helm/logzio-k8s-events
```

#### 3. Check Logz.io for your logs
Give your logs some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).


#### Optional Custom Listener
If you have an HTTP/s endpoint that receives JSON input than you can override the Logz.io listener by setting the `customListener` secret. 

Replace `<<CUSTOM-HOST>>` with your endpoint URL. 

```shell
helm install --namespace=monitoring \
--set secrets.logzioShippingToken='<<SHIPPING-TOKEN>>' \
--set secrets.customListener='<<CUSTOM-HOST>>' \
--set secrets.env_id='<<ENV-ID>>' \
logzio-k8s-events logzio-helm/logzio-k8s-events
```

#### Deployment Events Versioning

To add a versioning indicator to our K8S 360 and Service Overview UI, you must include the specified annotation in the metadata of each resource whose versioning you wish to track. The 'View commit' button will link to the commit URL in your version control system (VCS) from the `logzio/commit_url` annotation value.

```yaml
metadata:
  annotations:
    logzio/commit_url: ""  
```

##### GitHub VCS Example 

Commit URL structure: `https://github.com/<account>/<repository>/commit/<commit-hash>`
   - Example: `https://github.com/logzio/logzio-k8s-events/commit/069c75c95caeca58dd0776405bb8dfb4eed3acb2`

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.
To uninstall the `logzio-k8s-events` deployment:

```shell
helm uninstall --namespace=monitoring logzio-k8s-events
```

## Sending logs from nodes with taints

If you want to ship logs from any of the nodes that have a taint, make sure that the taint key values are listed in your in your daemonset configuration as follows:

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
 - **0.0.6**:
   - Upgrade `logzio-k8s-events` to v0.0.3
      - Upgrade GoLang version to `v1.22.3`
      - Upgrade docker image to `alpine:3.20`
      - Upgrade GoLang docker image to `golang:1.22.3-alpine3.20`
 - **0.0.5**:
    - Remove the duplicate label `app.kubernetes.io/managed-by` @philwelz
 - **0.0.4**:
    - Enhanced env_id handling to support both numeric and string formats.
 - **0.0.3**:
    - Rename listener template.
 - **0.0.2**:
    - Ignore internal event changes.
 - **0.0.1**:
    - Initial release.
