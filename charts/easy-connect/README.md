easy-connect Helm Chart
====================

The easy-connect Helm chart is designed to simplify the process of instrumenting Kubernetes applications with OpenTelemetry auto-instrumentation and configurable log types. It is designed to work in conjunction with the [logzio-monitoring](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring) Helm chart.

The easy-connect Helm chart includes three main components:

1.  Kubernetes Instrumentor - Provides auto-instrumentation and log type controller for Kubernetes applications.
2.  easy-connect Server - A server that handles the comuunication between the user and the Kubernetes instrumentor.
3.  easy-connect UI - A graphical interface for managing and viewing your instrumentation data.

Supported languages:
- java
- nodejs
- python
- dotnet

Before you start you will need:
------------
- Opentelemetry collector installed on your cluster
  - works out of the box with [logzio-monitoring](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring) chart installed with traces and logs enabled (version `0.5.8` or higher for log_type)
  - to send the data to a custom collector change the `kubernetesInstrumentor.env.monitoringServiceEndpoint` value


Installation
------------

To install the easy-connect Helm chart, use the following command:

```bash
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
helm install logzio-easy-connect logzio-helm/easy-connect -n monitoring --create-namespace
``` 

Then use `kubectl port-forward` to accsess the user intefrace in your browser
```
kubectl port-forward svc/easy-connect-ui -n monitoring 31032:31032
```

Go to http://localhost:31032 

Configuration
-------------

The following table lists the configurable parameters of the easy-connect chart and their default values.
serviceAccount
| Parameter | Description | Default |
| --- | --- | --- |
| `kubernetesInstrumentor.serviceAccount` | Service account name of the instrumentor deployment | `"kubernetes-instrumentor"` |
| `kubernetesInstrumentor.image.repository` | Repository of the instrumentor image | `"logzio/instrumentor"` |
| `kubernetesInstrumentor.image.tag` | Tag of the instrumentor image | `"v1.0.9"` |
| `kubernetesInstrumentor.instrumentationDetectorImage.repository` | Repository of the instrumentation detector image | `"logzio/instrumentation-detector"` |
| `kubernetesInstrumentor.instrumentationDetectorImage.tag` | Tag of the instrumentation detector image | `"v1.0.8"` |
| `kubernetesInstrumentor.javaAgentImage.repository` | Repository of the Java agent image | `"logzio/otel-agent-java"` |
| `kubernetesInstrumentor.javaAgentImage.tag` | Tag of the Java agent image | `"v1.0.9"` |
| `kubernetesInstrumentor.dotnetAgentImage.repository` | Repository of the .Net agent image | `"logzio/otel-agent-dotnet"` |
| `kubernetesInstrumentor.dotnetAgentImage.tag` | Tag of the .Net agent image | `"v1.0.9"` |
| `kubernetesInstrumentor.nodejsAgentImage.repository` | Repository of the Node.js agent image | `"logzio/otel-agent-nodejs"` |
| `kubernetesInstrumentor.nodejsAgentImage.tag` | Tag of the Node.js agent image | `"v1.0.9"` |
| `kubernetesInstrumentor.pythonAgentImage.repository` | Repository of the Python agent image | `"logzio/otel-agent-python"` |
| `kubernetesInstrumentor.pythonAgentImage.tag` | Tag of the Python agent image | `"v1.0.9"` |
| `kubernetesInstrumentor.deleteDetectionPods` | Delete detection pods after detection | `true` |
| `kubernetesInstrumentor.ports.metricsPort` | Metrics port for the instrumentor | `8080` |
| `kubernetesInstrumentor.ports.healthProbePort` | Health probe port for the instrumentor | `8081` |
| `kubernetesInstrumentor.resources.limits.cpu` | CPU limit for the instrumentor | `"500m"` |
| `kubernetesInstrumentor.resources.limits.memory` | Memory limit for the instrumentor | `"128Mi"` |
| `kubernetesInstrumentor.resources.requests.cpu` | CPU request for the instrumentor | `"10m"` |
| `kubernetesInstrumentor.resources.requests.memory` | Memory request for the instrumentor | `"64Mi"` |
| `kubernetesInstrumentor.env.monitoringServiceEndpoint` | Endpoint of the monitoring service | `"logzio-monitoring-otel-collector.monitoring.svc.cluster.local"` |
| `kubernetesInstrumentor.service.name` | Name of the instrumentor service | `"kubernetes-instrumentor-service"` |
| `kubernetesInstrumentor.service.port` | Service port for the instrumentor | `8080` |
| `kubernetesInstrumentor.service.targetPort` | Target port for the instrumentor service | `8080` |
| `easyConnectServer.serviceAccount` | Service account name of the instrumentor deployment | `"easy-connect-server"` |
| `easyConnectServer.image.repository` | Repository of the server image | `"logzio/easy-connect-server"` |
| `easyConnectServer.image.tag` | Tag of the server image | `"v1.0.7"` |
| `easyConnectServer.ports.http` | HTTP port for the server | `8080` |
| `easyConnectServer.service.name` | Name of the server service | `"easy-connect-server"` |
| `easyConnectServer.service.port` | Service port for the server | `5050` |
| `easyConnectServer.service.targetPort` | Target port for the server service | `5050` |
| `easyConnectUi.image.repository` | Repository of the UI image | `"logzio/easy-connect-ui"` |
| `easyConnectUi.image.tag` | Tag of the UI image | `"v1.0.0"` |
| `easyConnectUi.ports.http` | HTTP port for the UI | `31032` |
| `easyConnectUi.service.name` | Name of the UI service | `"easy-connect-ui"` |
| `easyConnectUi.service.port` | Service port for the UI | `31032` |
| `easyConnectUi.service.targetPort` | Target port for the UI service | `31032` |
| `rbac.clusterRoles...` | Configure the RBAC cluster roles | Refer to `values.yaml` |
| `rbac.clusterRoleBindings...` | Configure the RBAC cluster role bindings | Refer to `values.yaml` |

