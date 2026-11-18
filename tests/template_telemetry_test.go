package tests

import (
	"os/exec"
	"regexp"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"
)

const ownNode = "${KUBE_NODE_NAME}"

type renderedDoc struct {
	Kind     string `yaml:"kind"`
	Metadata struct {
		Name string `yaml:"name"`
	} `yaml:"metadata"`
	Spec struct {
		Replicas *int `yaml:"replicas"`
	} `yaml:"spec"`
	Data map[string]string `yaml:"data"`
}

type scrapeJob struct {
	JobName             string `yaml:"job_name"`
	KubernetesSdConfigs []struct {
		Role      string `yaml:"role"`
		Selectors []struct {
			Field string `yaml:"field"`
		} `yaml:"selectors"`
	} `yaml:"kubernetes_sd_configs"`
	RelabelConfigs []struct {
		Action       string   `yaml:"action"`
		Regex        string   `yaml:"regex"`
		SourceLabels []string `yaml:"source_labels"`
	} `yaml:"relabel_configs"`
}

type collectorConfig struct {
	Receivers map[string]struct {
		Config struct {
			ScrapeConfigs []scrapeJob `yaml:"scrape_configs"`
		} `yaml:"config"`
	} `yaml:"receivers"`
}

func helmTemplate(t *testing.T, chart string, args ...string) []renderedDoc {
	t.Helper()
	out, err := exec.Command("helm", append([]string{"template", "test", chart}, args...)...).CombinedOutput()
	if err != nil {
		t.Fatalf("helm template failed: %v\n%s", err, out)
	}
	var docs []renderedDoc
	for _, raw := range splitYAMLDocs(string(out)) {
		var d renderedDoc
		if err := yaml.Unmarshal([]byte(raw), &d); err != nil {
			t.Fatalf("rendered manifest is not valid YAML: %v\n%s", err, raw)
		}
		docs = append(docs, d)
	}
	return docs
}

func collectorConfigs(docs []renderedDoc) map[string]string {
	configs := map[string]string{}
	for _, d := range docs {
		if relay, ok := d.Data["relay"]; d.Kind == "ConfigMap" && ok {
			configs[d.Metadata.Name] = relay
		}
	}
	return configs
}

var telemetryDaemonsetArgs = []string{
	"--set", "collector.mode=daemonset",
	"--set", "metrics.enabled=true",
	"--set", "applicationMetrics.enabled=true",
	"--set", "global.windows.enabled=true",
	"--set", "global.logzioMetricsToken=dummy",
}

func TestTelemetryDaemonsetScrapesOnlyOwnNode(t *testing.T) {
	configs := collectorConfigs(helmTemplate(t, "../charts/logzio-telemetry", telemetryDaemonsetArgs...))
	checked := map[string]bool{}
	for name, relay := range configs {
		var cfg collectorConfig
		if err := yaml.Unmarshal([]byte(relay), &cfg); err != nil {
			t.Fatalf("failed to parse collector config of %s: %v", name, err)
		}
		for _, receiver := range cfg.Receivers {
			for _, job := range receiver.Config.ScrapeConfigs {
				for _, sd := range job.KubernetesSdConfigs {
					checked[job.JobName] = true
					if !scopedToOwnNode(job, sd.Role) {
						t.Errorf("%s: job %s (role %s) is not limited to the collector's own node", name, job.JobName, sd.Role)
					}
				}
			}
		}
	}
	for _, job := range []string{"kubernetes-nodes", "kubernetes-cadvisor", "kubernetes-service-endpoints", "applications", "windows-metrics"} {
		if !checked[job] {
			t.Errorf("expected scrape job %s not found in daemonset collector config", job)
		}
	}
}

func scopedToOwnNode(job scrapeJob, role string) bool {
	if role == "node" {
		for _, sd := range job.KubernetesSdConfigs {
			for _, s := range sd.Selectors {
				if s.Field == "metadata.name="+ownNode {
					return true
				}
			}
		}
		return false
	}
	for _, r := range job.RelabelConfigs {
		if r.Action == "keep" && r.Regex == ownNode && len(r.SourceLabels) == 1 && strings.HasSuffix(r.SourceLabels[0], "_node_name") {
			return true
		}
	}
	return false
}

