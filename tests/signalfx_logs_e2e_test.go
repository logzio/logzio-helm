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
				EventType       string            `json:"com_splunk_signalfx_event_type"`
				EventCategory   int               `json:"com_splunk_signalfx_event_category"`
				AccessToken     string            `json:"com_splunk_signalfx_access_token"`
				EventProperties map[string]string `json:"com_splunk_signalfx_event_properties"`
				Source          string            `json:"source"`
				EnvID           string            `json:"env_id"`
				Timestamp       int64             `json:"@timestamp"`
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
		
		// Debug: Log the entire log structure to understand what we're getting
		logger.Info("Processing SignalFx log", zap.Any("log", hit))
		
		// Check required SignalFx event fields
		if source.EventType == "" {
			logger.Error("Missing com_splunk_signalfx_event_type field", zap.Any("log", hit))
			t.Errorf("Missing com_splunk_signalfx_event_type field")
			break
		}
		
		if source.EventCategory == 0 {
			logger.Error("Missing com_splunk_signalfx_event_category field", zap.Any("log", hit))
			t.Errorf("Missing com_splunk_signalfx_event_category field")
			break
		}
		
		if source.Timestamp == 0 {
			logger.Error("Missing @timestamp field", zap.Any("log", hit))
			t.Errorf("Missing @timestamp field")
			break
		}
		
		// Check event properties
		if source.EventProperties == nil {
			logger.Error("Missing com_splunk_signalfx_event_properties", zap.Any("log", hit))
			t.Errorf("Missing com_splunk_signalfx_event_properties")
			break
		}
		
		if source.EventProperties["message"] == "" {
			logger.Error("Missing message in event_properties", zap.Any("log", hit))
			t.Errorf("Missing message in event_properties")
			break
		}
		
		if source.EventProperties["log_level"] == "" {
			logger.Error("Missing log_level in event_properties", zap.Any("log", hit))
			t.Errorf("Missing log_level in event_properties")
			break
		}
		
		// Check if the log is from SignalFx source
		if source.Source != "signalfx-logs-gen" {
			logger.Error("Log not from SignalFx source", zap.String("source", source.Source))
			t.Errorf("Expected log from SignalFx source, got: %s", source.Source)
		}
		
		// Log successful validation for debugging
		logger.Info("Successfully validated SignalFx log", 
			zap.String("event_type", source.EventType),
			zap.Int("event_category", source.EventCategory),
			zap.String("source", source.Source),
			zap.String("env_id", source.EnvID))
		
		// Check event type
		if source.EventType != "test_signalfx_log" {
			logger.Error("Unexpected event type", zap.String("event_type", source.EventType))
			t.Errorf("Expected event type 'test_signalfx_log', got: %s", source.EventType)
		}
		
		// Check event category (should be 1000000 for USER_DEFINED)
		if source.EventCategory != 1000000 {
			logger.Error("Unexpected event category", zap.Int("event_category", source.EventCategory))
			t.Errorf("Expected event category 1000000, got: %d", source.EventCategory)
		}
	}
}

func fetchSignalFxLogs(logsApiKey string) (*LogResponse, error) {
	url := fmt.Sprintf("%s/search", BaseLogzioApiUrl)
	client := &http.Client{}
	envID := os.Getenv("ENV_ID")
	query := fmt.Sprintf("env_id:%s AND source:signalfx-logs-gen", envID)
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