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
				EventType    string            `json:"event_type"`
				Category     string            `json:"category"`
				Timestamp    int64             `json:"timestamp"`
				Dimensions   map[string]string `json:"dimensions"`
				Properties   map[string]string `json:"properties"`
				Source       string            `json:"source"`
				EnvID        string            `json:"env_id"`
				LogLevel     string            `json:"log_level"`
				Message      string            `json:"message"`
			} `json:"_source"`
		} `json:"hits"`
	} `json:"hits"`
}

func TestLogzioLogsCollectorSignalFxLogs(t *testing.T) {
	logsApiKey := os.Getenv("LOGZIO_LOGS_API_KEY")
	if logsApiKey == "" {
		t.Fatalf("LOGZIO_LOGS_API_KEY environment variable not set")
	}

	logResponse, err := fetchSignalFxLogs(logsApiKey)
	if err != nil {
		t.Fatalf("Failed to fetch SignalFx logs: %v", err)
	}

	if logResponse.Hits.Total == 0 {
		t.Errorf("No SignalFx logs found")
	}
	
	logger.Info("Found SignalFx logs", zap.Int("total", logResponse.Hits.Total))

	for _, hit := range logResponse.Hits.Hits {
		source := hit.Source
		
		// Check required SignalFx event fields
		if source.EventType == "" {
			logger.Error("Missing event_type field", zap.Any("log", hit))
			t.Errorf("Missing event_type field")
			break
		}
		
		if source.Category == "" {
			logger.Error("Missing category field", zap.Any("log", hit))
			t.Errorf("Missing category field")
			break
		}
		
		if source.Timestamp == 0 {
			logger.Error("Missing timestamp field", zap.Any("log", hit))
			t.Errorf("Missing timestamp field")
			break
		}
		
		// Check dimensions
		if source.Dimensions == nil {
			logger.Error("Missing dimensions", zap.Any("log", hit))
			t.Errorf("Missing dimensions")
			break
		}
		
		if source.Dimensions["env_id"] == "" {
			logger.Error("Missing env_id in dimensions", zap.Any("log", hit))
			t.Errorf("Missing env_id in dimensions")
			break
		}
		
		if source.Dimensions["source"] == "" {
			logger.Error("Missing source in dimensions", zap.Any("log", hit))
			t.Errorf("Missing source in dimensions")
			break
		}
		
		// Check properties
		if source.Properties == nil {
			logger.Error("Missing properties", zap.Any("log", hit))
			t.Errorf("Missing properties")
			break
		}
		
		if source.Properties["message"] == "" {
			logger.Error("Missing message in properties", zap.Any("log", hit))
			t.Errorf("Missing message in properties")
			break
		}
		
		if source.Properties["log_level"] == "" {
			logger.Error("Missing log_level in properties", zap.Any("log", hit))
			t.Errorf("Missing log_level in properties")
			break
		}
		
		// Check if the log is from SignalFx source
		if source.Dimensions["source"] != "signalfx-logs-gen" {
			logger.Error("Log not from SignalFx source", zap.String("source", source.Dimensions["source"]))
			t.Errorf("Expected log from SignalFx source, got: %s", source.Dimensions["source"])
		}
		
		// Log successful validation for debugging
		logger.Info("Successfully validated SignalFx log", 
			zap.String("event_type", source.EventType),
			zap.String("category", source.Category),
			zap.String("source", source.Dimensions["source"]),
			zap.String("env_id", source.Dimensions["env_id"]))
		
		// Check event type
		if source.EventType != "test_signalfx_log" {
			logger.Error("Unexpected event type", zap.String("event_type", source.EventType))
			t.Errorf("Expected event type 'test_signalfx_log', got: %s", source.EventType)
		}
		
		// Check category
		if source.Category != "USER_DEFINED" {
			logger.Error("Unexpected category", zap.String("category", source.Category))
			t.Errorf("Expected category 'USER_DEFINED', got: %s", source.Category)
		}
	}
}

func fetchSignalFxLogs(logsApiKey string) (*LogResponse, error) {
	url := fmt.Sprintf("%s/search", BaseLogzioApiUrl)
	client := &http.Client{}
	envID := os.Getenv("ENV_ID")
	query := fmt.Sprintf("env_id:%s AND type:agent-k8s AND source:signalfx-logs-gen", envID)
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
		logger.Error("Failed to unmarshal response", zap.String("body", string(body)), zap.Error(err))
		return nil, err
	}
	
	logger.Info("Successfully parsed response", zap.Int("totalHits", logResponse.Hits.Total))

	return &logResponse, nil
} 