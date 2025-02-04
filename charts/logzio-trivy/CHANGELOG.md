# Changes by Version

<!-- next version -->

## 1.0.0
- **Breaking changes**
    - Secret values are now global and aligned to prevent duplicate values in the parent chart
      - `secrets.logzioShippingToken` >> `global.logzioLogsToken`
      - `secrets.logzioListener` >> `global.logzioRegion`
      - `env_id` >> `global.env_id`
    - K8s secret resource configuration has been renamed from `secrets` >> `secret`

## 0.3.6
- Fix `tolerations` value 

## 0.3.5
- Added `affinity` ,`nodeSelector` and `tolerations` to the deployment.

## 0.3.4
- Bump Trivy-Operator version to `0.24.1`.

## 0.3.3
- Upgrade to image `logzio/trivy-to-logzio:0.3.3`.
    - Upgrade python version to 3.12.5.
    - Re-build image to include the latest version of git(CVE-2024-32002).
- Bump Trivy-Operator version to `0.24.0`.

## 0.3.2
- Added 'user-agent' header for telemetry data.

## 0.3.0
- Bump Trivy-Operator version to `0.15.1`.

## 0.2.1
- Default to disable unused reports (config audit, rbac assessment, infra assessment, cluster compliance).
- Bump Trivy-Operator version to `0.13.1`.
- Bump logzio-trivy version to `0.2.1`.

## 0.2.0
- Upgrade to image `logzio/trivy-to-logzio:0.2.0`:
    - Watch for new reports, in addition to daily scan.

## 0.1.0
- Upgrade to image `logzio/trivy-to-logzio:0.1.0`.
- **Breaking changes**:
    - Deprecation of CronJob, using Deployment instead.
    - Scanning for reports will occur once upon container deployment, then once a day at the scheduled time. 
    - Not using cron expressions anymore. Instead, set a time for the daily run in form of HH:MM. 

## 0.0.2
- Add quotes to schedule expression to avoid errors. 

## 0.0.1
- Initial release.
