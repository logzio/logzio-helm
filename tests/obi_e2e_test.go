package tests

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"testing"

	"go.uber.org/zap"
)

// OBITraceResponse represents the structure of the traces API response for OBI tests
type OBITraceResponse struct {
	Hits struct {
		Total int `json:"total"`
		Hits  []struct {
			Source struct {
				Process struct {
					Tag map[string]interface{} `json:"tag"`
				} `json:"process"`
				JaegerTag     map[string]interface{} `json:"JaegerTag"`
				OperationName string                 `json:"operationName"`
			} `json:"_source"`
		} `json:"hits"`
	} `json:"hits"`
}

// TestOBITraces verifies that traces from OBI eBPF instrumentation are arriving at Logz.io
func TestOBITraces(t *testing.T) {
	tracesApiKey := os.Getenv("LOGZIO_TRACES_API_KEY")
	if tracesApiKey == "" {
		t.Fatalf("LOGZIO_TRACES_API_KEY environment variable not set")
	}

	envID := os.Getenv("ENV_ID")
	if envID == "" {
		t.Fatalf("ENV_ID environment variable not set")
	}

	logger.Info("Testing OBI traces", zap.String("env_id", envID))

	traceResponse, err := fetchOBITraces(tracesApiKey, envID)
	if err != nil {
		t.Fatalf("Failed to fetch OBI traces: %v", err)
	}

	if traceResponse.Hits.Total == 0 {
		t.Errorf("No traces found for OBI test application")
	} else {
		logger.Info("Found traces", zap.Int("count", traceResponse.Hits.Total))
	}

	// Verify required Kubernetes fields are present
	requiredK8sFields := []string{"kubernetes_namespace", "kubernetes_node", "pod"}
	missingFields := verifyOBITraces(traceResponse, requiredK8sFields)
	if len(missingFields) > 0 {
		t.Errorf("Missing required Kubernetes fields in traces: %v", missingFields)
	}

	// Verify eBPF/OBI instrumentation indicators
	hasEBPFTraces := false
	for _, hit := range traceResponse.Hits.Hits {
		operationName := hit.Source.OperationName

		// Get telemetry SDK name from process.tag map
		var telemetrySdkName string
		if sdkName, ok := hit.Source.Process.Tag["telemetry@sdk@name"]; ok {
			telemetrySdkName, _ = sdkName.(string)
		}

		logger.Info("Found trace",
			zap.String("operation", operationName),
			zap.String("telemetry_sdk_name", telemetrySdkName))

		// Check for the specific eBPF instrumentation SDK name
		if telemetrySdkName == "opentelemetry-ebpf-instrumentation" {
			hasEBPFTraces = true
			logger.Info("Found eBPF instrumented trace",
				zap.String("operation", operationName),
				zap.String("telemetry_sdk_name", telemetrySdkName))
			break
		}
	}

	if !hasEBPFTraces {
		t.Errorf("No eBPF instrumented traces found - expected traces with telemetry.sdk.name='opentelemetry-ebpf-instrumentation'")
	}
}

// fetchOBITraces fetches the traces from the logz.io API for OBI testing
func fetchOBITraces(tracesApiKey string, envID string) (*OBITraceResponse, error) {
	url := fmt.Sprintf("%s/search", BaseLogzioApiUrl)
	client := &http.Client{}

	query := fmt.Sprintf(`JaegerTag.env_id:%s AND type:jaegerSpan`, envID)
	logger.Info("Fetching OBI traces", zap.String("url", url), zap.String("query", query))

	formattedQuery := formatQuery(query)
	req, err := http.NewRequest("POST", url, bytes.NewBufferString(formattedQuery))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-TOKEN", tracesApiKey)

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("unexpected status code: %d, body: %s", resp.StatusCode, string(body))
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var traceResponse OBITraceResponse
	err = json.Unmarshal(body, &traceResponse)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal trace response: %v, body: %s", err, string(body))
	}

	return &traceResponse, nil
}

// verifyOBITraces checks if the traces contain the required Kubernetes fields
func verifyOBITraces(traceResponse *OBITraceResponse, requiredFields []string) []string {
	if len(traceResponse.Hits.Hits) == 0 {
		return requiredFields // All fields are missing if no traces
	}

	missingFieldsMap := make(map[string]bool)
	for _, field := range requiredFields {
		missingFieldsMap[field] = false
	}

	// TODO change to simple implementation
	fieldMap := map[string]string{
		"kubernetes_namespace": "kubernetes_namespace",
		"kubernetes_node":      "kubernetes_node",
		"pod":                  "pod",
	}

	for _, hit := range traceResponse.Hits.Hits {
		tag := hit.Source.Process.Tag

		for fieldName, tagKey := range fieldMap {
			if value, ok := tag[tagKey]; !ok || value == "" || value == nil {
				missingFieldsMap[fieldName] = true
			}
		}

		// Only check first trace
		break
	}

	var missingFields []string
	for field, missing := range missingFieldsMap {
		if missing {
			missingFields = append(missingFields, field)
		}
	}

	return missingFields
}
