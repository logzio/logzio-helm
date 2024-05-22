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

// LogResponse represents the structure of the logs API response
type LogResponse struct {
	Hits struct {
		Total int `json:"total"`
		Hits  []struct {
			Source struct {
				Kubernetes struct {
					ContainerImageID string `json:"container_image_id"`
					ContainerName    string `json:"container_name"`
					ContainerImage   string `json:"container_image"`
					NamespaceName    string `json:"namespace_name"`
					PodName          string `json:"pod_name"`
					PodID            string `json:"pod_id"`
					Host             string `json:"host"`
				} `json:"kubernetes"`
			} `json:"_source"`
		} `json:"hits"`
	} `json:"hits"`
}

func TestLogzioMonitoringLogs(t *testing.T) {
	logsApiKey := os.Getenv("LOGZIO_LOGS_API_KEY")
	if logsApiKey == "" {
		t.Fatalf("LOGZIO_LOGS_API_KEY environment variable not set")
	}

	logResponse, err := fetchLogs(logsApiKey)
	if err != nil {
		t.Fatalf("Failed to fetch logs: %v", err)
	}

	if logResponse.Hits.Total == 0 {
		t.Errorf("No logs found")
	}
	// Verify required fields
	requiredFields := []string{"container_image_id", "container_name", "container_image", "namespace_name", "pod_name", "pod_id", "host"}
	missingFields := verifyLogs(logResponse, requiredFields)
	if len(missingFields) > 0 {
		t.Errorf("Missing log fields: %v", missingFields)
	}
}

// fetchLogs fetches the logs from the logz.io API
func fetchLogs(logsApiKey string) (*LogResponse, error) {
	url := fmt.Sprintf("%s/search", BaseLogzioApiUrl)
	client := &http.Client{}
	req, err := http.NewRequest("POST", url, bytes.NewBufferString(LogsQuery))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-TOKEN", logsApiKey)

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

	var logResponse LogResponse
	err = json.Unmarshal(body, &logResponse)
	if err != nil {
		return nil, err
	}

	return &logResponse, nil
}

// verifyLogs checks if the logs contain the required Kubernetes fields
func verifyLogs(logResponse *LogResponse, requiredFields []string) []string {
	missingFieldsMap := make(map[string]bool, len(requiredFields))
	for _, field := range requiredFields {
		missingFieldsMap[field] = false
	}

	for _, hit := range logResponse.Hits.Hits {
		kubernetes := hit.Source.Kubernetes
		if kubernetes.ContainerImageID == "" {
			missingFieldsMap["container_image_id"] = true
			break
		}
		if kubernetes.ContainerName == "" {
			missingFieldsMap["container_name"] = true
			break
		}
		if kubernetes.ContainerImage == "" {
			missingFieldsMap["container_image"] = true
			break
		}
		if kubernetes.NamespaceName == "" {
			missingFieldsMap["namespace_name"] = true
			break
		}
		if kubernetes.PodName == "" {
			missingFieldsMap["pod_name"] = true
			break
		}
		if kubernetes.PodID == "" {
			missingFieldsMap["pod_id"] = true
			break
		}
		if kubernetes.Host == "" {
			missingFieldsMap["host"] = true
			break
		}
	}

	var missingFields []string
	for field, value := range missingFieldsMap {
		if value == true {
			missingFields = append(missingFields, field)
		}
	}

	return missingFields
}
