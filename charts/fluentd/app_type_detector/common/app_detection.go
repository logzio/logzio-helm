package common

type ApplicationByContainer struct {
	ContainerName string      `json:"containerName"`
	Application   Application `json:"application"`
	ProcessName   string      `json:"processName,omitempty"`
}

type Application string

var Applications = []Application{
	"alcide-kaudit",
	"apache_access",
	"apache-access",
	"apache",
	"auditd",
	"cloudfront",
	"cloudtrail",
	"elb",
	"fargate",
	"guardduty",
	"route_53",
	"S3Access",
	"vpcflow",
	"awswaf",
	"checkpoint",
	"cisco-asa",
	"cisco-meraki",
	"crowdstrike",
	"docker_logs",
	"docker-collector-logs",
	"elasticsearch",
	"fail2ban",
	"falco",
	"fargate",
	"fortigate",
	"github",
	"gpfs",
	"haproxy",
	"jenkins",
	"juniper",
	"kafka_server",
	"kafka-server",
	"k8s",
	"mcafee_epo",
	"iis",
	"modsecurity",
	"mongodb",
	"monit",
	"mysql_error",
	"mysql_monitor",
	"mysql_slow_query",
	"mysql",
	"nagios",
	"nginx_access",
	"nginx-access",
	"nginx-error",
	"nginx",
	"openvas",
	"openvpn",
	"ossec",
	"trendmicro_deep",
	"paloalto",
	"performance-tab",
	"pfsense",
	"sonicwall",
	"sophos-ep",
	"stormshield",
	"wineventlog",
	"zeek",
	"zipkinSpan",
}

//var mysqlApps = map[string]int{
//	"mysql_monitor": 2,
//	"mysql":         1,
//
//	"kafka_server": 2,
//	"kafka-server": 2,
//	"apache":       1,
//
//	"nginx_access": 2,
//	"nginx-access": 2,
//	"nginx":        1,
//
//	"docker_logs":           1,
//	"docker-collector-logs": 2,
//
//	"apache_access": 2,
//	"apache-access": 2,
//}
