# Changes by Version

<!-- next version -->
## 2.3.0
- Support global setting for `nodeSelector` and `affinity`.
  - Upgrade `otel/opentelemetry-collector-contrib` image to version `0.133.0`.

## 2.2.1
- Add SignalFx logs support
## 2.2.0
- Introduce advanced **log filtering** support via the new `filters` values key.
  - Users can now `exclude` (drop) or `include` (keep) logs based on `namespace`, `service`, or any `resource.*` / `attribute.*` fields using regular expressions.
  - The chart automatically converts the rules into [OpenTelemetry filter processors](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/filterprocessor) and injects them **immediately after** the `k8sattributes` processor so Kubernetes metadata is available for matching.

## 2.1.0
- **Breaking changes**
  - Upgrade `otel/opentelemetry-collector-contrib` image to version `0.127.0`
    - The `time` attribute is no longer present as field in the log record. The log timestamp is now only available under `@timestamp` in Logz.io.

## 2.0.2
- Add support for auto resource detection with `distribution` and `resourceDetection.enabled` flags.

## 2.0.1
- Add support for global tolerations

## 2.0.0
- **Breaking changes**
    - Secret values are now global
      - `secrets.secretParam` >> `global.secretParam` to prevent duplicate values in the parent chart
      - Update `secrets.customEndpoint` >> `global.customLogsEndpoint` to avoid conflicts with other charts
    - K8s secret resource configuration has been renamed from `secrets` >> `secret`
- Upgrade `otel/opentelemetry-collector-contrib` image to `v.0.109.0`

## 1.1.0
- Simplified user experience for independently managing logzio secrets.
    - Remove requirment to set environment variables in the pods independently.
    - Provided instructions in `values.yaml` regarding the process.

## 1.0.9
- **EKS fargate Breaking changes**:
    - Add `nest` filters to remove dots from kubernetes metadata keys.
    Changes in fields names:
    - `kubernetes.*` -> `kubernetes_*`
    - `kubernetes.labels.*` -> `kubernetes_labels_*`
    - `kubernetes.annotations.*` -> `kubernetes_annotations_*`

## 1.0.8
- Bug-fix:
    - Remove comment from `_helpers.tpl` template that breaks aws-logging configmap

## 1.0.7
- Upgrade `otel/opentelemetry-collector-contrib` image to v0.107.0
    - Adjusted health check extension endpoint
  - In case `json_parser` fails, send the log anyway and print the error only in debug mode.

## 1.0.6
- Added `varlogcontainers` volume and volume mounts
- Added new `container` operator instead of complex operator sequence
- Remove default resources `limits`
- Add default resources `requests`

## 1.0.5
- Upgrade `otel/opentelemetry-collector-contrib` image to `v0.103.0`

## 1.0.4
- Add standalone deployment mode
- Rename `LogzioRegion` to camelCase - `logzioRegion`
- Add user-agent header

## 1.0.3
- Replace dots (".") with underscores ("_") in log attributes keys:
    - Added `transform/dedot` proccesor. 
    - Edited `k8sattributes`, `transform/log_type`, `transform/log_level` proccesors.

## 1.0.2
- Change template function name `baseConfig` -> `baseLoggingConfig` to avoid conflicts with other charts deployed
- Refactor tempaltes function names `opentelemetry-collector` -> `logs-collector` to avoid conflicts with other charts templates

## 1.0.1
- Update multiline parsing
- Update error detection in logs
- Change default log type
- Enhanced env_id handling to support both numeric and string formats.

## 1.0.0
- kubernetes logs collection agent for logz.io based on opentelemetry collector
