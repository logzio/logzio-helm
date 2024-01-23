# Logz.io forked chart
The `kube-state-metrics` helm chart was forked in order to divide the load of `pods` metrics collection by creating a daemonset with `daemonset.enabled` flag which is enabled by default. 
The rest of the resources metrics will be collected by the deployment pod.

## Disable DaemonSet Pods Metrics Sharding 

```console
helm install logzio-monitoring-kube-state-metrics logzio-helm/kube-state-metrics -n monitoring --set daemonset.enabled=false
```

Un-comment the `pods` metrics in the `collectors` configuraiton.

# kube-state-metrics Helm Chart 

Installs the [kube-state-metrics agent](https://github.com/kubernetes/kube-state-metrics).


## Get Repo Info

```console
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

_See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation._

## Install Chart

```console
helm install -n monitoring --create-namespace \
logzio-monitoring-kube-state-metrics logzio-helm/kube-state-metrics 
```

_See [configuration](#configuration) below._

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Uninstall Chart

```console
helm uninstall logzio-monitoring-kube-state-metrics -n monitoring 
```

This removes all the Kubernetes components associated with the chart and deletes the release.

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

## Upgrading Chart

```console
helm upgrade logzio-monitoring-kube-state-metrics logzio-helm/kube-state-metrics -n monitoring [flags]
```

_See [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) for command documentation._

### Migrating from stable/kube-state-metrics and kubernetes/kube-state-metrics

You can upgrade in-place:

1. [get repo info](#get-repo-info)
1. [upgrade](#upgrading-chart) your existing release name using the new chart repo


## Upgrading to v3.0.0

v3.0.0 includes kube-state-metrics v2.0, see the [changelog](https://github.com/kubernetes/kube-state-metrics/blob/release-2.0/CHANGELOG.md) for major changes on the application-side.

The upgraded chart now the following changes:
* Dropped support for helm v2 (helm v3 or later is required)
* collectors key was renamed to resources
* namespace key was renamed to namespaces


## Configuration

See [Customizing the Chart Before Installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with detailed comments:

```console
helm show values logzio-helm/kube-state-metrics -n monitoring
```

You may also run `helm show values` on this chart's [dependencies](#dependencies) for additional options.
