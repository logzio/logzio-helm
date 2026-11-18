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

type k8sObjectLogsResponse struct {
	Hits struct {
		Total int `json:"total"`
		Hits  []struct {
			Source map[string]any `json:"_source"`
		} `json:"hits"`
	} `json:"hits"`
}

func TestK8sObjectsLogs(t *testing.T) {
	logsApiKey := os.Getenv("LOGZIO_LOGS_API_KEY")
	if logsApiKey == "" {
		t.Fatalf("LOGZIO_LOGS_API_KEY environment variable not set")
	}

	res, err := fetchK8sObjectLogs(logsApiKey)
	if err != nil {
		t.Fatalf("Failed to fetch k8s object logs: %v", err)
	}
	if res.Hits.Total == 0 {
		t.Fatalf("No k8s object logs found")
	}

	for _, hit := range res.Hits.Hits {
		src := hit.Source
		object, _ := src["object"].(map[string]any)
		metadata, _ := object["metadata"].(map[string]any)
		if src["k8s_resource_name"] == nil || object["kind"] == nil || metadata["name"] == nil {
			logger.Error("Missing k8s object log fields", zap.Any("log", src))
			t.Errorf("Missing k8s object log fields")
			break
		}
		if _, ok := src["scope"]; ok {
			logger.Error("Unexpected scope field in k8s object log", zap.Any("log", src))
			t.Errorf("Unexpected scope field in k8s object log")
			break
		}
	}
}

func fetchK8sObjectLogs(logsApiKey string) (*k8sObjectLogsResponse, error) {
	url := fmt.Sprintf("%s/search", BaseLogzioApiUrl)
	query := fmt.Sprintf("env_id:%s AND type:k8s_object", os.Getenv("ENV_ID"))
	logger.Info("sending api request", zap.String("url", url), zap.String("query", query))
	req, err := http.NewRequest("POST", url, bytes.NewBufferString(formatQuery(query)))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-API-TOKEN", logsApiKey)

	resp, err := http.DefaultClient.Do(req)
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
	var res k8sObjectLogsResponse
	if err := json.Unmarshal(body, &res); err != nil {
		return nil, err
	}
	return &res, nil
}
