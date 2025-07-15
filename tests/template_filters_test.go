package tests

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"
)

type K8sManifest struct {
	Kind     string `yaml:"kind"`
	Metadata struct {
		Name string `yaml:"name"`
	} `yaml:"metadata"`
	Data map[string]string `yaml:"data"`
}

type ChartCase struct {
	Name          string
	ChartPath     string
	ConfigMapName string
	ExtraArgs     []string
}

type filterProc struct {
	ErrorMode string              `yaml:"error_mode"`
	Logs      map[string][]string `yaml:"logs,omitempty"`
	Traces    map[string][]string `yaml:"traces,omitempty"`
}

type relayConfig struct {
	Processors map[string]filterProc `yaml:"processors"`
}

// Add expected OTTL rules for each test case (logs and apm use same logic)
var expected = map[string]struct {
	exclude []string
	include []string
}{
	"case-advanced-1.yaml": {
		exclude: []string{
			`IsMatch(resource.attributes["k8s.namespace.name"], "kube-system|monitoring")`,
			`IsMatch(resource.attributes["k8s.pod.name"], "^debug-.*$")`,
			`IsMatch(resource.attributes["service.name"], "^synthetic-.*$")`,
		},
		include: []string{
			`not (IsMatch(attributes["deployment.environment"], "prod|stage"))`,
			`not (IsMatch(resource.attributes["k8s.namespace.name"], "prod|stage"))`,
			`not (IsMatch(resource.attributes["service.name"], "^app-.*$"))`,
		},
	},
	"case-advanced-2.yaml": {
		exclude: []string{
			`IsMatch(attributes["log.level"], "debug|trace")`,
			`IsMatch(resource.attributes["k8s.pod.name"], "^test-.*$")`,
		},
		include: []string{
			`not (IsMatch(resource.attributes["k8s.namespace.name"], "prod"))`,
			`not (IsMatch(resource.attributes["service.name"], "^(api|web)-.*$"))`,
		},
	},
	"case-combo.yaml": {
		exclude: []string{
			`IsMatch(attributes["log.level"], "debug")`,
		},
		include: []string{
			`not (IsMatch(resource.attributes["k8s.namespace.name"], "prod"))`,
		},
	},
	"case-exclude-kube.yaml": {
		exclude: []string{
			`IsMatch(resource.attributes["k8s.namespace.name"], "kube-system")`,
		},
	},
	"case-include-prod.yaml": {
		include: []string{
			`not (IsMatch(resource.attributes["k8s.namespace.name"], "prod"))`,
		},
	},
	"case-none.yaml": {},
}

func TestHelmFilterTemplates(t *testing.T) {
	charts := []ChartCase{
		{
			Name:          "logs",
			ChartPath:     "../charts/logzio-logs-collector",
			ConfigMapName: "logzio-logs-collector-daemonset",
			ExtraArgs:     []string{"--set", "global.logzioLogsToken=dummy"},
		},
		{
			Name:          "apm",
			ChartPath:     "../charts/logzio-apm-collector",
			ConfigMapName: "logzio-apm-collector",
			ExtraArgs:     []string{"--set", "enabled=true", "--set", "global.logzioTracesToken=dummy"},
		},
	}

	filterDir := "./filters"
	files, err := filepath.Glob(filepath.Join(filterDir, "*.yaml"))
	if err != nil {
		t.Fatalf("failed to list filter cases: %v", err)
	}
	if len(files) == 0 {
		t.Fatalf("no filter test cases found in %s", filterDir)
	}

	exclude := map[string]bool{
		"relable-filters.yaml": true,
		"relable-simple.yaml":  true,
	}

	for _, chart := range charts {
		for _, valuesFile := range files {
			base := filepath.Base(valuesFile)
			if exclude[base] {
				continue
			}
			caseName := fmt.Sprintf("%s_%s", chart.Name, base)
			t.Run(caseName, func(t *testing.T) {
				args := append([]string{"template", "test", chart.ChartPath, "-f", valuesFile}, chart.ExtraArgs...)
				cmd := exec.Command("helm", args...)
				out, err := cmd.CombinedOutput()
				if err != nil {
					t.Fatalf("helm template failed: %v\n%s", err, out)
				}
				manifests := splitYAMLDocs(string(out))
				var found bool
				for _, manifest := range manifests {
					var k8s K8sManifest
					if err := yaml.Unmarshal([]byte(manifest), &k8s); err != nil {
						continue
					}
					if k8s.Kind == "ConfigMap" && k8s.Metadata.Name == chart.ConfigMapName {
						found = true
						relay := k8s.Data["relay"]
						filename := filepath.Base(valuesFile)
						exp := expected[filename]
						assertFilterRules(t, relay, filename, exp.exclude, exp.include)
					}
				}
				if !found {
					t.Errorf("ConfigMap %s not found in rendered output", chart.ConfigMapName)
				}
			})
		}
	}
}

