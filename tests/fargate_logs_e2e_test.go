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
				LogLevel          string `json:"log_level"`
				ContainerName     string `json:"kubernetes_container_name"`
				ContainerHash     string `json:"kubernetes_container_hash"`
				Host              string `json:"kubernetes_host"`
				PodID             string `json:"kubernetes_pod_id"`
				ContainerImageTag string `json:"kubernetes_container_image"`
				PodName           string `json:"kubernetes_pod_name"`
				NamespaceName     string `json:"kubernetes_namespace_name"`
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
		log := hit.Source
		if log.ContainerImageTag == "" || log.ContainerName == "" || log.NamespaceName == "" || log.PodName == "" || log.PodID == "" || log.Host == "" {
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
	query := fmt.Sprintf("type:%s AND kubernetes_container_name:log-generator", envID)
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
