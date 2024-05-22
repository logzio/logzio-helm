package tests

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"testing"
)

// TraceResponse represents the structure of the traces API response
type TraceResponse struct {
	Hits struct {
		Total int `json:"total"`
		Hits  []struct {
			Source struct {
				Process struct {
					Tag struct {
						KubernetesNamespace string `json:"kubernetes_namespace"`
						KubernetesNode      string `json:"kubernetes_node"`
						Pod                 string `json:"pod"`
					} `json:"tag"`
				} `json:"process"`
			} `json:"_source"`
		} `json:"hits"`
	} `json:"hits"`
}

func TestLogzioMonitoringTraces(t *testing.T) {
	tracesApiKey := os.Getenv("LOGZIO_TRACES_API_KEY")
	if tracesApiKey == "" {
		t.Fatalf("LOGZIO_TRACES_API_KEY environment variable not set")
	}

	traceResponse, err := fetchTraces(tracesApiKey)
	if err != nil {
		t.Fatalf("Failed to fetch traces: %v", err)
	}
	if traceResponse.Hits.Total == 0 {
		t.Errorf("No traces found")
	}
	// Verify required fields
	requiredFields := []string{"kubernetes_namespace", "kubernetes_node", "pod"}
	missingFields := verifyTraces(traceResponse, requiredFields)
	if len(missingFields) > 0 {
		t.Errorf("Missing trace fields: %v", missingFields)
	}
}

// verifyTraces checks if the traces contain the required Kubernetes fields
func verifyTraces(traceResponse *TraceResponse, requiredFields []string) []string {
	missingFieldsMap := make(map[string]bool, len(requiredFields))
	for _, field := range requiredFields {
		missingFieldsMap[field] = false
	}

	for _, hit := range traceResponse.Hits.Hits {
		tag := hit.Source.Process.Tag
		if tag.KubernetesNamespace == "" {
			missingFieldsMap["kubernetes_namespace"] = true
			break
		}
		if tag.KubernetesNode == "" {
			missingFieldsMap["kubernetes_node"] = true
			break
		}
		if tag.Pod == "" {
			missingFieldsMap["pod"] = true
			break
		}
	}

	var missingFields []string
	for field, value := range missingFieldsMap {
		if value {
			missingFields = append(missingFields, field)
		}
	}

	return missingFields
}

// fetchTraces fetches the traces from the logz.io API
func fetchTraces(tracesApiKey string) (*TraceResponse, error) {
	url := fmt.Sprintf("%s/search", BaseLogzioApiUrl)
	client := &http.Client{}
	req, err := http.NewRequest("POST", url, bytes.NewBufferString(TracesQuery))
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
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var traceResponse TraceResponse
	err = json.Unmarshal(body, &traceResponse)
	if err != nil {
		return nil, err
	}

	return &traceResponse, nil
}