// splitYAMLDocs splits a multi-doc YAML string into individual docs
func splitYAMLDocs(yamlStr string) []string {
	docs := strings.Split(yamlStr, "\n---")
	var out []string
	for _, doc := range docs {
		doc = strings.TrimSpace(doc)
		if doc != "" {
			out = append(out, doc)
		}
	}
	return out
}

// assertFilterProcessors checks that filter/exclude and/or filter/include are present and after k8sattributes if expected
func assertFilterProcessors(t *testing.T, relay string, valuesFile string) bool {
	if !strings.Contains(relay, "processors:") {
		t.Errorf("no processors section in relay config for %s", valuesFile)
		return false
	}
	lines := strings.Split(relay, "\n")
	var order []string
	for _, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "- ") {
			order = append(order, strings.TrimSpace(strings.TrimPrefix(line, "- ")))
		}
	}

	k8sIdx := indexOf(order, "k8sattributes")
	exIdx := indexOf(order, "filter/exclude")
	inIdx := indexOf(order, "filter/include")
	if exIdx != -1 && k8sIdx != -1 && exIdx < k8sIdx {
		t.Errorf("filter/exclude appears before k8sattributes")
		return false
	}
	if inIdx != -1 && k8sIdx != -1 && inIdx < k8sIdx {
		t.Errorf("filter/include appears before k8sattributes")
		return false
	}
	return true
}

func contains(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}

func indexOf(list []string, s string) int {
	for i, v := range list {
		if v == s {
			return i
		}
	}
	return -1
}

func assertFilterRules(t *testing.T, relay string, valuesFile string, expectedExclude, expectedInclude []string) {
	t.Helper()
	var cfg relayConfig
	if err := yaml.Unmarshal([]byte(relay), &cfg); err != nil {
		t.Fatalf("failed to parse relay YAML: %v", err)
	}
	if len(expectedExclude) > 0 {
		actual := getFilterExprs(cfg, "filter/exclude")
		if !equalStringSlices(actual, expectedExclude) {
			t.Errorf("exclude rules mismatch for %s:\nexpected: %#v\ngot: %#v", valuesFile, expectedExclude, actual)
		}
	}
	if len(expectedInclude) > 0 {
		actual := getFilterExprs(cfg, "filter/include")
		if !equalStringSlices(actual, expectedInclude) {
			t.Errorf("include rules mismatch for %s:\nexpected: %#v\ngot: %#v", valuesFile, expectedInclude, actual)
		}
	}
	if valuesFile != "case-none.yaml" && len(expectedExclude) == 0 && len(expectedInclude) == 0 {
		t.Errorf("Test case %s: expected at least one filter rule, but none provided in expected map", valuesFile)
	}
	if valuesFile != "case-none.yaml" {
		actualExclude := getFilterExprs(cfg, "filter/exclude")
		actualInclude := getFilterExprs(cfg, "filter/include")
		if len(actualExclude) == 0 && len(actualInclude) == 0 {
			t.Errorf("Test case %s: expected at least one filter processor in rendered config, but got none", valuesFile)
		}
	}
}

func getFilterExprs(cfg relayConfig, key string) []string {
	proc, ok := cfg.Processors[key]
	if !ok {
		return nil
	}
	if len(proc.Logs) > 0 {
		return proc.Logs["log_record"]
	}
	if len(proc.Traces) > 0 {
		return proc.Traces["span"]
	}
	return nil
}