func TestCollectorConfigsHaveNoBareEnvVars(t *testing.T) {
	bareVar := regexp.MustCompile(`(?:^|[^$])(\$[A-Za-z_][A-Za-z0-9_]*)`)
	cases := []struct {
		chart string
		args  []string
	}{
		{"../charts/logzio-telemetry", telemetryDaemonsetArgs},
		{"../charts/logzio-telemetry", []string{"--set", "collector.mode=standalone", "--set", "metrics.enabled=true", "--set", "applicationMetrics.enabled=true", "--set", "k8sObjectsConfig.enabled=true", "--set", "global.logzioMetricsToken=dummy", "--set", "global.logzioLogsToken=dummy"}},
		{"../charts/logzio-logs-collector", []string{"--set", "global.logzioLogsToken=dummy"}},
		{"../charts/logzio-apm-collector", []string{"--set", "enabled=true", "--set", "spm.enabled=true", "--set", "serviceGraph.enabled=true", "--set", "global.logzioTracesToken=dummy", "--set", "global.logzioSpmToken=dummy"}},
	}
	for _, c := range cases {
		for name, relay := range collectorConfigs(helmTemplate(t, c.chart, c.args...)) {
			for _, line := range strings.Split(relay, "\n") {
				if m := bareVar.FindStringSubmatch(line); m != nil {
					t.Errorf("%s: %s is not expanded by the collector, use ${%s}: %s", name, m[1], m[1][1:], strings.TrimSpace(line))
				}
			}
		}
	}
}

func TestTelemetryK8sObjectsRunsOnce(t *testing.T) {
	for _, mode := range []string{"daemonset", "standalone"} {
		t.Run(mode, func(t *testing.T) {
			docs := helmTemplate(t, "../charts/logzio-telemetry",
				"--set", "collector.mode="+mode,
				"--set", "metrics.enabled=true",
				"--set", "k8sObjectsConfig.enabled=true",
				"--set", "global.logzioMetricsToken=dummy",
				"--set", "global.logzioLogsToken=dummy")
			var withK8sObjects []string
			for name, relay := range collectorConfigs(docs) {
				var cfg collectorConfig
				if err := yaml.Unmarshal([]byte(relay), &cfg); err != nil {
					t.Fatalf("failed to parse collector config of %s: %v", name, err)
				}
				for receiver := range cfg.Receivers {
					if receiver == "k8sobjects" || strings.HasPrefix(receiver, "k8sobjects/") {
						withK8sObjects = append(withK8sObjects, name)
						break
					}
				}
			}
			if len(withK8sObjects) != 1 || withK8sObjects[0] != "test-otel-collector-k8s-objects" {
				t.Errorf("k8sobjects receiver should only be in test-otel-collector-k8s-objects, found in %v", withK8sObjects)
			}
			for _, d := range docs {
				if d.Kind == "Deployment" && d.Metadata.Name == "test-otel-collector-k8s-objects" {
					if d.Spec.Replicas == nil || *d.Spec.Replicas != 1 {
						t.Errorf("k8s objects deployment should have exactly 1 replica")
					}
					return
				}
			}
			t.Errorf("deployment test-otel-collector-k8s-objects not rendered")
		})
	}
}

func TestTelemetryOptionalFeaturesRender(t *testing.T) {
	base := []string{"--set", "metrics.enabled=true", "--set", "global.logzioMetricsToken=dummy", "--set", "global.logzioLogsToken=dummy"}
	features := map[string][]string{
		"opencost":            {"--set", "opencost.enabled=true"},
		"carbon":              {"--set", "carbon.enabled=true"},
		"windows":             {"--set", "global.windows.enabled=true"},
		"podDisruptionBudget": {"--set", "podDisruptionBudget.enabled=true"},
		"autoscaling":         {"--set", "collector.mode=standalone", "--set", "standaloneCollector.enabled=true", "--set", "autoscaling.enabled=true"},
	}
	for name, args := range features {
		t.Run(name, func(t *testing.T) {
			helmTemplate(t, "../charts/logzio-telemetry", append(append([]string{}, base...), args...)...)
		})
	}
}
