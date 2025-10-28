# OBI - OpenTelemetry eBPF Instrumentation

OpenTelemetry eBPF Instrumentation (OBI) provides zero-code auto-instrumentation for Kubernetes applications using eBPF technology. It automatically captures HTTP/S requests, gRPC calls, database queries, and optionally network flow metrics without requiring code changes or application restarts.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Linux kernel 5.8+ (for full eBPF support)
- Privileged security context with specific capabilities
- Container runtime: containerd, CRI-O, or Docker

## Installation

### Add Logz.io Helm Repository
```bash
helm repo add logzio-helm https://logzio.github.io/logzio-helm
helm repo update
```

### Install the chart along with logzio-monitoring
```bash
helm install -n monitoring --create-namespace \
--set enabled=true \
--set traces.endpoint="http://logzio-apm-collector.monitoring.svc:4317" \
--set metrics.endpoint="http://logzio-monitoring-otel-collector.monitoring.svc:4317" \
obi logzio-helm/obi
```

### Install the chart for direct otlp export tp logz.io
```bash
helm install -n monitoring --create-namespace \
--set enabled=true \
--set traces.endpoint="https://otlp-listener.logz.io" \
--set traces.token="token" \
--set metrics.endpoint="https://otlp-listener.logz.io" \
--set metrics.token="token" \
obi logzio-helm/obi
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `enabled` | Enable OBI deployment | `false` |
| `traces.endpoint` | OTLP endpoint for traces | `""` |
| `traces.token` | Authentication token for traces | `""` |
| `metrics.endpoint` | OTLP endpoint for metrics | `""` |
| `metrics.token` | Authentication token for metrics | `""` |
| `network.enabled` | Enable network flow metrics | `false` |
| `image.repository` | OBI container image | `otel/ebpf-instrument` |
| `image.tag` | OBI container image tag | `main` |
| `config` | OBI configuration file | `multiple` |

###  Direct otlp export authentication
Configure authentication tokens for OTLP endpoints:

```yaml
traces:
  endpoint: "https://otlp-listener.logz.io"
  token: "your-traces-token-here"
metrics:
  endpoint: "https://otlp-listener.logz.io"
  token: "your-metrics-token-here"
```

### Service Discovery
By default, OBI instruments all applications in all namespaces. Customize via `config.discovery`:

```yaml
config:
  discovery:
    instrument:
      - k8s_namespace: "production"
    exclude_instrument:
      - k8s_namespace: "kube-system"
```

### Network Flow Metrics
Enable network observability (requires `CAP_NET_ADMIN`):

```yaml
network:
  enabled: true
```

## Troubleshooting

### Check OBI Status
```bash
kubectl logs -n <namespace> -l app.kubernetes.io/name=obi
kubectl get configmap -n <namespace> obi -o yaml
```


## Uninstalling
```bash
helm uninstall -n monitoring obi
```

## Documentation
- [OBI Official Documentation](https://opentelemetry.io/docs/zero-code/obi/)
- [Configuration Options](https://opentelemetry.io/docs/zero-code/obi/configure/options/)
- [Service Discovery](https://opentelemetry.io/docs/zero-code/obi/configure/service-discovery/)