func equalStringSlices(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// --- Relabel config tests for logzio-telemetry ---
type TelemetryScrapeConfig struct {
	JobName              string        `yaml:"job_name"`
	RelabelConfigs       []interface{} `yaml:"relabel_configs"`
	MetricRelabelConfigs []interface{} `yaml:"metric_relabel_configs"`
}

type TelemetryPrometheusReceiver struct {
	Config struct {
		ScrapeConfigs []TelemetryScrapeConfig `yaml:"scrape_configs"`
	} `yaml:"config"`
}

type TelemetryRelayRoot struct {
	Receivers map[string]TelemetryPrometheusReceiver `yaml:"receivers"`
}

type relabelRule struct {
	action       string
	sourceLabels []string
	targetLabel  string
	regex        string
}

func TestHelmTelemetryRelabelConfigs(t *testing.T) {
	chartPath := "../charts/logzio-telemetry"
	configMapNames := []string{"test-otel-collector-ds", "test-otel-collector-standalone", "logzio-k8s-telemetry-otel-collector-ds", "logzio-k8s-telemetry-otel-collector-standalone"}

	// Define expected relabel rules for each test case and pipeline/job
	cases := []struct {
		name       string
		valuesFile string
		expect     map[string][]relabelRule // pipeline -> expected rules
	}{
		{
			name:       "relable-simple",
			valuesFile: "../tests/filters/relable-simple.yaml",
			expect: map[string][]relabelRule{
				"prometheus/infrastructure": {
					{action: "drop", targetLabel: "namespace", regex: "kube-system"},
				},
				"prometheus/applications": {
					{action: "keep", targetLabel: "namespace", regex: "prod"},
				},
			},
		},
		{
			name:       "relable-filters",
			valuesFile: "../tests/filters/relable-filters.yaml",
			expect: map[string][]relabelRule{
				"prometheus/infrastructure": {
					{action: "drop", targetLabel: "namespace", regex: "kube-system|monitoring"},
					{action: "drop", targetLabel: "deployment.environment", regex: "dev|test"},
					{action: "drop", targetLabel: "service.tier", regex: "internal"},
					{action: "keep", targetLabel: "deployment.environment", regex: "prod"},
				},
				"prometheus/applications": {
					{action: "drop", targetLabel: "name", regex: "go_gc_duration_seconds|http_requests_total"},
					{action: "keep", targetLabel: "namespace", regex: "prod|staging"},
					{action: "keep", targetLabel: "http.status_code", regex: "2..|3.."},
				},
			},
		},
	}

	for _, mode := range []string{"daemonset", "standalone"} {
		for _, tc := range cases {
			t.Run(tc.name+"_"+mode, func(t *testing.T) {
				args := []string{"template", "test", chartPath, "-f", tc.valuesFile, "--set", "collector.mode=" + mode, "--set", "metrics.enabled=true", "--set", "applicationMetrics.enabled=true", "--set", "global.logzioMetricsToken=dummy"}
				cmd := exec.Command("helm", args...)
				out, err := cmd.CombinedOutput()
				if err != nil {
					t.Logf("helm template failed: %v\n%s", err, out)
					manifests := splitYAMLDocs(string(out))
					var foundNames []string
					for _, manifest := range manifests {
						var k8s K8sManifest
						if err := yaml.Unmarshal([]byte(manifest), &k8s); err == nil && k8s.Kind == "ConfigMap" {
							foundNames = append(foundNames, k8s.Metadata.Name)
						}
					}
					t.Logf("ConfigMaps found in rendered output: %v", foundNames)
					t.Fatalf("helm template failed: %v", err)
				}
				manifests := splitYAMLDocs(string(out))
				var found bool
				var foundNames []string
				for _, manifest := range manifests {
					var k8s K8sManifest
					if err := yaml.Unmarshal([]byte(manifest), &k8s); err != nil {
						continue
					}
					if k8s.Kind == "ConfigMap" {
						foundNames = append(foundNames, k8s.Metadata.Name)
					}
					if k8s.Kind == "ConfigMap" && contains(configMapNames, k8s.Metadata.Name) {
						found = true
						relay := k8s.Data["relay"]
						var relayCfg TelemetryRelayRoot
						if err := yaml.Unmarshal([]byte(relay), &relayCfg); err != nil {
							t.Fatalf("failed to parse relay YAML: %v", err)
						}
						for pipeline, wantRules := range tc.expect {
							receiver, ok := relayCfg.Receivers[pipeline]
							if !ok {
								t.Errorf("receiver %s not found in relay config for %s", pipeline, k8s.Metadata.Name)
								continue
							}
							var got []map[string]interface{}
							for _, sc := range receiver.Config.ScrapeConfigs {
								for _, relabel := range sc.RelabelConfigs {
									if m, ok := relabel.(map[string]interface{}); ok {
										got = append(got, m)
									}
								}
							}
							for _, want := range wantRules {
								if !relabelRulePresent(got, want) {
									t.Errorf("expected relabel rule not found in %s: action=%s target_label=%s regex=%s", pipeline, want.action, want.targetLabel, want.regex)
									t.Logf("Full relay YAML for %s: \n%s", k8s.Metadata.Name, relay)
								}
							}
						}
					}
				}
				if !found {
					t.Logf("ConfigMaps found in rendered output: %v", foundNames)
					t.Errorf("ConfigMap not found in rendered output for mode %s", mode)
				}
			})
		}
	}
}

func relabelRulePresent(got []map[string]interface{}, want relabelRule) bool {
	for _, m := range got {
		if m["action"] == want.action && m["target_label"] == want.targetLabel {
			if want.regex == "" || m["regex"] == want.regex {
				return true
			}
		}
	}
	return false
}
