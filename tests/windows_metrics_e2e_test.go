package tests

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"testing"

	"go.uber.org/zap"
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

// TestWindowsMetrics verifies that node-level Windows metrics collected by the
// windows_exporter HostProcess DaemonSet reach Logz.io with the node-level
// labels required by the Kubernetes 360 dashboard. Runs only against the
// Windows AKS e2e cluster.
func TestWindowsMetrics(t *testing.T) {
	if os.Getenv("KUBERNETES_ENV") != "aks-windows" {
		t.Skip("Skipping Windows metrics test (KUBERNETES_ENV != aks-windows)")
	}
	requiredMetrics := map[string][]string{
		"windows_cpu_time_total":              {"p8s_logzio_name", "instance", "kubernetes_node", "mode"},
		"windows_memory_available_bytes":      {"p8s_logzio_name", "instance", "kubernetes_node"},
		"windows_memory_physical_total_bytes": {"p8s_logzio_name", "instance", "kubernetes_node"},
		"windows_logical_disk_free_bytes":     {"p8s_logzio_name", "instance", "kubernetes_node"},
		"windows_logical_disk_size_bytes":     {"p8s_logzio_name", "instance", "kubernetes_node"},
	}
	envId := os.Getenv("ENV_ID")
	query := fmt.Sprintf(`{env_id='%s',__name__=~'windows_.+'}`, envId)
	testMetrics(t, requiredMetrics, query)
}

// testMetrics fetches metrics from Logz.io and asserts the required metrics/labels are present.
func testMetrics(t *testing.T, requiredMetrics map[string][]string, query string) {
	metricsApiKey := os.Getenv("LOGZIO_METRICS_API_KEY")
	if metricsApiKey == "" {
		t.Fatalf("LOGZIO_METRICS_API_KEY environment variable not set")
	}

	metricResponse, err := fetchMetrics(metricsApiKey, url.QueryEscape(query))
	if err != nil {
		t.Fatalf("Failed to fetch metrics: %v", err)
	}

	if metricResponse.Status != "success" {
		t.Errorf("No metrics found")
	}
	logger.Info("Found metrics", zap.Int("metrics_count", len(metricResponse.Data.Result)))

	missingMetrics := verifyMetrics(metricResponse, requiredMetrics)
	if len(missingMetrics) > 0 {
		var sb strings.Builder
		for _, metric := range missingMetrics {
			sb.WriteString(metric + "\n")
		}
		t.Errorf("Missing metrics or labels:\n%s", sb.String())
	}
}

// fetchMetrics fetches the metrics from the Logz.io API
func fetchMetrics(metricsApiKey string, query string) (*MetricResponse, error) {
	requestUrl := fmt.Sprintf("%s/metrics/prometheus/api/v1/query?query=%s", BaseLogzioApiUrl, query)
	client := &http.Client{}
	logger.Info("sending api request", zap.String("url", requestUrl))
	req, err := http.NewRequest("GET", requestUrl, nil)
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
	if err := json.Unmarshal(body, &metricResponse); err != nil {
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

// deduplicate removes duplicate strings from the input slice.
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
