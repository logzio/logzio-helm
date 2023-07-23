ezkonnect Helm Chart
====================

The EZKonnect Helm chart is designed to simplify the process of instrumenting Kubernetes applications with OpenTelemetry auto-instrumentation and configurable log types. It is designed to work in conjunction with the [logzio-monitoring](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring) Helm chart.

The EZKonnect Helm chart includes three main components:

1.  Kubernetes Instrumentor - Provides auto-instrumentation and log type controller for Kubernetes applications.
2.  EZKonnect Server - A server that handles the comuunication between the user and the Kubernetes instrumentor.
3.  EZKonnect UI - A graphical interface for managing and viewing your instrumentation data.

Supported languages:
- java
- nodejs
- python
- dotnet

Installation
------------

To install the EZKonnect Helm chart, use the following command:

```bash
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
helm install logzio-ezkonnect logzio-helm/ezkonnect -n ezkonnect --create-namespace
``` 

Then use `kubectl port-forward` to accsess the user intefrace in your browser
```
kubectl port-forward svc/ezkonnect-ui -n ezkonnect 31032:31032
```

Go to http://localhost:31032 

Configuration
-------------

The following table lists the configurable parameters of the EZKonnect chart and their default values.
serviceAccount
| Parameter | Description | Default |
| --- | --- | --- |
| `kubernetesInstrumentor.serviceAccount` | Service account name of the instrumentor deployment | `"kubernetes-instrumentor"` |
| `kubernetesInstrumentor.image.repository` | Repository of the instrumentor image | `"logzio/instrumentor"` |
| `kubernetesInstrumentor.image.tag` | Tag of the instrumentor image | `"v1.0.5"` |
| `kubernetesInstrumentor.instrumentationDetectorImage.repository` | Repository of the instrumentation detector image | `"logzio/instrumentation-detector"` |
| `kubernetesInstrumentor.instrumentationDetectorImage.tag` | Tag of the instrumentation detector image | `"v1.0.5"` |
| `kubernetesInstrumentor.javaAgentImage.repository` | Repository of the Java agent image | `"logzio/otel-agent-java"` |
| `kubernetesInstrumentor.javaAgentImage.tag` | Tag of the Java agent image | `"v1.0.5"` |
| `kubernetesInstrumentor.dotnetAgentImage.repository` | Repository of the .Net agent image | `"logzio/otel-agent-dotnet"` |
| `kubernetesInstrumentor.dotnetAgentImage.tag` | Tag of the .Net agent image | `"v1.0.5"` |
| `kubernetesInstrumentor.nodejsAgentImage.repository` | Repository of the Node.js agent image | `"logzio/otel-agent-nodejs"` |
| `kubernetesInstrumentor.nodejsAgentImage.tag` | Tag of the Node.js agent image | `"v1.0.5"` |
| `kubernetesInstrumentor.pythonAgentImage.repository` | Repository of the Python agent image | `"logzio/otel-agent-python"` |
| `kubernetesInstrumentor.pythonAgentImage.tag` | Tag of the Python agent image | `"v1.0.5"` |
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
| `ezkonnectServer.serviceAccount` | Service account name of the instrumentor deployment | `"ezkonnect-server"` |
| `ezkonnectServer.image.repository` | Repository of the server image | `"logzio/ezkonnect-server"` |
| `ezkonnectServer.image.tag` | Tag of the server image | `"v1.0.6"` |
| `ezkonnectServer.ports.http` | HTTP port for the server | `8080` |
| `ezkonnectServer.service.name` | Name of the server service | `"ezkonnect-server"` |
| `ezkonnectServer.service.port` | Service port for the server | `5050` |
| `ezkonnectServer.service.targetPort` | Target port for the server service | `5050` |
| `ezkonnectUi.image.repository` | Repository of the UI image | `"logzio/ezkonnect-ui"` |
| `ezkonnectUi.image.tag` | Tag of the UI image | `"v1.0.0"` |
| `ezkonnectUi.ports.http` | HTTP port for the UI | `31032` |
| `ezkonnectUi.service.name` | Name of the UI service | `"ezkonnect-ui-service"` |
| `ezkonnectUi.service.port` | Service port for the UI | `31032` |
| `ezkonnectUi.service.targetPort` | Target port for the UI service | `31032` |
| `rbac.clusterRoles...` | Configure the RBAC cluster roles | Refer to `values.yaml` |
| `rbac.clusterRoleBindings...` | Configure the RBAC cluster role bindings | Refer to `values.yaml` |

You can override the default values by creating your own `values.yaml` file and passing the `--values` or `-f` option to the Helm command. For example:

`helm install logzio-ezkonnect logzio-helm/ezkonnect -n ezkonnect --create-namespace --values my_values.yaml` 

Here, `my_values.yaml` is your custom configuration file.


Change log
-------------
* 1.0.1
  - New user interface
  - Add `activeServiceName` to crd
  - New images for `ezkonnect-server` & `kubernetes-instrumentor`
* 1.0.0
  - Easily add otel auto instrumentation and log types to your Kubernetes applications