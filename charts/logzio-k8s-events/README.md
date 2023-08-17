# Logz.io Kubernetes Events

Helm is a tool for managing packages of pre-configured Kubernetes resources using Charts.
Logzio-K8S-Events helm chart allows you to deploy a daemonset that will ship deployment event logs from your Kubernetes cluster to Logz.io.


**Note**: This chart is for shipping Kubernetes deployment event logs only. For a chart that ships all telemetry (logs, metrics, traces, spm) - use our [Logzio Monitoring chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring).


### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed
* Allow outgoing traffic to destination port 8071


**Note:** Helm 2 will reach [EOL on November 2020](https://helm.sh/blog/2019-10-22-helm-2150-released/#:~:text=6%20months%20after%20Helm%203's,Helm%202%20will%20formally%20end). This document follows the command syntax recommended for Helm 3, but the Chart will work with both Helm 2 and Helm 3. 


<div id="standard-config">

### Configuration deployment:

#### 1. Add logzio-helm repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

#### 2. Deploy

Replace `<<SHIPPING-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-HOST>>` with your region’s host address (for example, `listener-eu.logz.io`). For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

Replace `<<ENV-ID>>` with your environment name.

```shell
helm install --namespace=kube-system \
--set secrets.logzioShippingToken='<<SHIPPING-TOKEN>>' \
--set secrets.logzioListener='<<LISTENER-HOST>>' \
--set secrets.envID='<<ENV-ID>>' \
logzio-k8s-events logzio-helm/logzio-k8s-events
```

#### 3. Check Logz.io for your logs
Give your logs some time to get from your system to ours, and then open [Logz.io](https://app.logz.io/).

</div>

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.
To uninstall the `logzio-k8s-events` deployment:

```shell
helm uninstall --namespace=kube-system logzio-k8s-events
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
 - **0.0.1**:
    - Initial release.
