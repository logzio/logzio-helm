# Logzio Otel Operator

## Overview

The Helm chart installs [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) in Kubernetes cluster.
The OpenTelemetry Operator is an implementation of a [Kubernetes Operator](https://www.openshift.com/learn/topics/operators).
At this point, it has [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) as the only managed component.

## logzio-otel-operator

Allows you to use open telemetry auto instrumentation so you can easly send traces from your kubernetes cluster.

## Prerequisites

- Kubernetes 1.19+ is required for OpenTelemetry Operator installation
- Helm 3.0+
- TLS certificate

### TLS Certificate Requirement

In Kubernetes, in order for the API server to communicate with the webhook component, the webhook requires a TLS
certificate that the API server is configured to trust. There are three ways for you to generate the required TLS certificate.

  - The easiest and default method is to install the [cert-manager](https://cert-manager.io/docs/) and set `opentelemetry-operator.admissionWebhooks.certManager.enabled` to `true`.
    In this way, cert-manager will generate a self-signed certificate. _See [cert-manager installation](https://cert-manager.io/docs/installation/kubernetes/) for more details._
  - You can also provide your own Issuer by configuring the `opentelemetry-operator.admissionWebhooks.certManager.issuerRef` value. You will need
    to specify the `kind` (Issuer or ClusterIssuer) and the `name`. Note that this method also requires the installation of cert-manager.
  - The last way is to manually modify the secret where the TLS certificate is stored. Make sure you set `opentelemetry-operator.admissionWebhooks.certManager.enabled` to `false` first.
    - Create the namespace for the OpenTelemetry Operator and the secret
      ```console
      $ kubectl create namespace opentelemetry-operator-system
      ```
    - Config the TLS certificate using `kubectl create` command
      ```console
      $ kubectl create secret tls opentelemetry-operator-controller-manager-service-cert \
          --cert=path/to/cert/file \
          --key=path/to/key/file \
          -n opentelemetry-operator-system
      ```
      You can also do this by applying the secret configuration.
      ```console
      $ kubectl apply -f - <<EOF
      apiVersion: v1
      kind: Secret
      metadata:
        name: opentelemetry-operator-controller-manager-service-cert
        namespace: opentelemetry-operator-system
      type: kubernetes.io/tls
      data:
        tls.crt: |
            # your signed cert
        tls.key: |
            # your private key
      EOF
      ```

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
--set collector.config.exporters.logzio.region=<<logzio-region>> \
--set collector.config.exporters.logzio.account_token=<<traces-token>> \
logzio-otel-operator logzio-helm/logzio-otel-operator --wait
```

The ```--wait``` flag is mandatory for this chart to run properly.

## Uninstall Chart

The following command uninstalls the chart whose release name is my-opentelemetry-operator.

```console
$ helm uninstall my-opentelemetry-operator
```

This will remove all the Kubernetes components associated with the chart and deletes the release, excluding the opentelemetry collector and instrumentation CR, which can be removed with the following command:

```console
$ kubectl delete otelinst opentelemetry-operator-instrumentation  \
  && kubectl delete opentelemetrycollector otel-collector 

```

The OpenTelemetry Collector CRD created by this chart won't be removed by default and should be manually deleted:

```console
$ kubectl delete crd opentelemetrycollectors.opentelemetry.io
```

## Upgrade Chart

```console
$ helm upgrade logzio-otel-operator logzio-helm/logzio-otel-operator
```

Please note that by default, the chart will be upgraded to the latest version. If you want to upgrade to a specific version,
use `--version` flag.

With Helm v3.0, CRDs created by this chart are not updated by default and should be manually updated.

After the chart is successfully deployed, we can inject auto instrumentation to kubernetes components:

## Injecting auto instrumentation

Instrumentation can be injected using pod annotations:

Java:
```
instrumentation.opentelemetry.io/inject-java: "true"
```

NodeJS:
```
instrumentation.opentelemetry.io/inject-nodejs: "true"
```

Python:
```
instrumentation.opentelemetry.io/inject-python: "true"
```

The possible values for the annotation:

```"true"``` - inject and Instrumentation resource from the namespace.

```"my-instrumentation"``` - name of Instrumentation CR instance in the current namespace.

```"my-other-namespace/my-instrumentation"``` - name and namespace of Instrumentation CR instance in another namespace.

```"false"``` - do not inject

Namespaces injection:
```
kubectl annotate namespace my-namespace instrumentation.opentelemetry.io/inject-java="true"
```

Pod with multi container injection:
```
annotations:
  instrumentation.opentelemetry.io/inject-java: "true"
  instrumentation.opentelemetry.io/container-names: "myapp,myapp2"
```

## Opentelemetry collector deployment modes

The opentelemetry collector supports multiple modes of deployment.
In this chart we use the 'deployment' method as the default.
For additional information about the other methods (daemonset, sidecar, statefulset), please visit:
[OpenTelemetry Operator Helm Chart](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-operator)
