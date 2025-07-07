# Changes by Version

<!-- next version -->
## 1.3.0
- Add **trace filtering** capability via the new `filters` values key.
  - Supports `exclude` (drop) and `include` (keep) rules on `namespace`, `service`, any `attribute.*` or `resource.*` fields using regular expressions.
  - Rules are converted into OpenTelemetry `filter` processors and injected right after `k8sattributes` so span/resource metadata is available.
## 1.2.3
- Expose collector metrics port by default 
## 1.2.2
- Add support for auto resource detection with `distribution` and `resourceDetection.enabled` flags.
  - The old `resourcedetection/all` configuration now serves as fallback if `distribution` is empty or with unknown value.
  - **Note:** If you use a custom `resourcedetection` configurations, you can disable the new behavior by setting `resourceDetection.enabled=false` and manually adding the required configuration under `traceConfig`.
- Upgrade OpenTelemetry Collector from `0.119.0` to `0.123.0`

## 1.2.1
- Add support for global tolerations

## 1.2.0
- Resolve issue preventing APM chart deployment on Fargate
- Upgrade OpenTelemetry Collector from `0.117.0` to `0.119.0`

## 1.1.0
- Implement option to override the global Logz.io shipping tokens
- Upgrade OpenTelemetry Collector from `0.116.1` to `0.117.0`

## 1.0.0
- Initial release 
- Kubernetes APM Agent for Logz.io, based on OpenTelemetry Collector
