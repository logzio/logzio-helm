package tests

import (
	"bytes"
	"encoding/json"
	"fmt"
	"go.uber.org/zap"
	"io"
	"net/http"
	"os"
	"testing"
)

type FargateLogResponse struct {
	Hits struct {
		Total int `json:"total"`
		Hits  []struct {
			Source struct {
				LogLevel   string `json:"log_level"`
				Kubernetes struct {
					ContainerName     string `json:"container_name"`
					ContainerHash     string `json:"container_hash"`
					Host              string `json:"host"`
					PodID             string `json:"pod_id"`
					ContainerImageTag string `json:"container_image"`
					PodName           string `json:"pod_name"`
					NamespaceName     string `json:"namespace_name"`
				} `json:"kubernetes"`
			} `json:"_source"`
		} `json:"hits"`
	} `json:"hits"`
}

func TestLogzioMonitoringFargateLogs(t *testing.T) {
	logsApiKey := os.Getenv("LOGZIO_LOGS_API_KEY")
	if logsApiKey == "" {
		t.Fatalf("LOGZIO_LOGS_API_KEY environment variable not set")
	}

	logResponse, err := fetchFargateLogs(logsApiKey)
	if err != nil {
		t.Fatalf("Failed to fetch logs: %v", err)
	}

	if logResponse.Hits.Total == 0 {
		t.Errorf("No logs found")
	}

	for _, hit := range logResponse.Hits.Hits {
		kubernetes := hit.Source.Kubernetes
		if kubernetes.ContainerImageTag == "" || kubernetes.ContainerName == "" || kubernetes.NamespaceName == "" || kubernetes.PodName == "" || kubernetes.PodID == "" || kubernetes.Host == "" {
			logger.Error("Missing log fields", zap.Any("log", hit))
			t.Errorf("Missing log fields")
			break
		}
	}
}

func fetchFargateLogs(logsApiKey string) (*FargateLogResponse, error) {
	url := fmt.Sprintf("%s/search", BaseLogzioApiUrl)
	client := &http.Client{}
	envID := os.Getenv("ENV_ID")
	query := fmt.Sprintf("type:%s AND kubernetes.container_name:log-generator", envID)
	formattedQuery := formatQuery(query)
	logger.Info("sending api request", zap.String("url", url), zap.String("query", query))
	req, err := http.NewRequest("POST", url, bytes.NewBufferString(formattedQuery))
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

	var logResponse FargateLogResponse
	err = json.Unmarshal(body, &logResponse)
	if err != nil {
		return nil, err
	}

	return &logResponse, nil
}
