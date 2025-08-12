# Changes by Version

<!-- next version -->
## 5.6.0
 - Upgrade OpenTelemetry collector to v0.131.0
 - Add health check port
 - Fix custom logs endpoint
 - Add liveness and readiness probe configuration
 - Remove deprecated `logging` exporter
 - Add generation metrics to K8S filter list

## 5.5.0
 - **Breaking change:** 
  - Default resource requests and limits for `standaloneCollector`,  `daemonsetCollector` &  `spanMetricsAgregator` are now empty by default and are configurable, only applies when explicitly set.
 - Add `priorityClassName`
 - Add `extraConfigMapMounts`
## 5.4.3
 - Add `enableServiceLinks` flag to control loading of service environment variables.
## 5.4.2
  - Disable k8s 360 environment variables if no filters are used.
## 5.4.1
  - Modify batch processor to be based on specific pipeline instead of base collector config
## 5.4.0
  - Add SignalFx metrics receiver
  - Add Carbon metrics receiver
  - Add custom logs endpoint
## 5.3.1
  - Add filters to `metrics_relabel_configs` instead of `relabel_configs`
  - Add comprehensive documentation warnings for new `filters` syntax regarding K8s 360 metrics compatibility
## 5.3.0
  - Add new `filters` syntax for metrics relabeling (recommended over legacy prometheusFilters)
## 5.2.1
  - Fix Pod disruption budget selector label for SPM collector (Contributed by @jod972)
  - Add PriorityClassName for SPM collector (Contributed by @jod972)
  - Add Replica Count for traces & SPM collectors
## 5.2.0
  - Expose collector metrics port by default
  - Add `podDisruptionBudget` (Contributed by @jod972)
  - Add `topologySpreadConstraints` (Contributed by @jod972)
  - Add support for auto resource detection with `distribution` and `resourceDetection.enabled` flags.
    - The old `resourcedetection/all` configuration now serves as fallback if `distribution` is empty or with unknown value.
  - **Breaking changes:** Resource detection is disabled by default. Meaning, the old `resourcedetection/all` for trace and SPM is not applied by default.
    - If you use this chart for trace and SPM collection, you can enable it by setting `resourceDetection.enabled=true`.
## 5.1.0
  - Respect metric filters in `prometheus/kubelet` scrape endpoint
## 5.0.4
  - Add support for global tolerations
## 5.0.3
  - Exposed span metrics collector service port for `thrift_binary` jaeger receiver
## 5.0.2
  - Exposed collector service port for `thrift_binary` jaeger receiver
## 5.0.1
  - Add `otlp` receivers to the metrics pipeline.
## 5.0.0
  - **Breaking Changes**
    - Logz.io secret values are now global
      - `secrets.MetricsToken` >> `global.logzioMetricsToken`
      - `secrets.TracesToken` >> `global.logzioTracesToken`
      - `secrets.SpmToken` >> `global.logzioSpmToken`
      - `secrets.k8sObjectsLogsToken` >> `global.logzioLogsToken`
      - `secrets.env_id` >> `global.env_id`
      - `secrets.LogzioRegion` >> `global.logzioRegion`
      - `secrets.CustomTracingEndpoint` >> `global.customTracesEndpoint`
      - Deprecate `secrets.p8s_logzio_name` and `secrets.ListenerHost`
        - Add `global.customMetricsEndpoint` to support sending metrics to a custom endpoint
## 4.3.2
  - Fix `prometheus/kubelet` scrape endpoint for standalone deployment
## 4.3.1
  - Add `prometheus/kubelet` job for kubelet metrics
## 4.3.0
  - Set `servicegraph` connector, `metrics_flush_interval` setting to `60s` to reduce outgoing connections
## 4.2.9
  - Add batch processor to the SPM pipeline, to reduce stress and increase efficiency.
## 4.2.8
  - Upgrade `otel/opentelemetry-collector-contrib` image to `v0.108.0`
  - Remove default resources `limits`
## 4.2.7
  - Fix `cluster-admin` cluster role binding creation condition
## 4.2.6
  - Upgrade `otel/opentelemetry-collector-contrib` image to `v0.103.0`
  - Fix standalone self metrics collection for EKS Fargate 
## 4.2.5
  - Added 'user-agent' header for telemetry data.
## 4.2.4
  - Upgrade `otel/opentelemetry-collector-contrib` image to `v0.102.1`
## 4.2.3
  - Disable Kubernetes objects receiver by default.
## 4.2.2
  - Fix missing `logzio-k8s-objects-logs-token` key from secret.
## 4.2.1
  - Filter in `container_cpu_cfs_throttled_seconds_total` and `kube_pod_container_info` metrics.
## 4.2.0
  - Upgraded `opentelemetry-collector-contrib` image to `v0.97.0`
  - Added Kubernetes objects receiver
  - Removed servicegraph connector from span metrics configuration
  - Allow `env_id` & `p8s_logzio_name` non string values
