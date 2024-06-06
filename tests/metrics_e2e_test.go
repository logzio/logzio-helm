package tests

import (
	"encoding/json"
	"fmt"
	"go.uber.org/zap"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
)

// MetricResponse represents the structure of the API response
type MetricResponse struct {
	Status string `json:"status"`
	Data   struct {
		ResultType string `json:"resultType"`
		Result     []struct {
			Metric map[string]string `json:"metric"`
			Value  []interface{}     `json:"value"`
		} `json:"result"`
	} `json:"data"`
}

func TestLogzioMonitoringMetrics(t *testing.T) {
	metricsApiKey := os.Getenv("LOGZIO_METRICS_API_KEY")
	if metricsApiKey == "" {
		t.Fatalf("LOGZIO_METRICS_API_KEY environment variable not set")
	}

	metricResponse, err := fetchMetrics(metricsApiKey)
	if err != nil {
		t.Fatalf("Failed to fetch metrics: %v", err)
	}

	requiredMetrics := map[string][]string{
		"kube_pod_status_phase":                    {"p8s_logzio_name", "namespace", "pod", "phase", "uid"},
		"kube_pod_info":                            {"p8s_logzio_name", "namespace", "host_ip", "node", "pod"},
		"container_cpu_usage_seconds_total":        {"p8s_logzio_name", "namespace", "pod", "region", "topology_kubernetes_io_region", "container"},
		"kube_pod_container_resource_limits":       {"p8s_logzio_name", "namespace", "pod", "resource"},
		"container_memory_working_set_bytes":       {"p8s_logzio_name", "namespace", "pod", "container"},
		"kube_pod_container_info":                  {"p8s_logzio_name", "namespace", "pod"},
		"container_network_transmit_bytes_total":   {"p8s_logzio_name", "namespace", "pod"},
		"container_network_receive_bytes_total":    {"p8s_logzio_name", "namespace", "pod"},
		"kube_pod_created":                         {"p8s_logzio_name", "namespace", "pod"},
		"kube_pod_owner":                           {"p8s_logzio_name", "namespace", "pod", "owner_kind", "owner_name"},
		"kube_pod_container_status_restarts_total": {"p8s_logzio_name", "namespace", "pod"},
		"kube_pod_status_reason":                   {"p8s_logzio_name", "namespace", "pod", "reason"},
		"kube_pod_container_status_waiting_reason": {"p8s_logzio_name", "namespace", "pod", "reason"},
		"node_cpu_seconds_total":                   {"p8s_logzio_name", "instance", "kubernetes_node"},
		"kube_node_status_allocatable":             {"p8s_logzio_name", "node", "resource"},
		"node_memory_MemAvailable_bytes":           {"p8s_logzio_name", "instance", "kubernetes_node"},
		"node_memory_MemTotal_bytes":               {"p8s_logzio_name", "instance", "kubernetes_node"},
		"kube_node_role":                           {"p8s_logzio_name", "status", "role", "node"},
		"kube_node_status_condition":               {"p8s_logzio_name", "status", "role", "node"},
		"kube_node_created":                        {"p8s_logzio_name", "node"},
		"node_filesystem_avail_bytes":              {"p8s_logzio_name", "instance", "kubernetes_node"},
		"node_filesystem_size_bytes":               {"p8s_logzio_name", "instance", "kubernetes_node"},
		"kube_replicaset_owner":                    {"p8s_logzio_name", "namespace", "owner_kind", "owner_name", "replicaset"},
		"kube_deployment_created":                  {"p8s_logzio_name", "namespace", "deployment"},
		"kube_deployment_status_condition":         {"p8s_logzio_name", "namespace", "deployment", "status"},
		"calls_total":                              {"k8s_node_name", "k8s_namespace_name", "k8s_pod_name", "span_kind", "operation"},
		"latency_sum":                              {"k8s_node_name", "k8s_namespace_name", "k8s_pod_name", "span_kind", "operation"},
		"latency_count":                            {"k8s_node_name", "k8s_namespace_name", "k8s_pod_name", "span_kind", "operation"},
		"latency_bucket":                           {"k8s_node_name", "k8s_namespace_name", "k8s_pod_name", "span_kind", "operation"},
	}

	if metricResponse.Status != "success" {
		t.Errorf("No metrics found")
	}
	logger.Info("Found metrics", zap.Int("metrics_count", len(metricResponse.Data.Result)))
	// Verify required metrics
	missingMetrics := verifyMetrics(metricResponse, requiredMetrics)
	if len(missingMetrics) > 0 {
		var sb strings.Builder
		for _, metric := range missingMetrics {
			sb.WriteString(metric + "\n")
		}
		t.Errorf("Missing metrics or labels:\n%s", sb.String())
	}
}

// fetchMetrics fetches the metrics from the logz.io API
func fetchMetrics(metricsApiKey string) (*MetricResponse, error) {
	envId := os.Getenv("ENV_ID")
	url := fmt.Sprintf("%s/metrics/prometheus/api/v1/query?query={env_id='%s'}", BaseLogzioApiUrl, envId)
	client := &http.Client{}
	logger.Info("sending api request", zap.String("url", url))
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("X-API-TOKEN", metricsApiKey)

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var metricResponse MetricResponse
	err = json.Unmarshal(body, &metricResponse)
	if err != nil {
		return nil, err
	}

	return &metricResponse, nil
}

// verifyMetrics checks if the required metrics and their labels are present in the response
func verifyMetrics(metricResponse *MetricResponse, requiredMetrics map[string][]string) []string {
	missingMetrics := []string{}

	for metricName, requiredLabels := range requiredMetrics {
		found := false
		for _, result := range metricResponse.Data.Result {
			if result.Metric["__name__"] == metricName {
				found = true
				for _, label := range requiredLabels {
					if _, exists := result.Metric[label]; !exists {
						missingMetrics = append(missingMetrics, fmt.Sprintf("%s (missing label: %s)", metricName, label))
					}
				}
			}
		}
		if !found {
			missingMetrics = append(missingMetrics, metricName+" (not found)")
		}
	}
	return deduplicate(missingMetrics)
}

// deduplicate removes duplicate strings from the input array.
func deduplicate(data []string) []string {
	uniqueMap := make(map[string]bool)
	var uniqueList []string

	for _, item := range data {
		trimmedItem := strings.TrimSpace(item)
		if _, exists := uniqueMap[trimmedItem]; !exists {
			uniqueMap[trimmedItem] = true
			uniqueList = append(uniqueList, trimmedItem)
		}
	}

	return uniqueList
}
