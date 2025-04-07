package tests

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"testing"
)

func TestTolerations(t *testing.T) {
	globalToleration := map[string]string{
		"key":      "global-key",
		"operator": "Equal",
		"value":    "global-value",
		"effect":   "NoSchedule",
	}

	apmToleration := map[string]string{
		"key":      "chart-key",
		"operator": "Equal",
		"value":    "chart-value",
		"effect":   "NoExecute",
	}

	subcharts := map[string][]map[string]string{
		"logzio-apm-collector":  {globalToleration, apmToleration},
		"logzio-logs-collector": {globalToleration},
		"logzio-k8s-telemetry":  {globalToleration},
		"logzio-fluentd":        {globalToleration},
	}

	for chart, expectedTolerations := range subcharts {
		t.Run(fmt.Sprintf("Verify tolerations for %s", chart), func(t *testing.T) {
			podName := getPodName(chart)
			namespace := "default"
			tolerations, err := fetchTolerations(podName, namespace)
			if err != nil {
				t.Fatalf("Failed to fetch tolerations for %s: %v", chart, err)
			}

			// Verify tolerations
			for _, expected := range expectedTolerations {
				found := false
				for _, toleration := range tolerations {
					if toleration["key"] == expected["key"] &&
						toleration["operator"] == expected["operator"] &&
						toleration["value"] == expected["value"] &&
						toleration["effect"] == expected["effect"] {
						found = true
						break
					}
				}
				if !found {
					t.Errorf("Toleration not found for %s: %v", chart, expected)
				}
			}
		})
	}
}

func getPodName(chart string) string {
	podNames := map[string]string{
		"logzio-apm-collector":  "logzio-apm-collector",
		"logzio-logs-collector": "logzio-logs-collector",
		"logzio-k8s-telemetry":  "logzio-k8s-telemetry",
	}
	return podNames[chart]
}

func fetchTolerations(podName, namespace string) ([]map[string]string, error) {
	cmd := exec.Command("kubectl", "get", "pod", "-l", fmt.Sprintf("app=%s", podName), "-n", namespace, "-o", "jsonpath={.items[0].spec.tolerations}")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	var tolerations []map[string]string
	err = json.Unmarshal(output, &tolerations)
	if err != nil {
		return nil, err
	}

	return tolerations, nil
}
