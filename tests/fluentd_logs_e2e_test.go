package tests

import (
	"bytes"
	"encoding/json"
	"fmt"
	"go.uber.org/zap"
	"io"
	"net/http"
	"os"
	"reflect"
	"testing"
)

type FluentdResponse struct {
	Hits struct {
		Total int `json:"total"`
		Hits  []struct {
			Source struct {
				FluentTags string `json:"fluentd_tags"`
				LogLevel   string `json:"log_level"`
				Kubernetes struct {
					ContainerImageTag  string `json:"container_image"`
					ContainerImageName string `json:"container_image_id"`
					ContainerName      string `json:"container_name"`
					NamespaceName      string `json:"namespace_name"`
					PodName            string `json:"pod_name"`
					PodUID             string `json:"pod_id"`
				} `json:"kubernetes"`
			} `json:"_source"`
		} `json:"hits"`
	} `json:"hits"`
}

func TestLogzioFluentdLogs(t *testing.T) {
	logsApiKey := os.Getenv("LOGZIO_LOGS_API_KEY")
	if logsApiKey == "" {
		t.Fatalf("LOGZIO_LOGS_API_KEY environment variable not set")
	}

	logResponse, err := fetchFluentdLogs(logsApiKey)
	if err != nil {
		t.Fatalf("Failed to fetch logs: %v", err)
	}

	if logResponse.Hits.Total == 0 {
		t.Errorf("No logs found")
	}

	for _, hit := range logResponse.Hits.Hits {
		kubernetes := hit.Source
		if isAnyFieldEmpty(reflect.ValueOf(kubernetes)) {
			logger.Error("Missing log fields", zap.Any("log", hit))
			t.Errorf("Missing log fields")
			break
		}
	}
}
func fetchFluentdLogs(logsApiKey string) (*FluentdResponse, error) {
	url := fmt.Sprintf("%s/search", BaseLogzioApiUrl)
	client := &http.Client{}
	envID := os.Getenv("ENV_ID")
	query := fmt.Sprintf("env_id:%s AND _exists_:fluentd_tags", envID)
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

	var logResponse FluentdResponse
	err = json.Unmarshal(body, &logResponse)
	if err != nil {
		return nil, err
	}

	return &logResponse, nil
}

func isAnyFieldEmpty(logRes reflect.Value) bool {
	for i := 0; i < logRes.NumField(); i++ {
		switch logRes.Field(i).Kind() {
		case reflect.String:
			if logRes.Field(i).String() == "" {
				return true
			}
		case reflect.Struct:
			if isAnyFieldEmpty(logRes.Field(i)) {
				return true
			}
		}
	}
	return false
}