## 4.1.3
  - Removed unused prometheus receiver
  - Divide metrics and labels renames to separate processors
  - Disable metric suffix from prometheus exporter.
    - Resolves latency metric rename
## 4.1.2
  - Upgrade `.values.spmImage.tag` `0.80` -> `0.97`
    - Add `metrics_expiration` to span metrics configuration, to prevent sending expired time series
    - Add `resource_metrics_key_attributes` to span metrics configuration, to prevent value fluctuation of counter metrics when resource attributes change.
  - Include collector log level configuration in individual components (standalone, daemonset, spanmetrics).
## 4.1.1
  - Fixed bug with cAdvisor metrics filter for standalone collector mode.
## 4.1.0
  - Upgraded prometheus-node-exporter version to `4.29.0`
  - Fixed bug with AKS metrics filter
  - Remove unified_status_code label from SPM
## 4.0.0
  - **BREAKING CHANGES**:
    - Removed the `kubernetes-360-metrics` key from the `logzio-secret`.
      - Populate the pods containers `K8S_360_METRICS` environment variable directly using the opentelemetry-collector.k8s360 definition to inherit the list from values file instead.
  - Added `logzio_app` label with `kubernetes360` value to cadvisor metrics pipeline to avoid dropping specific metrics by matching the k8s 360 filter.
## 3.0.0
  - Updated K360 metrics list in `secrets.yaml` - now created dynamically from OOB filters.
  - Added `job_dummy` relabel and processor - Fixing an issue where duplicate metrics were being sent if the metrics were not in the `K8S_360_METRICS` environment variable.
  - Use attributes processor to create the `unified_status_code` dimension as it supports connectors.
  - **BREAKING CHANGES**:
    - Instead of having the global `metrics.enabled` option of disabling installation of all logzio-telemetry sub charts, each sub chart has its own flag and by default will be installed.
      - `kubeStateMetrics.enabled`
      - `pushGateway.enabled`
      - `nodeExporter.enabled`



<details>
  <summary markdown="span"> Expand to check old versions </summary>

## 2.2.0
  - Upgraded SPM collector image to version `0.80.0`.
  - Added service graph connector metrics.
    - `serviceGraph.enabled` option.
  - Refactored span metrics processor to a connector.
    - Added metrics transform processor to modify the data for Logz.io backwards compatibility.
## 2.1.0
  - Update SPM labels
    - Add `rpc_grpc_status_code` dimension
    - Add `unified_status_code` dimension
      - Takes value of `rpc_grpc_status_code` / `http_status_code`
  - Add `containerSecurityContext` configuration option for container based policies. 
## 2.0.0
  - Upgrade sub charts to their latest versions.
    - `kube-state-metrics` to `4.24.0`
      - Upgraded horizontal pod autoscaler API group version.
    - `prometheus-node-exporter` to `4.23.2`
    - `prometheus-pushgateway` to `2.4.2`
  - Secrets resource name is now changeable via `secrets.name` in `values.yaml`.
  - Fix sub charts conditional installation. 
  - Add conditional creation of `CustomTracingEndpoint` secret key. 
## 1.3.0
  - Upgraded horizontal pod autoscaler API group version.
## 1.2.0
  - Upgraded collector image to `0.80.0`.
  - Changed condition to filter duplicate metrics collected by daemonset collector.
## 1.1.0
  - Add custom tracing endpoint option
## 1.0.3
  - Fixed an issue when enabling dropKubeSystem filter where namespace label values were not filtered.
## 1.0.2
  - Rename `spm` k8s metadata fields
## 1.0.1
  - Fixed `spm` service component name
  - Add `spm` cloud metadata
  - Rename `spm` k8s metadata fields
## 1.0.0 
  - Fixed an issue where when enabling `enableMetricsFilter.kubeSystem` installation failes.
  - **BREAKING CHANGES**:
    - Rename `enableMetricsFilter.kubeSystem` to `enableMetricsFilter.dropKubeSystem`, in order to avoid confusion between functionality of filters.
## 0.2.1
  - Rename k8s attributes for traces pipeline.
  - SPM: add dimension `http.status_code`.
## 0.2.0
  - **BREAKING CHANGES**:
   - Added `applicationMetrics.enabled` value (defaults to `false`)
## 0.1.1
  - Added added resourcedetection processor - added kubernetes spm labels and traces fields.
