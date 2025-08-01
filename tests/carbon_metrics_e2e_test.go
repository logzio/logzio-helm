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

func TestCarbonMetrics(t *testing.T) {
	requiredMetrics := map[string][]string{
		"test_carbon_metric": {"p8s_logzio_name", "source"},
	}
	envId := os.Getenv("ENV_ID")
	queryTemplate := `test_carbon_metric{p8s_logzio_name="%s"}`
	query := fmt.Sprintf(queryTemplate, envId)
	escapedQuery := url.QueryEscape(query)
	testMetrics(t, requiredMetrics, escapedQuery)
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