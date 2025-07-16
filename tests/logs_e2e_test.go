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

type LogResponse struct {
	Hits struct {
		Total int `json:"total"`
		Hits  []struct {
			Source struct {
				ContainerImageTag  string `json:"container_image_tag"`
				ContainerImageName string `json:"container_image_name"`
				ContainerName      string `json:"k8s_container_name"`
				NamespaceName      string `json:"k8s_namespace_name"`
				PodName            string `json:"k8s_pod_name"`
				PodUID             string `json:"k8s_pod_uid"`
				NodeName           string `json:"k8s_node_name"`
				LogLevel           string `json:"log_level"`
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

	for _, hit := range logResponse.Hits.Hits {
		kubernetes := hit.Source
		if kubernetes.ContainerImageTag == "" || kubernetes.ContainerName == "" || kubernetes.NamespaceName == "" || kubernetes.PodName == "" || kubernetes.PodUID == "" || kubernetes.NodeName == "" || kubernetes.ContainerImageName == "" || kubernetes.LogLevel == "" {
			logger.Error("Missing log fields", zap.Any("log", hit))
			t.Errorf("Missing log fields")
			break
		}
	}
}

func fetchLogs(logsApiKey string) (*LogResponse, error) {
	url := fmt.Sprintf("%s/search", BaseLogzioApiUrl)
	client := &http.Client{}
	envID := os.Getenv("ENV_ID")
	query := fmt.Sprintf("env_id:%s AND type:%s AND k8s_deployment_name:log-generator", envID, envID)
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

	var logResponse LogResponse
	err = json.Unmarshal(body, &logResponse)
	if err != nil {
		return nil, err
	}

	return &logResponse, nil
}

func TestLogsFilterExcludeKubeSystemNamespace(t *testing.T) {
	logsApiKey := os.Getenv("LOGZIO_LOGS_API_KEY")
	if logsApiKey == "" {
		t.Fatalf("LOGZIO_LOGS_API_KEY environment variable not set")
	}

	logResponse, err := fetchLogs(logsApiKey)
	if err != nil {
		t.Fatalf("Failed to fetch logs: %v", err)
	}

	count := 0
	for _, hit := range logResponse.Hits.Hits {
		if hit.Source.NamespaceName == "kube-system" {
			count++
		}
	}
	if count > 0 {
		t.Errorf("Expected no logs from kube-system namespace, but found %d", count)
	}
}
