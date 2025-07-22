# Logz.io Telemetry Filters Migration

This document explains the filtering capabilities in the Logz.io Telemetry Helm chart, which supports both legacy and new filter syntaxes for backward compatibility.
## Overview

The Logz.io Telemetry chart supports two filtering approaches:

1. **New Filters Syntax** (Recommended): Simple, flexible syntax for new deployments
2. **Legacy PrometheusFilters** (Backward Compatible): Complex syntax maintained for existing customers

Both syntaxes can be used together, with filters from both sources being applied to the same pipelines.

### Essential Metric Categories for K8s 360

When creating custom filters, ensure these metric names patterns are **never excluded** from the infrastructure pipeline:

- `kube_pod_*` - Pod status and metadata
- `kube_node_*` - Node information and status  
- `kube_deployment_*` - Deployment status
- `kube_daemonset_*` - DaemonSet status
- `kube_replicaset_*` - ReplicaSet information
- `kube_statefulset_*` - StatefulSet status
- `container_cpu_*` - Container CPU metrics
- `container_memory_*` - Container memory metrics
- `container_network_*` - Container network metrics
- `node_cpu_*` - Node CPU metrics
- `node_memory_*` - Node memory metrics
- `node_filesystem_*` - Node storage metrics
- `node_network_*` - Node network metrics


## New Filters Syntax (Recommended)

The new filters syntax provides a simple, intuitive way to filter Prometheus metrics:

```yaml
filters:
  infrastructure:
    exclude:
      namespace: "kube-system|monitoring"
      attribute:
        deployment: "dev|test"
        service: "internal"
    include:
      attribute:
        deployment: "prod"
  applications:
    exclude:
      name: "go_gc_duration_seconds|http_requests_total"
    include:
      namespace: "prod|staging"
      attribute:
        status_code: "2..|3.."
```

### Syntax Rules

- **Pipeline**: `infrastructure` or `applications`
- **Action**: `include` (keep) or `exclude` (drop)
- **Target**: 
  - `name`: Metric name (maps to `__name__` label)
  - `namespace`: Kubernetes namespace
  - `service`: Service name
  - `attribute.<key>`: Any Prometheus label
- **Values**: Regular expressions (use `|` for OR, `.*` for wildcard)

### ⚠️ Safe Filtering Examples

Here are examples of filtering that **won't break** K8s 360 dashboards:

```yaml
# SAFE: Exclude specific application metrics (non-infrastructure)
filters:
  applications:
    exclude:
      name: "go_gc_duration_seconds|http_requests_total"

# SAFE: Include only specific namespaces for applications
filters:
  applications:
    include:
      namespace: "prod|staging"

# SAFE: Filter by custom application labels
filters:
  applications:
    exclude:
      attribute:
        environment: "dev|test"
```

### ⚠️ Dangerous Filtering Examples

**AVOID these patterns as they can break K8s 360 dashboards:**

```yaml
# DANGEROUS: Don't exclude core kube-state-metrics
filters:
  infrastructure:
    exclude:
      name: "kube_pod_.*|kube_deployment_.*|kube_node_.*" 

# DANGEROUS: Don't exclude essential container metrics
filters:
  infrastructure:
    exclude:
      name: "container_cpu_.*|container_memory_.*"


```

## Legacy PrometheusFilters (Backward Compatible)

The legacy syntax provides complex filtering with cloud provider presets and granular control:

```yaml
prometheusFilters:
  metrics:
    infrastructure:
      keep:
        aks: "metric1|metric2|metric3"  # AKS preset
        eks: "metric1|metric2|metric3"  # EKS preset
        gke: "metric1|metric2|metric3"  # GKE preset
        custom: "custom_metric1|custom_metric2"
      drop:
        custom: "metric_to_drop1|metric_to_drop2"
  
  namespaces:
    infrastructure:
      keep:
        custom: "namespace1|namespace2"
      drop:
        kubeSystem: "kube-system"  # Built-in kube-system exclusion
        custom: "namespace_to_drop"
  
  services:
    infrastructure:
      keep:
        custom: "service1|service2"
      drop:
        kubeDns: "kube-dns"  # Built-in kube-dns exclusion
        custom: "service_to_drop"
```


## Filter Application

Filters are applied to different Prometheus scrape jobs:

### Infrastructure Pipeline
- `prometheus/infrastructure`: Kubernetes service endpoints
- `prometheus/cadvisor`: Container metrics
- `prometheus/kubelet`: Node metrics

### Applications Pipeline
- `prometheus/applications`: Application metrics

## Migration Path

### From Legacy to New Syntax

**Important**: If you're currently using `enableMetricsFilter.aks=true`, `enableMetricsFilter.eks=true`, or `enableMetricsFilter.gke=true`, these flags automatically include the essential K8s 360 metrics. When migrating to the new syntax, you must be careful not to exclude these metrics.

1. **Metrics Filtering**:
   ```yaml
   # Legacy (with built-in K8s 360 protection)
   prometheusFilters:
     metrics:
       infrastructure:
         keep:
           custom: "metric1|metric2"
   
   # New (⚠️ be careful not to exclude essential metrics)
   filters:
     infrastructure:
       include:
         name: "metric1|metric2"
   ```

2. **Namespace Filtering**:
   ```yaml
   # Legacy
   prometheusFilters:
     namespaces:
       infrastructure:
         drop:
           custom: "namespace1|namespace2"
   
   # New (safe for namespaces)
   filters:
     infrastructure:
       exclude:
         namespace: "namespace1|namespace2"
   ```

3. **Service Filtering**:
   ```yaml
   prometheusFilters:
     services:
       infrastructure:
         drop:
           custom: "service1|service2"
   
   filters:
     infrastructure:
       exclude:
         service: "service1|service2"
   ```

### Gradual Migration

**Recommended approach** to avoid breaking K8s 360 dashboards:

1. Keep existing prometheusFilters configuration
2. Add new filters alongside existing configuration for non-essential metrics only
3. Test that K8s 360 dashboards still work correctly
4. Gradually move non-essential rules from prometheusFilters to filters
5. **Never remove** the cloud provider presets (aks/eks/gke) from prometheusFilters without ensuring all essential metrics are preserved in the new syntax
6. Only remove prometheusFilters once you've verified functionality

## Testing

**⚠️ CRITICAL**: Always test your filter configurations to ensure K8s 360 dashboards continue to work after applying filters.

### Testing Steps

1. **Use the provided test file**:
   ```bash
   helm template . -f test-filters.yaml
   ```

This will generate a configuration that demonstrates both filter approaches working together.