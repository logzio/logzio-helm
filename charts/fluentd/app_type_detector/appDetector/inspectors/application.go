package inspectors

import (
	"github.com/logzio/app-type-detector/appDetector/process"
	"github.com/logzio/app-type-detector/common"
	"regexp"
)

type ApplicationInspector struct{}

var application = &ApplicationInspector{}

/*
*
Returns an application name if that name exists in either exe or command line
*/
func (appInspector *ApplicationInspector) Inspect(process *process.Details) (string, bool) {

	detectedApps := make(map[string]bool)

	for _, applicationType := range common.Applications {
		match, _ := regexp.MatchString("\\b"+string(applicationType)+"\\b", process.ExeName)

		if match {
			detectedApps[string(applicationType)] = true
		}

		//if strings.Contains(process.ExeName, string(applicationType)) {
		//	detectedApps[string(applicationType)] = true
		//}

	}

	for _, applicationType := range common.Applications {
		match, _ := regexp.MatchString("\\b"+string(applicationType)+"\\b", process.CmdLine)

		if match {
			detectedApps[string(applicationType)] = true
		}

		//if strings.Contains(process.CmdLine, string(applicationType)) {
		//	detectedApps[string(applicationType)] = true
		//}
	}

	if len(detectedApps) == 1 {
		return getFirstAppInMap(detectedApps), true
	}

	if len(detectedApps) > 1 {
		return findBestAppMatch(detectedApps), true
	}
	return "", false
}

func getFirstAppInMap(detectedApps map[string]bool) string {
	for key := range detectedApps {
		return key
	}

	return ""
}

/**
return best match for detected app names -as of now calculated by length
*/
func findBestAppMatch(apps map[string]bool) string {
	topKey := ""
	for key, _ := range apps {
		if len(key) > len(topKey) {
			topKey = key
		}
	}

	return topKey
}
