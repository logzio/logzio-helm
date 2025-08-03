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

// CarbonMetricResponse represents the structure of the API response for carbon metrics
type CarbonMetricResponse struct {
	Status string `json:"status"`
	Data   struct {
		ResultType string `json:"resultType"`
		Result     []struct {
			Metric map[string]string `json:"metric"`
			Value  []interface{}     `json:"value"`
		} `json:"result"`
	} `json:"data"`
}

func TestCarbonMetricsTags(t *testing.T) {
	requiredMetrics := map[string][]string{
		"test_carbon_metric": {"p8s_logzio_name", "source"},
	}
	envId := os.Getenv("ENV_ID")
	queryTemplate := `test_carbon_metric{p8s_logzio_name="%s"}`
	query := fmt.Sprintf(queryTemplate, envId)
	escapedQuery := url.QueryEscape(query)
	testCarbonMetrics(t, requiredMetrics, escapedQuery)
}

func TestCarbonMetricsDot(t *testing.T) {
	requiredMetrics := map[string][]string{
		"test_carbon_metric": {"p8s_logzio_name", "env_id", "source"},
	}
	envId := os.Getenv("ENV_ID")
	queryTemplate := `test_carbon_metric{p8s_logzio_name="%s",env_id="%s"}`
	query := fmt.Sprintf(queryTemplate, envId, envId)
	escapedQuery := url.QueryEscape(query)
	testCarbonMetrics(t, requiredMetrics, escapedQuery)
}

func testCarbonMetrics(t *testing.T, requiredMetrics map[string][]string, query string) {
	metricsApiKey := os.Getenv("LOGZIO_METRICS_API_KEY")
	if metricsApiKey == "" {
		t.Fatalf("LOGZIO_METRICS_API_KEY environment variable not set")
	}

	metricResponse, err := fetchCarbonMetrics(metricsApiKey, query)
	if err != nil {
		t.Fatalf("Failed to fetch metrics: %v", err)
	}

	if metricResponse.Status != "success" {
		t.Errorf("No metrics found")
	}
	logger.Info("Found metrics", zap.Int("metrics_count", len(metricResponse.Data.Result)))
	// Verify required metrics
	missingMetrics := verifyCarbonMetrics(metricResponse, requiredMetrics)
	if len(missingMetrics) > 0 {
		var sb strings.Builder
		for _, metric := range missingMetrics {
			sb.WriteString(metric + "\n")
		}
		t.Errorf("Missing metrics or labels:\n%s", sb.String())
	}
}

// fetchCarbonMetrics fetches the metrics from the logz.io API
func fetchCarbonMetrics(metricsApiKey string, query string) (*CarbonMetricResponse, error) {
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

	var metricResponse CarbonMetricResponse
	err = json.Unmarshal(body, &metricResponse)
	if err != nil {
		return nil, err
	}

	return &metricResponse, nil
}

// verifyCarbonMetrics checks if the required metrics and their labels are present in the response
func verifyCarbonMetrics(metricResponse *CarbonMetricResponse, requiredMetrics map[string][]string) []string {
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
	return deduplicateCarbon(missingMetrics)
}

// deduplicateCarbon removes duplicate strings from the input array.
func deduplicateCarbon(data []string) []string {
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

 