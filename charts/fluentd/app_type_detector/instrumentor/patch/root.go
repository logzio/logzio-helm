package patch

import (
	"context"
	"fmt"
	apiV1 "github.com/logzio/app-type-detector/api/v1alpha1"
	"github.com/logzio/app-type-detector/common"
	v1 "k8s.io/api/core/v1"
	"sigs.k8s.io/controller-runtime/pkg/log"
)

type Patcher interface {
	Patch(podSpec *v1.PodTemplateSpec, detected *apiV1.AppDetector)
	shouldPatch(podSpec *v1.PodTemplateSpec) bool
}

var patcherMap = map[string]Patcher{}

func ModifyObject(ctx context.Context, original *v1.PodTemplateSpec, detectedApplication *apiV1.AppDetector) error {
	for _, app := range getApplicationsInResult(ctx, detectedApplication) {
		p, exists := patcherMap[app]
		if !exists {
			return fmt.Errorf("unable to find patcher for app %s", app)
		}

		p.Patch(original, detectedApplication)
	}

	return nil
}

func IsDetected(ctx context.Context, original *v1.PodTemplateSpec, detectedApp *apiV1.AppDetector) (bool, error) {
	isDetected := true
	for _, app := range getApplicationsInResult(ctx, detectedApp) {
		p, exists := patcherMap[app]
		if !exists {
			return false, fmt.Errorf("unable to find patcher for %s", app)
		}

		isDetected = isDetected && p.shouldPatch(original)
	}

	return isDetected, nil
}

/**
get running detected applications
*/
func getApplicationsInResult(ctx context.Context, detectedApplication *apiV1.AppDetector) []string {
	logger := log.FromContext(ctx)
	appMap := make(map[string]interface{})
	for _, appByContainer := range detectedApplication.Spec.Applications {
		logger.V(5).Info("Added detected app to result", "app", appByContainer)
		appMap[string(appByContainer.Application)] = nil
	}

	var apps []string
	for app, _ := range appMap {
		apps = append(apps, app)
	}

	return apps
}

func init() {
	addAnnotationPatcher()
}

func addAnnotationPatcher() {
	for _, app := range common.Applications {
		patcherMap[string(app)] = annotationPatcher
	}
}
