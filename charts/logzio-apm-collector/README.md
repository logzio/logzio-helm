# Logz.io APM Collector Helm Chart
> [!IMPORTANT]
> Kubernetes APM Collection Agent is still In development

This Helm chart deploys an agent, which leverages the OpenTelemetry Collector, that collects traces and span metrics from Kubernetes clusters and sends them to Logz.io

## Prerequisites
- Kubernetes 1.24+
- Helm 3.9+

## Installation
### Add Logz.io Helm Repository
Before installing the chart, add the Logz.io Helm repository:
```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

### Install the Chart

The chart provides options for enabling the following:
1. Traces
2. SPM (Service Performance Monitoring)
3. Service Graph 
4. OpenTelemetry Operator (Auto-instrumentation)


```shell
helm install -n monitoring --create-namespace \
--set enabled=true \
--set spm.enabled=true \
--set serviceGraph.enabled=true \
--set otel-operator.enabled=true \
--set secrets.logzioTracesToken="<<LOGZIO_TRACES_TOKEN>>" \
--set secrets.logzioSpmToken="<<LOGZIO_SPM_TOKEN>>" \
--set secrets.logzioRegion="<<LOGZIO_REGION_CODE>>" \
--set secrets.env_id="<<ENV_ID>>" \
logzio-apm-collector logzio-helm/logzio-apm-collector
```

> [!NOTE]
> To disable either one of SPM, Service Graph or OpenTelemetry Operator, remove the relevant `--set XXX.enabled` line from the above command.

> [!IMPORTANT]
> Values of `<<LOGZIO_TRACES_TOKEN>>`, `<<LOGZIO_SPM_TOKEN>>` and `<<LOGZIO_REGION_CODE>>` can be found in your Logz.io account.  
> For `<<ENV_ID>>` define any environment identifier attribute (for example, the cluster name).


## Configuration

- [All configuration options](./VALUES.md)
- [Enable Auto-instrumentation](#enable-auto-instrumentation)
  - [Multi-container pods](#multi-container-pods)
- [Customize Auto-instrumentation](#customize-auto-instrumentation)
  - [Customize Propagator](#customize-propagator)
  - [Add a custom Sampler](#add-a-custom-sampler)
  - [Distribute namespaces](#distribute-namespaces)
- [Manual Instrumentation](#manual-instrumentation)
- [Custom Trace Sampling rules](#custom-trace-sampling-rules)

## Enable Auto-instrumentation
- **Step 1:** Make sure to enable the OpenTelemetry operator in the chart:
```shell
--set otel-operator.enabled=true \
```

- **Step 2**: Add annotations to your relevant Kubernetes object (Deployment, StatefulSet, Namespace, Daemonset, or Pod)
```yaml
instrumentation.opentelemetry.io/inject-<APP_LANGUAGE>": "monitoring/logzio-apm-collector"
```

> [!TIP]
> `<APP_LANGUAGE>` can be one of `apache-httpd`, `dotnet`, `go`, `java`, `nginx`, `nodejs` or `python`.


### Multi-container pods
By default, in multi-container pods, instrumentation is performed on the first container available in the pod spec.
To fine tune which containers to instrument, add the below annotations to your pod:
```yaml
instrumentation.opentelemetry.io/inject-<APP_LANGUAGE>": "monitoring/logzio-apm-collector"
instrumentation.opentelemetry.io/<APP_LANGUAGE>-container-names: "myapp,myapp2"
instrumentation.opentelemetry.io/inject-<APP_LANGUAGE_2>": "monitoring/logzio-apm-collector"
instrumentation.opentelemetry.io/<APP_LANGUAGE_2>-container-names: "myapp3"
```

> [!TIP]
> `<APP_LANGUAGE>`, `<APP_LANGUAGE_2>` can be one of `apache-httpd`, `dotnet`, `go`, `java`, `nginx`, `nodejs` or `python`.


## Customize Auto-instrumentation
Below you can find multiple ways in which you can customize the OpenTelemetry Operator Auto-instrumentation.

### Customize Propagator
The propagator specifies how context is injected into and extracted from carriers for distributed tracing.
By default, the propagators `tracecontext` (W3C Trace Context) and `baggage` (W3C Correlation Context) are enabled.
You can customize this to include other formats ([full list here](https://opentelemetry.io/docs/languages/sdk-configuration/general/#otel_propagators)) or set it to "none" to disable automatic propagation.
```shell
--set instrumentation.propagator={tracecontext, baggage, b3}
```

### Add a custom Sampler
You can specify a sampler to be used by the instrumentor. You'll need to specify the below:
- Sampler used to sample the traces ([available options](https://opentelemetry.io/docs/languages/sdk-configuration/general/#otel_traces_sampler))
- Sampler arguments ([Sampler type expected input](https://opentelemetry.io/docs/languages/sdk-configuration/general/#otel_traces_sampler_arg))

Example:
```shell
--set instrumentation.sampler.type="parentbased_always_on" \
--set instrumentation.sampler.argument="0.25"
```

### Distribute namespaces
For intensive applications, to reduce the performance impact of the operator, you can define multiple namespaces to deploy the instrumentor resource at, which can help distribute the load in larger clusters.
To do so, specify which namespaces to deploy the instrumentor at: 
```shell
--set includeNamespaces="ns1,ns2,ns3"
```

For resources in the namespaces where you configured the instrumentation, you need to add annotation in this format:
```yaml
instrumentation.opentelemetry.io/inject-<APP_LANGUAGE>": "true"
```

> [!TIP]
> `<APP_LANGUAGE>` can be one of `apache-httpd`, `dotnet`, `go`, `java`, `nginx`, `nodejs` or `python`.

## Manual Instrumentation
If you're using manual instrumentation or a custom instrumentation agent, configure it to export data to the Logz.io APM collector by setting the export/output address as follows:

```
logzio-monitoring-otel-collector.monitoring.svc.cluster.local:<<PORT>>
```

> [!IMPORTANT]
> Replace `<<PORT>>` based on the protocol your agent uses:
> - 4317 for GRCP
> - 4318 for HTTP
> For a complete list, see `values.yaml` >> `traceConfig` >> `receivers`.

## Custom trace sampling rules
To customize the Traces Sampling rules in the OpenTelemetry Collector, you can follow the below steps:

- **Step 1**: Create [customized Tail sampling rules configuration](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/tailsamplingprocessor).

- **Step 2**: Update the `values.yaml` file:

Get the current Chart's `values.yaml` file:
```shell
helm get values logzio-apm-collector -n monitoring > new-values.yaml
```

Edit the section under `traceConfig` >> `processors` >> `tail_sampling` in `new-values.yaml` to contain the custom config which you created in step 1.

- **Step 3**: Apply the config:
```shell
helm upgrade logzio-apm-collector logzio-helm/logzio-apm-collector -n monitoring -f new-values.yaml
```

## Uninstalling
To uninstall the `logzio-apm-collector` chart, you can use:
```shell
helm uninstall -n monitoring logzio-apm-collector
```
