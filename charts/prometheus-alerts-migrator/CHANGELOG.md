# Changes by Version

<!-- next version -->
## v3.0.2
- Upgrade `logzio/prometheus-alerts-migrator` image `v1.3.1`->`v1.3.2`:
  - Fix folder name to not get truncated when name is longer than 40 characters.
## v3.0.1
- Upgrade `logzio/prometheus-alerts-migrator` image `v1.3.0`->`v1.3.1`:
  - Enforce a 40-character limit on the auto-generated Grafana folder UIDs to prevent runtime exceptions when the generated UID is too long.
## v3.0.0
- Upgrade `logzio/prometheus-alerts-migrator` image `v1.2.1`->`v1.3.0`:
  - Upgrade to Grafana 10 API
    - Remove support for `MSTeamsConfigs` (`msteams_configs`) due to deprecation in Grafana 10.
  - Upgrade GoLang version to 1.24
  - Upgrade dependencies
    - `logzio_terraform_client`: `1.22.0` -> `v1.23.2`
    - `prometheus/alertmanager`: `v0.28.0` -> `v0.28.1`
    - `prometheus/common`: `v0.61.0` -> `v0.62.0`
    - `prometheus/prometheus`: `v0.301.0` -> `v0.302.1`
    - `k8s.io/api`: `v0.32.0` -> `v0.32.2`
    - `k8s.io/apimachinery`: `v0.32.0` -> `v0.32.2`
    - `k8s.io/client-go`: `v0.32.0` -> `v0.32.2`
## v2.1.1
- Upgrade `logzio/prometheus-alerts-migrator` image `v1.2.0`->`v1.2.1`:
  - Add support for MS Teams v2 contact points
  - Update `prometheus/alertmanager`: `v0.27.0` -> `v0.28.0`
## v2.1.0
- Upgrade `logzio/prometheus-alerts-migrator` image `v1.1.0`->`v1.2.0`:
  - Add support for MS Teams contact points
  - Update dependencies:
    - `prometheus/common`: `v0.60.1` -> `v0.61.0`
    - `prometheus/prometheus`: `v0.55.0` -> `v0.301.0`
    - `k8s.io/api`: `v0.31.2` -> `v0.32.0`
    - `k8s.io/apimachinery`: `v0.31.2` -> `v0.32.0`
    - `k8s.io/client-go`: `v0.31.2` -> `v0.32.0`
  - Improve error handling In event handler creation
  - Refactor import alias names to lowercase
## v2.0.3
- Upgrade `logzio/prometheus-alerts-migrator` image `v1.0.3`->`v1.1.0`
  - Add support for migrating alert rules groups
  - Upgrade GoLang version to 1.23
  - Upgrade dependencies
    - `k8s.io/client-go`: `v0.28.3` -> `v0.31.2`
    - `k8s.io/apimachinery`: `v0.28.3` -> `v0.31.2`
    - `k8s.io/api`: `v0.28.3` -> `v0.31.2`
    - `k8s.io/klog/v2`: `v2.110.1` -> `v2.130.1`
    - `logzio_terraform_client`: `1.20.0` -> `1.22.0`
    - `prometheus/common`: `v0.44.0` -> `v0.60.1`
    - `prometheus/alertmanager`: `v0.26.0` -> `v0.27.0`
    - `prometheus/prometheus`: `v0.47.2` -> `v0.55.0`
## v2.0.2
  - Remove default resources `limits`
## v2.0.1
  - values.yaml:
    - Added rbac permissions to create `events`
## v2.0.0
- values.yaml:
  - Added: `config.alerManagerConfigMapAnnotation`, `config.ingnoreSlackText`, `config.ingnoreSlackTitle` values
  - Refactor: `config.configMapAnnotation`->`config.rulesConfigMapAnnotation`
- Upgrade `logzio/prometheus-alerts-migrator` image `v1.0.0`->`v1.0.3`:
  - Handle Prometheus alert manager configuration file
  - Add CRUD operations for contact points and notification policies
  - Add `reduce` query to alerts (grafana alerts can evaluate alerts only from reduced data)
  - Update `logzio_terraform_client`: `1.18.0` -> `1.19.0`
  - Use data source uid instead of name
## v1.0.0
- initial release