## 0.1.0 
  - **BREAKING CHANGES**:
    - Split prometheus scrape jobs to separate pipelines:
      - Infrastrucutre: includes kubernetes-service-endpoints, windows-metrics, collector-metrics & cadvisor jobs.
      - Applications: includes applications jobs
    - Improved prometheus filters mechanism:
      - Users can now easily add custom filters for metrics, namesapces & services
      using `prometheusFilters` in `values.yaml`. For more information view [Adding additional filters](#adding-addiotional-filters-for-metrics-scraping) 
    - Added spot labels for kube-state-metrics.
## 0.0.29
  - Upgrade traces and metrics otel image `0.70.0` -> `0.78.0`
  - Upgrade spm image `0.70.0` -> `0.73.0`
  - Added values for seprate spm iamge  
## 0.0.28
  - Change default metrics scrape and export values to handle more cases
  - Reorder processors
  - Remove the `memory_limiter` processor
## 0.0.27
  - Removed duplicate `prometheus.io/scrape` annotation from `kube-state-metrics` (@dlip)
## 0.0.26
  - Added `applications` scrape job for `daemonset` collector mode.
  - Added `secrets.enabled` value.

## 0.0.25
  - Added affinity condition to the daemonset collector.
  - Added opencost duplicate metrics filtering. NOTE: Opencost can be enabled with [Logzio Monitorig Helm Chart](https://github.com/logzio/logzio-helm/tree/master/charts/logzio-monitoring)
  - Fix condition for collector service.
  - Improved naming of the collector deployments:
    - Daemonset pods now have the "ds" suffix.
    - Standalone pod now have the "standalone" suffix.

## 0.0.24
  - Added `collector.mode` flag - now supports `standalone` and `daemonset`, default is `daemonset`.
  - Fixed subchart conditions.
  - Added `VALUES.md`. 
  - Increased minimum memory (`1024Mi`) and cpu (`512m`) requiremts for the collector pods.

## 0.0.23
  - Updated metrics filter (#219)
## 0.0.22
  - **breaking changes:** Add separate span metrics component that includes the following resources:
    - `deployment-spm.yaml`
    - `service-spm.yaml`
    - `configmap-spm.yaml`
  - Updated collector image -> `0.70.0`
## 0.0.21
  - Updated collector image - fixing memory leak crash.
## 0.0.20
  - Change the default port for node exporter `9100` -> `9101` to avoid pods stocking on pending state if a user has `node-exporter` daemon set deployed on the cluster
  - Update otel `0.64.0` -> `0.66.0` 
  - Add `logzio_agent_version` label
  - Add `logz.io/app=kubertnetes360` annotation to `Kube-state-metrics` and `node-exporter`
  - Add `filter/kubernetes360` processor for metrics, to avoid duplicated metrics if a user has `Kube-state-metrics` or `node-exporter` deployed on the cluster
## 0.0.19
  - Drop metrics from `kube-system` namespace
## 0.0.18
  - Add `kube_pod_container_status_terminated_reason` `kube_node_labels` metrics to filters
## 0.0.17
  - Add `kube_pod_container_status_waiting_reason` metric to filters
## 0.0.16
  - Add `kube_deployment_labels` `node_memory_Buffers_bytes` `node_memory_Cached_bytes` metrics to filters
## 0.0.15
  - Add `applications` job
  - Add `collector-metrics` job
  - Replace `$` -> `$$` to escape special char
  - Upgrade otel image `0.60.0`-> `0.64.0`
  - Add `k8s 360` metrics to filters
## 0.0.14
  - Add `k8sattributesprocessor`
  - Require `p8s-logzio-name` only if `metrics` or `spm` are enabled
  - Add `resource/k8s` processor
## 0.0.13
  - Change to `prometheus` exporter for spanmetrics
## 0.0.12
  - Add listener url when `spm` is enabled.
## 0.0.11
  - Change default values of `secrets.SamplingProbability`, `secrets.SamplingLatency`
## 0.0.10
  - `SampelingProbability` -> `SamplingProbability`
## 0.0.9
  - Remove `decision_wait` `num_traces` `expected_new_traces_per_sec` options from the tail sampling proccessor, in order to use the otel default values for the proccessor
  - Fix typos
## 0.0.8
  - Changed default value for `env_id`
## 0.0.7
  - Added default value for `env_id`
## 0.0.6
  - Added span metrics
  - Added sampling
## 0.0.5
  - Upgrade otel collector image -> `otel/opentelemetry-collector-contrib:0.60.0`
## 0.0.4
  - Added basic metrics filtering for gke,aks and eks clusters (via "enableMetricsFilter" parameter).
  - Fixed an issue where windows-metrics scraping job trying to scrape linux nodes on gke.
  - Added an option to disable kube-dns service scraping on eks (via "disableKubeDnsScraping" parameter), to prevent contiunous warning logs.
## 0.0.3
  - Dep: kube-state-metrics -> `4.13.0`
  - Dep: prometheus-node-exporter -> `3.3.0`
  - Dep: prometheus-pushgateway -> `1.18.2`
  - Remove batch processor from metrics pipeline
  - Modify resource limitations
## 0.0.2
  - Add default `nodeAffinity` to prevent node exporter deamonset deploymment on fargate nodes
## 0.0.1 - Initial release
</details>
