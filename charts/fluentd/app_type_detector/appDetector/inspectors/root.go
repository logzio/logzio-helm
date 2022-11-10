package inspectors

import (
	"github.com/logzio/app-type-detector/appDetector/process"
)

type inspector interface {
	Inspect(process *process.Details) (string, bool)
}

var inspectors = []inspector{application}

// DetectApplication returns a list of all the detected languages in the process list
// For go applications the process path is also returned, in all other languages the value is empty
func DetectApplication(processes []process.Details) ([]string, string) {
	var result []string
	processName := ""
	for _, p := range processes {
		for _, i := range inspectors {
			inspectionResult, detected := i.Inspect(&p)
			if detected {
				result = append(result, inspectionResult)
				break
			}
		}
	}

	return result, processName
}
