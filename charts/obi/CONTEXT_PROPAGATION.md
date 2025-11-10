# OBI Context Propagation Guide

## Overview

OBI automatically propagates trace context across service boundaries using the W3C Trace Context standard. This guide explains configuration requirements and current limitations.

## How It Works

OBI propagates trace context by:
- Intercepting network traffic at the kernel level via eBPF
- Injecting and extracting `traceparent` headers in HTTP requests


## Known Limitations

### Protocol Support
- ✅ HTTP/1.x: Full support
- ⚠️  gRPC/HTTP/2: Limited support (may result in disconnected traces)
- ⚠️  HTTPS: Context propagation works but with reduced visibility

### Common Issues

**Disconnected Traces**
- Occurs when services use unsupported protocols (gRPC/HTTP/2)
- Workaround: Use service mesh (Istio, Linkerd) or manual instrumentation

**Invalid Parent Span References**
- Happens when context propagates partially
- Verify all required capabilities are granted

## Use Cases

### HTTP/REST Microservices
Best for HTTP/1.x REST APIs. Full trace propagation across services.

```yaml
hostNetwork: true
network:
  enabled: true
config:
  ebpf:
    context_propagation: 'all'
```

### Mixed Protocol Environments
For applications using both HTTP and gRPC:
- HTTP/1.x traces will connect properly
- gRPC traces may be disconnected

## Troubleshooting

### Check OBI Status
```bash
kubectl logs -n <namespace> -l app.kubernetes.io/name=obi
kubectl describe pod -n <namespace> -l app.kubernetes.io/name=obi
```

### Verify Configuration
- Ensure `hostNetwork: true` is set
- Confirm `network.enabled: true`
- Check `context_propagation: 'all'` in config
- Verify all required capabilities are granted

### Trace Issues
If traces show gaps or invalid parent spans:
1. Check OBI logs for errors
2. Verify protocol compatibility (HTTP/1.x vs gRPC)

## References
- [OBI Distributed Traces Documentation](https://opentelemetry.io/docs/zero-code/obi/distributed-traces/)
- [Context Propagation Specification](https://www.w3.org/TR/trace-context/)

