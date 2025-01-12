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

func TestSpmMetricsApm(t *testing.T) {
	requiredMetrics := map[string][]string{
		"calls_total":    {"k8s_node_name", "k8s_namespace_name", "k8s_pod_name", "span_kind", "operation"},
		"latency_sum":    {"k8s_node_name", "k8s_namespace_name", "k8s_pod_name", "span_kind", "operation"},
		"latency_count":  {"k8s_node_name", "k8s_namespace_name", "k8s_pod_name", "span_kind", "operation"},
		"latency_bucket": {"k8s_node_name", "k8s_namespace_name", "k8s_pod_name", "span_kind", "operation"},
	}
	envId := os.Getenv("ENV_ID")
	query := fmt.Sprintf(`{env_id='%s'}`, envId)
	testMetrics(t, requiredMetrics, query)
}

func TestServiceGraphMetricsApm(t *testing.T) {
	requiredMetrics := map[string][]string{
		"traces_service_graph_request_total":                 {"client", "server"},
		"traces_service_graph_request_failed_total":          {"client", "server"},
		"traces_service_graph_request_server_seconds_bucket": {"client", "server"},
		"traces_service_graph_request_server_seconds_count":  {"client", "server"},
		"traces_service_graph_request_server_seconds_sum":    {"client", "server"},
		"traces_service_graph_request_client_seconds_bucket": {"client", "server"},
		"traces_service_graph_request_client_seconds_count":  {"client", "server"},
		"traces_service_graph_request_client_seconds_sum":    {"client", "server"},
	}
	envId := os.Getenv("ENV_ID")
	query := fmt.Sprintf(`{client_env_id='%s'}`, envId)
	testMetrics(t, requiredMetrics, query)
}

func testMetrics(t *testing.T, requiredMetrics map[string][]string, query string) {
	metricsApiKey := os.Getenv("LOGZIO_METRICS_API_KEY")
	if metricsApiKey == "" {
		t.Fatalf("LOGZIO_METRICS_API_KEY environment variable not set")
	}

	metricResponse, err := fetchMetrics(metricsApiKey, query)
	if err != nil {
		t.Fatalf("Failed to fetch metrics: %v", err)
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
func fetchMetrics(metricsApiKey string, query string) (*MetricResponse, error) {
	url := fmt.Sprintf("%s/metrics/prometheus/api/v1/query?query=%s", BaseLogzioApiUrl, query)
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
