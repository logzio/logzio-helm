# Changes by Version

<!-- next version -->
## 3.0.0
- Upgrade `logzio-k8s-events` to `v1.0.0`
  - **Breaking changes:**
    - `metadata.managedFields` is no longer shipped.
    - Masked values are hashed with HMAC-SHA256 (64 hex characters) instead of MD5. Set `MASKING_HASH_KEY` for hashes that stay comparable across restarts.
    - Only a one-line summary of each event is printed to stdout. Set `DEBUG=true` to print the full event.
  - Fix a race that could ship Secret `data` unmasked.
  - Hash the values of sensitive container env vars, including inside the `kubectl.kubernetes.io/last-applied-configuration` annotation.
  - Hash a Secret's `last-applied-configuration` annotation.
  - Mask Secrets deleted while the watch was down.
  - Add `SENSITIVE_ENV_NAMES` to extend the masked env var names.
  - Run the Docker image as a non-root user (UID `10001`).
  - Publish the Docker image with SBOM and provenance attestations.
  - Upgrade `golang.org/x/net` to `v0.62.0`.
  - Shut down gracefully on `SIGTERM`, flushing the remaining logs.
  - Match related workloads in the resource's namespace, and merge the workloads of all subjects of a ClusterRole or ClusterRoleBinding.
  - Fix data races on shared globals.
  - Set `@timestamp` to the time of the event.
  - Batch logs instead of sending each event separately.
  - Upgrade GoLang version to `v1.27.4`, and docker images to `golang:1.27.4-alpine3.24` and `alpine:3.24`.
  - Upgrade `k8s.io/client-go`, `k8s.io/api` and `k8s.io/apimachinery` to `v0.37.2`.
  - Upgrade `github.com/logzio/logzio-go` to `v1.0.10`.
  - Upgrade GitHub Actions, and add `go vet`, race detection and `govulncheck` to CI.
- Add `debug`, `sensitiveEnvNames` and `maskingHashKeySecret` values.
- Add `envVars` to `values.yaml`.
- Fix `envVars` rendering: `valueFrom` entries failed to render, values that aren't strings (e.g. `true` or `5`) failed to render, `false` or `0` values were dropped, and whole numbers rendered in scientific notation (e.g. `1e+06`).

## 2.0.0
- Support global setting for `nodeSelector` and `affinity`.
- **Breaking changes:**
  - Deprecate `nodeArchitectures` setting (can be configured directly under `affinity`).

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
