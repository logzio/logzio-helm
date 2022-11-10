package controllers

import (
	"context"
	"errors"
	apiV1 "github.com/logzio/app-type-detector/api/v1alpha1"
	"github.com/logzio/app-type-detector/common/consts"
	"github.com/logzio/app-type-detector/instrumentor/patch"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"
)

var (
	IgnoredNamespaces = []string{"kube-system", "local-path-storage", "gatekeeper-system", consts.DefaultMonitoringNamespace}
	SkipAnnotation    = "logzio.io/skip_app_detection"
)

func skipAppDetectorSync(annotations map[string]string, namespace string) bool {
	for k, v := range annotations {
		if k == SkipAnnotation && v == "true" {
			return true
		}
	}

	for _, ns := range IgnoredNamespaces {
		if namespace == ns {
			return true
		}
	}

	return false
}

func syncAppDetectors(ctx context.Context, req *ctrl.Request, c client.Client, scheme *runtime.Scheme,
	readyReplicas int32, object client.Object, podTemplateSpec *v1.PodTemplateSpec, ownerKey string) error {

	logger := log.FromContext(ctx)
	detectedApps, err := getDetectedApps(ctx, req, c, ownerKey)
	if err != nil {
		logger.Info("error finding detected apps objects", "error", err)
		return err
	}

	if len(detectedApps.Items) == 0 {
		if readyReplicas == 0 {
			logger.Info("not enough ready replicas, waiting for pods to be ready")
			return nil
		}

		initDetect := new(bool)
		*initDetect = false
		appDetector := apiV1.AppDetector{
			ObjectMeta: metav1.ObjectMeta{
				Name:      req.Name,
				Namespace: req.Namespace,
			},
			Status: apiV1.AppDetectorStatus{
				Detected: false,
			},
			Spec: apiV1.AppDetectorSpec{
				Detected: initDetect,
			},
		}

		err = ctrl.SetControllerReference(object, &appDetector, scheme)
		if err != nil {
			logger.Error(err, "error creating app detector object")
			return err
		}

		err = c.Create(ctx, &appDetector)
		logger.V(5).Info("Creating app detector")
		if err != nil {
			logger.Error(err, "error creating app detector object")
			return err
		}

		appDetector.Status = apiV1.AppDetectorStatus{
			AppDetection: apiV1.AppDetectionStatus{
				Phase: apiV1.PendingAppDetectionPhase,
			},
			Detected: false,
		}
		err = c.Status().Update(ctx, &appDetector)
		logger.V(5).Info("Updated app detector pod status to pending")
		if err != nil {
			logger.Error(err, "error creating app detector object")
		}

		return nil
	}

	if len(detectedApps.Items) > 1 {
		return errors.New("found more than one detected application for deployment")
	}

	// If app not detected yet - nothing to do
	detectedApp := detectedApps.Items[0]
	if len(detectedApp.Spec.Applications) == 0 || detectedApp.Status.AppDetection.Phase != apiV1.CompletedAppDetectionPhase {
		logger.V(5).Info("No new applications detected or app detection is still in progress")
		return nil
	}

	// if instrumentation conditions are met

	//Compute .status.instrumented field
	detected, err := patch.IsDetected(ctx, podTemplateSpec, &detectedApp)
	if err != nil {
		logger.Error(err, "error computing app detector status")
		return err
	}

	var updatedApp apiV1.AppDetector
	if detected != detectedApp.Status.Detected {
		detectedApp.Status.Detected = detected

		c.Get(ctx, req.NamespacedName, &detectedApp)
		updatedApp.Status.Detected = detected
		err = c.Status().Update(ctx, &detectedApp)
		if err != nil {
			logger.Error(err, "Error computing app detector status")
		}
	}

	if detected {
		err = patch.ModifyObject(ctx, podTemplateSpec, &detectedApp)
		if err != nil {
			logger.Error(err, "error patching deployment / statefulset")
			return err
		}

		err = c.Update(ctx, &detectedApp)
		if err != nil {
			logger.Error(err, "error updating annotation in application")
			return err
		}

		err = c.Update(ctx, object)
		if err != nil {
			logger.Error(err, "error detecting application")
			return err
		}
	}

	return nil
}

func getDetectedApps(ctx context.Context, req *ctrl.Request, c client.Client, ownerKey string) (*apiV1.AppDetectorList, error) {
	var detectedApps apiV1.AppDetectorList
	err := c.List(ctx, &detectedApps, client.InNamespace(req.Namespace), client.MatchingFields{ownerKey: req.Name})
	if err != nil {
		return nil, err
	}

	return &detectedApps, nil
}
