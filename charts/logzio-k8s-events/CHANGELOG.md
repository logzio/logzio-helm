# Changes by Version

<!-- next version -->
## 1.0.1
- Add support for configuring tolerations
## 1.0.0
- **Breaking changes:**
  - Secret values are now global and aligned to prevent duplicate values in the parent chart
    - `secrets.logzioShippingToken` >> `global.logzioLogsToken`
    - `secrets.logzioListener` >> `global.logzioRegion`
    - `secrets.env_id` >> `global.env_id`
    - `secrets.customListener` >> `global.customLogsEndpoint`
  -  K8s secret resource configuration has been renamed from `secrets` >> `secret`
    - `secretName` >> `secret.name`

## 0.0.8
- Upgrade `logzio-k8s-events` to v`0.0.4`
  - Upgrade GoLang version to `v1.23.0`
  - Upgrade `github.com/logzio/logzio-go` to `v1.0.9`
  - Upgrade GoLang docker image to `golang:1.23.0-alpine3.20`

## 0.0.7
- Remove default resources `limits`

## 0.0.6
- Upgrade `logzio-k8s-events` to v0.0.3
  - Upgrade GoLang version to `v1.22.3`
  - Upgrade docker image to `alpine:3.20`
  - Upgrade GoLang docker image to `golang:1.22.3-alpine3.20`

## 0.0.5
- Remove the duplicate label `app.kubernetes.io/managed-by` @philwelz

## 0.0.4
- Enhanced env_id handling to support both numeric and string formats.

## 0.0.3
- Rename listener template.

## 0.0.2
- Ignore internal event changes.

## 0.0.1
- Initial release.
