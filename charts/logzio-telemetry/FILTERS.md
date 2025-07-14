# Logz.io Telemetry Filters Migration

This document explains the filtering capabilities in the Logz.io Telemetry Helm chart, which supports both legacy and new filter syntaxes for backward compatibility.

## Overview

The Logz.io Telemetry chart supports two filtering approaches:

1. **New Filters Syntax** (Recommended): Simple, flexible syntax for new deployments
2. **Legacy PrometheusFilters** (Backward Compatible): Complex syntax maintained for existing customers

Both syntaxes can be used together, with filters from both sources being applied to the same pipelines.

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

### Examples

```yaml
# Exclude specific metrics
filters:
  infrastructure:
    exclude:
      name: "go_gc_duration_seconds|http_requests_total"

# Include only specific namespaces
filters:
  applications:
    include:
      namespace: "prod|staging"

# Filter by custom labels
filters:
  infrastructure:
    exclude:
      attribute:
        deployment: "dev|test"
        service: "internal"
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

### Legacy Filter Flags

Enable specific legacy filter features:

```yaml
enableMetricsFilter:
  aks: true      # Enable AKS metrics preset
  eks: true      # Enable EKS metrics preset
  gke: true      # Enable GKE metrics preset
  dropKubeSystem: true  # Enable kube-system namespace exclusion

disableKubeDnsScraping: true  # Enable kube-dns service exclusion
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

1. **Metrics Filtering**:
   ```yaml
   # Legacy
   prometheusFilters:
     metrics:
       infrastructure:
         keep:
           custom: "metric1|metric2"
   
   # New
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
   
   # New
   filters:
     infrastructure:
       exclude:
         namespace: "namespace1|namespace2"
   ```

3. **Service Filtering**:
   ```yaml
   # Legacy
   prometheusFilters:
     services:
       infrastructure:
         drop:
           custom: "service1|service2"
   
   # New
   filters:
     infrastructure:
       exclude:
         service: "service1|service2"
   ```

### Gradual Migration

You can migrate gradually by:

1. Adding new filters alongside existing prometheusFilters
2. Testing that both work correctly
3. Gradually moving rules from prometheusFilters to filters
4. Removing prometheusFilters once migration is complete

## Testing

Use the provided `test-filters.yaml` file to test both filter syntaxes:

```bash
helm template . -f test-filters.yaml
```

This will generate a configuration that demonstrates both filter approaches working together.
