# Changes by Version

<!-- next version -->

## 1.0.1
- Upgrade docker image to `1.5.6`.
  - Upgrade ARM and AMD fluentd image version to `v1.18.0-debian-logzio-amd64-1.3` and `v1.18.0-debian-logzio-arm64-1.3`

## 1.0.0
- **Breaking changes**
  - Secret values are now global to prevent duplicate values in the parent chart
    - `logzioShippingToken` >> `global.logzioLogsToken`
    - `logzioListener` >> `global.logzioRegion`
    - `env_id` >> `global.env_id`
  -  K8s secret resource configuration has been renamed from `secrets` >> `secret`
    - `secretName` >> `secret.name`

## 0.30.6
- Upgrade fluentd version to `1.18.0`

## 0.30.5
- Upgrade fluentd version to `1.17.1`

## 0.30.4
- Fix `nodeSelector` indentation

## 0.30.3
- Resolve `nodeSelector` bug

## 0.30.2
- Remove default resources `limits`

## 0.30.1
- Handle empty etcd `log` key, populated based on `message` key.

## 0.30.0
- Upgrade fluentd version to `1.16.5`
- Fix bug of `env-id.conf`

<details>
  <summary markdown="span"> Expand to check old versions </summary>

## 0.29.2
- Enhanced env_id handling to support both numeric and string formats.

## 0.29.1
- Added `enabled` value, to conditianly control the deployment of this chart by a parent chart.
- Added `daemonset.LogFileRefreshInterval` and `windowsDaemonset.LogFileRefreshInterval` values, to control list of watched log files refresh interval.

## 0.29.0
- EKS Fargate logging:
  - Send logs to port `8070` in logzio listener (instead of port `5050`)

## 0.28.1
- Added `windowsDaemonset.enabled` customization.

## 0.28.0
- Added `daemonset.initContainerSecurityContext` customization.
- Added `daemonset.updateStrategy` customization.

## 0.27.0
- Added `daemonset.podSecurityContext`, `daemonset.securityContext` customization.

## 0.26.0
- Bump docker image to `1.5.1`.
- Add ability to configure pos file for containers logs.

## 0.25.0
- Add parameter `isPrivileged` to allow running Daemonset with priviliged security context.
- **Bug fix**: Fix template for `fluentd.serviceAccount`, and fix use of template in service account.

## 0.24.0
- Add parameter `configmap.customFilterAfter` that allows adding filters AFTER built-in filter configuration.
- Added `daemonset.init.containerImage` customization.
- Added fluentd image for windows server 2022.

## 0.23.0
- Allow filtering logs by log level with `logLevelFilter`.

## 0.22.0
- Add custom endpoint option with `secrets.customEndpoint`.

## 0.21.0
- Bump docker image to `1.5.0`:
  - Upgrade fluentd to `1.16`.
  - Upgrade gem `fluent-plugin-logzio` to `0.2.2`:
    - Do not retry on 400 and 401. For 400 - try to fix log and resend.
    - Generate a metric (`logzio_status_codes`) for response codes from Logz.io.

## 0.20.3
- ezKonnect support: Added `logz.io/application_type` to type annotation check .

## 0.20.2
- Upgrade docker image `logzio/logzio-fluentd` to `1.4.0`:
  - Use fluentd's retry instead of retry in code (raise exception on non-2xx response).

## 0.20.1
- Added log level detection for fargate log router
- Remove `namespace` value, replaced by `Realese.namespace` in all templates

## 0.20.0
- Upgraded windows image to `logzio/windows:0.0.2`:
  - Added prometheus monitor plugin
  - Added dedot plugin
  - Updated `windowsDaemonset.fluentdPrometheusConf` - now controls prometheus config for collecting and exposing fluentd metrics.

## 0.19.0
- Upgraded image to `logzio/logzio-fluentd:1.3.1`:
  - Added prometheus monitor plugin
    - Updated `daemonset.fluentdPrometheusConf` - now controls prometheus config for collecting and exposing fluentd metrics.

## 0.18.0
- Added log_level detection for "warn" level.

## 0.17.0
- Add `secrets.enabled` to control secret creation and management. ([#194](https://github.com/logzio/logzio-helm/pull/194))

## 0.16.0
- Increased memory request and limit to 500Mi, cpu request to 200m.

## 0.15.0
- Added dedot processor - auto replace `.` in log field to `_`.

## 0.14.0
- Fix typo in `fargateLogRouter`

## 0.13.0
- Removal of field `log_type`. Auto populating `type` instead.

## 0.12.0
- Added auto detection for log_level field.

## 0.11.0
- Upgrade image `logzio/logzio-fluentd:1.2.0`:
  - Upgrade to `fluentd 1.15`.
  - Upgrade plugin `fluent-plugin-kubernetes_metadata_filter` to `3.1.2`.

## 0.10.0
- Added an option to parse `log_type` annotation into `log_type` field.

## 0.9.0
- Added a default value for `env_id` field.

## 0.8.0
- Add ability to add environment id with `env_id` field.

## 0.7.0
- Add ability to change the secret name with `secretName`. [#133](https://github.com/logzio/logzio-helm/pull/133)

## 0.6.1
- Fix bug for `extraConfig` ([#114](https://github.com/logzio/logzio-helm/issues/114)).

## 0.6.0
- Added `daemonset.priorityClassName` and `windowsDaemonset.priorityClassName`.

## 0.5.0
- Add support for `daemonset.affinity` value.
- Add support for fargate logging.

## 0.4.1
- Upgrade default image version to `logzio/logzio-fluentd:1.1.1`.

## 0.4.0
- Allow dynamically set the log type for the logs.

## 0.3.0
- Added new value fields: `daemonset.excludeFluentdPath`, `daemonset.extraExclude`, `daemonset.containersPath`, `configmap.customSources`, `configmap.customFilters`.
- Added support for windows containers.

## 0.2.0
- Added `daemonset.nodeSelector`.

## 0.1.0
- Upgrade default image version to `logzio/logzio-fluentd:1.0.2` which also supports ARM architecture.
- Deprecated variables: `daemonset.containerdRuntime`, `configmap.kubernetesContainerd`.
- Added `configmap.partialDocker`, `configmap.partialContainerd` that concatenate logs that split due to large size (over 16k). To learn more go to the [configuration table](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd#configuration).
- Added `daemonset.cri` to match the partial log config to the cluster's CRI. To learn more go to the [configuration table](https://github.com/logzio/logzio-helm/tree/master/charts/fluentd#configuration).

## 0.0.4
- Refactor configmaps

## 0.0.3
- Edit configmap template name

## 0.0.2
- Fix templates name - allow dyncmically change it.

## 0.0.1
- Initial release.

</details>