You can override the default values by creating your own `values.yaml` file and passing the `--values` or `-f` option to the Helm command. For example:

`helm install logzio-easy-connect logzio-helm/easy-connect -n easy-connect --create-namespace --values my_values.yaml` 

Here, `my_values.yaml` is your custom configuration file.

Manual actions
-------------
The `logzio-instrumetor` microservice can be deployed to your cluster to discover applications, inject opentelemetry instrumentation, add log types and more. You can manually control the discovery process with annotations.
- `logz.io/traces_instrument = true` - will instrument the application with opentelemetry
- `logz.io/traces_instrument = rollback` - will delete the opentelemetry instrumentation
- `logz.io/service-name = <string>` - will set active service name for your opentelemetry instrumentation
- `logz.io/application_type = <string>` - will set log type to send to logz.io (**dependent on logz.io fluentd helm chart**)
- `logz.io/skip = true` - will skip the application from instrumentation or app detection

Alternative images
-------------
you can find alternative to `dockerhub` images in `public.ecr.aws/logzio/` with the same image name (example: `public.ecr.aws/logzio/instrumentor`)

Change log
-------------
* 1.0.5
  - Add `deleteDetectionPods` value
  - Add `easy.conect.version` resource attributes to spans
  - Enrich detection pod logs
  - Add easy connect instrumentation detection
  - Reduce the amount of instrumentor logs
  - Handle conflicts from different reconciles gracefully
  - Update `nodejs` agent
* 1.0.4
  - add images to `public.aws.ecr`
  - Update `dotnet` agent:
    - use `otlp` exporter instead of `zipkin`
    - upgrade version `v0.5.0` -> `v1.2.0`
    - Add env variables: 
      - `OTEL_EXPORTER_OTLP_PROTOCOL`
      - `DOTNET_STARTUP_HOOKS` 
      - `OTEL_METRICS_EXPORTER`
      - `OTEL_LOGS_EXPORTER`
      - `OTEL_EXPORTER_OTLP_PROTOCOL`
      - `OTEL_DOTNET_AUTO_HOME`
      - `OTEL_RESOURCE_ATTRIBUTES`
  - update `python` agent:
    - update deps
* 1.0.3
  - Refactor `ezkonnect` -> `easy-connect`
* 1.0.2
  - Update `instrumentor` image version `v1.0.5` -> `v1.0.6`
* 1.0.1
  - New user interface
  - Add `activeServiceName` to crd
  - New images for `ezkonnect-server` & `kubernetes-instrumentor`
* 1.0.0
  - Easily add otel auto instrumentation and log types to your Kubernetes applications