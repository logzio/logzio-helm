# Logz.io APM Collector Helm Chart
> [!IMPORTANT]
> Kubernetes APM Collection Agent is still In development

This Helm chart deploys an agent, which leverages the OpenTelemetry Collector, that collects traces and span metrics from Kubernetes clusters and sends them to Logz.io.


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


```shell
helm install -n monitoring --create-namespace \
--set enabled=true \
--set spm.enabled=true \
--set serviceGraph.enabled=true \
--set global.logzioTracesToken="<<LOGZIO_TRACES_TOKEN>>" \
--set global.logzioSpmToken="<<LOGZIO_SPM_TOKEN>>" \
--set global.logzioRegion="<<LOGZIO_REGION_CODE>>" \
--set global.env_id="<<ENV_ID>>" \
logzio-apm-collector logzio-helm/logzio-apm-collector
```

> [!NOTE]
> To disable either one of SPM or Service Graph remove the relevant `--set XXX.enabled` line from the above command.

> [!IMPORTANT]
> Values of `<<LOGZIO_TRACES_TOKEN>>`, `<<LOGZIO_SPM_TOKEN>>` and `<<LOGZIO_REGION_CODE>>` can be found in your Logz.io account.  
> For `<<ENV_ID>>` define any environment identifier attribute (for example, the cluster name).


## Configuration

- [All configuration options](./VALUES.md)
- [Instrumentation](#instrumentation)
- [Custom Trace Sampling rules](#custom-trace-sampling-rules)
- [Enable File Storage extension](#enable-file-storage-extension)


## Instrumentation
If you're using manual instrumentation or an instrumentation agent, configure it to export data to the Logz.io APM collector by setting the export/output address as follows:

```
logzio-apm-collector.monitoring.svc.cluster.local:<<PORT>>
```

> [!IMPORTANT]
> Replace `<<PORT>>` based on the protocol your agent uses:
> - 4317 for GRCP
> - 4318 for HTTP
>
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


## Enable File Storage extension
The [OpenTelemetry File Storage extension](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/storage/filestorage) allows storing temporary data on disk rather than in memory. This helps reduces memory stress, particularly in high-load scenarios, and ensures that state is persisted on disk.

To enable the File Storage extension, follow the below steps:

- **Step 1**: Add the File Storage Extension

Update the `traceConfig` and/or `spmConfig` in `values.yaml` to include the File Storage extension.
Make sure to add your custom configuration under `extensions` section and added to the `service` extensions.
Example:

```yaml
traceConfig:
  ...
  extensions:
    ...
    file_storage:
      directory: /var/lib/otelcol
  ...
  service:
    extensions: [health_check, file_storage]
```

- **Step 2**: Configure Disk Storage Path

Edit the `extraVolumes` and `extraVolumeMounts` in `values.yaml`, to contain the path where the data should be saved on disk.
Ensure this path matches the one set in `extensions.file_storage.directory` in step 1:

```yaml
extraVolumes:
  - name: varlibotelcol
    hostPath:
      path: /var/lib/otelcol  # use the same path as `extensions.file_storage.directory`
      type: DirectoryOrCreate
extraVolumeMounts:
  - name: varlibotelcol
    mountPath: /var/lib/otelcol  # use the same path as `extensions.file_storage.directory`
```


## Uninstalling
To uninstall the `logzio-apm-collector` chart, you can use:
```shell
helm uninstall -n monitoring logzio-apm-collector
```
