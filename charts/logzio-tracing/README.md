# Logzio-tracing

Logzio-tracing allows you to ship traces from your Kubernetes cluster to Logz.io.
The chart will deploy tracing agents and/or collector (depends on the brand)

### Prerequisites:
* [Helm CLI](https://helm.sh/docs/intro/install/) installed

You can choose your tracing agent and collector brand between:
* OpenTelemetry (otel)
* Jaeger

#### 1. Add logzio-tracing repo to your helm repo list

```shell
helm repo add logzio-helm https://logzio.github.io/logzio-helm/logzio-tracing
```

#### 2. Deploy

Replace `<<TRACES-TOKEN>>` with the [token](https://app.logz.io/#/dashboard/settings/general) of the account you want to ship to.

Replace `<<LISTENER-REGION>>` with your region’s code (for example, `eu`), defaults to `us`. For more information on finding your account’s region, see [Account region](https://docs.logz.io/user-guide/accounts/account-region.html).

```shell
helm install \
--set=Secrets.TracesToken=VVFGWdpOVBNNluWlDFUDhnbDRDODOxZP \
--set=Configs.Region=<<LISTENER-REGION>> \
k8s-tracing logzio-tracing

```


### Configuration

| Parameter | Description | Default |
|---|---|---|
| `Secrets.TracesToken` | Secret with your [logzio traces token](https://app.logz.io/#/dashboard/settings/general) |  `""` |
| `Configs.Region` | Your [logzio region](https://docs.logz.io/user-guide/accounts/account-region.html). Defaults to US East.|  `"us"` |
| `Configs.AgentBrand` | Which agent brand to use. Either `otel` or `jaeger`, choosing `otel` will not deploy a collector as well since OpenTelemetry's agents functions also as collectors. |  `"otel"` |
| `Configs.CollectorBrand` | Which collector brand to use. Either `otel` or `jaeger` |  `"otel"` |
| `Configs.LogLevel` | Log level of the collector and agents to emit. One of `DEBUG`, `INFO`, `WARN` or `ERROR`|  `"INFO"` |
| `Jaeger.Agent.Image` | The Jaeger agent docker image. |  `jaegertracing/jaeger-agent:1.18.0` |
| `Jaeger.Agent.Port` | The Jaeger agent port|  `6831` |
| `Jaeger.Collector.Image` | The Jaeger collector docker image|  `logzio/jaeger-logzio-collector:latest` |
| `Jaeger.Collector.Ports.ZipkingReceiver` | Jaeger collector Zipkin receiver port|  `9411` |
| `Jaeger.Collector.Ports.JaegerReceiverGrpc` | Jaeger collector GRPC receiver port| `14250` | 
| `Otel.Collector.Image` | OpenTelemetry collector docker image|  `otel/opentelemetry-collector-contrib:0.17.0` |
| `Otel.Collector.Ports.ZipkingReceiver` | OpenTelemetry collector Zipkin receiver port |  `9411` |
| `Otel.Collector.Ports.JaegerReceiverHttp` | OpenTelemetry collector HTTP receiver port|  `14268` |
| `Otel.Collector.Ports.JaegerReceiverGrpc` | OpenTelemetry collector GRPC receiver port| `14250` |


If you wish to change the default values, specify each parameter using the `--set key=value` argument to `helm install`.

### Uninstalling the Chart

The command removes all the k8s components associated with the chart and deletes the release.  
To uninstall the `logzio-k8s-logs` deployment:

```shell
helm uninstall --namespace=kube-system logzio-tracing
```


## Change log
 - **0.0.1**:
    - Initial release.
