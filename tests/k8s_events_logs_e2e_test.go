package tests

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"go.uber.org/zap"
)

// Matches tests/resources/k8s-events-workload.yaml and the updates the workflow applies to it
const (
	k8sEventsNamespace = "k8s-events-e2e"
	k8sEventsTimeout   = 5 * time.Minute
)

// Marker values in the test resources. None of them may reach Logz.io, plain or base64 encoded
var k8sEventsPlaintextValues = []string{"E2E-MARKER-DATA", "E2E-MARKER-DATA-CHANGED", "E2E-MARKER-ENV"}

type k8sEventsLogsResponse struct {
	Hits struct {
		Total int `json:"total"`
		Hits  []struct {
			Source map[string]any `json:"_source"`
		} `json:"hits"`
	} `json:"hits"`
}

func TestK8sEventsLogs(t *testing.T) {
	logsApiKey := os.Getenv("LOGZIO_LOGS_API_KEY")
	if logsApiKey == "" {
		t.Fatalf("LOGZIO_LOGS_API_KEY environment variable not set")
	}
	envID := os.Getenv("ENV_ID")
	if envID == "" {
		t.Fatalf("ENV_ID environment variable not set")
	}
	query := fmt.Sprintf("env_id:%s AND type:logzio-k8s-events AND newObject.metadata.namespace:%s", envID, k8sEventsNamespace)

	// Logs take a while to be ingested, so poll until both update events arrive
	var events []map[string]any
	var secretUpdate, deploymentUpdate map[string]any
	deadline := time.Now().Add(k8sEventsTimeout)
	for {
		res, err := fetchK8sEventsLogs(logsApiKey, query)
		if err != nil {
			logger.Warn("Failed to fetch k8s events logs", zap.Error(err))
		} else {
			events = events[:0]
			for _, hit := range res.Hits.Hits {
				events = append(events, hit.Source)
			}
			secretUpdate = findK8sEvent(events, "Secret", "db")
			deploymentUpdate = findK8sEvent(events, "Deployment", "app")
		}
		if secretUpdate != nil && deploymentUpdate != nil {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("Missing k8s events after %s: secret update found: %t, deployment update found: %t", k8sEventsTimeout, secretUpdate != nil, deploymentUpdate != nil)
		}
		time.Sleep(15 * time.Second)
	}

	for _, event := range events {
		raw, _ := json.Marshal(event)
		for _, value := range k8sEventsPlaintextValues {
			if strings.Contains(string(raw), value) || strings.Contains(string(raw), base64.StdEncoding.EncodeToString([]byte(value))) {
				t.Errorf("Marker value %q was shipped in event: %s", value, event["message"])
			}
		}
		if strings.Contains(string(raw), "managedFields") {
			t.Errorf("managedFields was shipped in event: %s", event["message"])
		}
	}

	secretObject := k8sEventsMap(secretUpdate["newObject"])
	if secretObject["data_hashed"] == nil || secretObject["data"] != nil {
		t.Errorf("Expected the Secret data to be hashed, got: %v", secretObject)
	}
	relatedDeployments, _ := k8sEventsMap(secretUpdate["relatedClusterServices"])["deployments"].([]any)
	if len(relatedDeployments) != 1 || relatedDeployments[0] != "app" {
		t.Errorf("Expected the Secret to be related to the app Deployment, got: %v", secretUpdate["relatedClusterServices"])
	}

	newDeployment, oldDeployment := k8sEventsMap(deploymentUpdate["newObject"]), k8sEventsMap(deploymentUpdate["oldObject"])
	containers, _ := k8sEventsMap(k8sEventsMap(k8sEventsMap(newDeployment["spec"])["template"])["spec"])["containers"].(string)
	if !strings.Contains(containers, `{"name":"INTERNAL_ID","value_hashed":"`) || !strings.Contains(containers, `{"name":"LOG_LEVEL","value":"debug"}`) {
		t.Errorf("Expected only the sensitive env var to be hashed, got: %s", containers)
	}
	// The K8S 360 deployment markers detect rollouts from the generations of both objects
	newGeneration, _ := k8sEventsMap(newDeployment["metadata"])["generation"].(float64)
	oldGeneration, _ := k8sEventsMap(oldDeployment["metadata"])["generation"].(float64)
	if newGeneration <= oldGeneration || oldGeneration == 0 {
		t.Errorf("Expected the Deployment generation to increase, got old: %v, new: %v", oldGeneration, newGeneration)
	}
}

// findK8sEvent returns the update event of the resource, or nil if it wasn't shipped yet
func findK8sEvent(events []map[string]any, kind string, name string) map[string]any {
	for _, event := range events {
		newObject := k8sEventsMap(event["newObject"])
		if event["eventType"] == "MODIFIED" && newObject["kind"] == kind && k8sEventsMap(newObject["metadata"])["name"] == name {
			return event
		}
	}
	return nil
}

func k8sEventsMap(value any) map[string]any {
	m, _ := value.(map[string]any)
	return m
}

func fetchK8sEventsLogs(logsApiKey string, query string) (*k8sEventsLogsResponse, error) {
	url := fmt.Sprintf("%s/search", BaseLogzioApiUrl)
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
	var res k8sEventsLogsResponse
	if err := json.Unmarshal(body, &res); err != nil {
		return nil, err
	}
	return &res, nil
}
