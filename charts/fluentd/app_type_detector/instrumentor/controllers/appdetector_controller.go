/*
Copyright 2022.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	v1 "github.com/logzio/app-type-detector/api/v1alpha1"
	"github.com/logzio/app-type-detector/common"
	"github.com/logzio/app-type-detector/common/consts"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"strings"

	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"
)

var (
	podOwnerKey = ".metadata.controller"
	apiGVStr    = v1.GroupVersion.String()
)

// AppDetectorReconciler reconciles a AppDetector object
type AppDetectorReconciler struct {
	client.Client
	Scheme                *runtime.Scheme
	AppDetectorTag        string
	AppDetectorImage      string
	DeleteAppDetectorPods bool
}

// Reconcile is responsible for language detection. The function starts the lang detection process if the AppDetector
// object does not have a languages field. In addition, Reconcile will clean up lang detection pods upon completion / error
func (r *AppDetectorReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)
	var detectedApp v1.AppDetector
	err := r.Get(ctx, req.NamespacedName, &detectedApp)
	if err != nil {
		if apierrors.IsNotFound(err) {
			return ctrl.Result{}, nil
		}

		logger.Error(err, "error fetching object")
		return ctrl.Result{}, err
	}

	// If language already detected - there is nothing to do
	if r.isAppDetected(&detectedApp) {
		return ctrl.Result{}, nil
	}

	// Language not detected yet - start the lang detection process
	if r.shouldStartAppDetection(&detectedApp) {
		logger.V(0).Info("starting app detection process")

		detectedApp.Status.AppDetection.Phase = v1.RunningAppDetectionPhase
		err = r.Status().Update(ctx, &detectedApp)
		if err != nil {
			logger.Error(err, "error updating detection app status")
			return ctrl.Result{}, err
		}

		labels, err := r.getOwnerTemplateLabels(ctx, &detectedApp)
		if err != nil {
			logger.Error(err, "error getting owner labels")
			return ctrl.Result{}, err
		}

		err = r.detectApp(ctx, &detectedApp, labels)
		if err != nil {
			logger.Error(err, "error detecting application")
		}
		return ctrl.Result{}, err
	}

	if detectedApp.Status.AppDetection.Phase == v1.RunningAppDetectionPhase {
		var childPods corev1.PodList
		err = r.List(ctx, &childPods, client.InNamespace(req.Namespace), client.MatchingFields{podOwnerKey: req.Name})
		if err != nil {
			logger.Error(err, "could not find child pods")
			return ctrl.Result{}, err
		}
		for _, pod := range childPods.Items {
			// If pod finished -  read detection result
			if pod.Status.Phase == corev1.PodSucceeded && len(pod.Status.ContainerStatuses) > 0 {
				containerStatus := pod.Status.ContainerStatuses[0]
				if containerStatus.State.Terminated == nil {
					continue
				}

				// Write detection result
				result := containerStatus.State.Terminated.Message
				var detectionResult []common.ApplicationByContainer
				err = json.Unmarshal([]byte(result), &detectionResult)
				if err != nil {
					logger.Error(err, "error parsing detection result")
					return ctrl.Result{}, err
				} else {
					detectedApp.Spec.Applications = detectionResult
					err = r.Update(ctx, &detectedApp)
					if err != nil {
						logger.Error(err, "error updating app detector object with detection result")
						return ctrl.Result{}, err
					}

					logger.Info("Completed detection updating status")
					detectedApp.Status.AppDetection.Phase = v1.CompletedAppDetectionPhase
					err = r.Status().Update(ctx, &detectedApp)
					if err != nil {
						logger.Error(err, "error updating app detector object with detection result")
						return ctrl.Result{}, err
					}
				}
			} else if pod.Status.Phase == corev1.PodFailed {
				logger.V(0).Info("app detection pod failed. marking as error")
				detectedApp.Status.AppDetection.Phase = v1.ErrorAppDetectionPhase
				err = r.Status().Update(ctx, &detectedApp)
				if err != nil {
					logger.Error(err, "error updating app detector pod status")
					return ctrl.Result{}, err
				}
				return ctrl.Result{}, nil
			}
		}
	}

	// Clean up finished pods
	if detectedApp.Status.AppDetection.Phase == v1.CompletedAppDetectionPhase ||
		detectedApp.Status.AppDetection.Phase == v1.ErrorAppDetectionPhase {
		var childPods corev1.PodList
		err = r.List(ctx, &childPods, client.InNamespace(req.Namespace), client.MatchingFields{podOwnerKey: req.Name})
		if err != nil {
			logger.Error(err, "could not find child pods")
			return ctrl.Result{}, err
		}

		for _, pod := range childPods.Items {
			if pod.Status.Phase == corev1.PodSucceeded || pod.Status.Phase == corev1.PodFailed {
				if !r.DeleteAppDetectorPods {
					return ctrl.Result{}, nil
				}

				err = r.Client.Delete(ctx, &pod)
				if client.IgnoreNotFound(err) != nil {
					logger.Error(err, "failed to delete app detection pod")
					return ctrl.Result{}, err
				}
			}
		}
	}

	return ctrl.Result{}, nil
}

func (r *AppDetectorReconciler) shouldStartAppDetection(app *v1.AppDetector) bool {
	return app.Status.AppDetection.Phase == v1.PendingAppDetectionPhase
}

func (r *AppDetectorReconciler) isAppDetected(app *v1.AppDetector) bool {
	return len(app.Spec.Applications) > 0
}

func (r *AppDetectorReconciler) detectApp(ctx context.Context, app *v1.AppDetector, labels map[string]string) error {
	pod, err := r.choosePods(ctx, labels, app.Namespace)
	if err != nil {
		return err
	}

	langDetectionPod, err := r.createAppDetectionPod(pod, app)
	if err != nil {
		return err
	}

	err = r.Create(ctx, langDetectionPod)
	return err
}

func (r *AppDetectorReconciler) choosePods(ctx context.Context, labels map[string]string, namespace string) (*corev1.Pod, error) {
	var podList corev1.PodList
	err := r.List(ctx, &podList, client.MatchingLabels(labels), client.InNamespace(namespace))
	if err != nil {
		return nil, err
	}

	if len(podList.Items) == 0 {
		return nil, consts.PodsNotFoundErr
	}

	for _, pod := range podList.Items {
		if pod.Status.Phase == corev1.PodRunning {
			return &pod, nil
		}
	}

	return nil, consts.PodsNotFoundErr
}

func (r *AppDetectorReconciler) createAppDetectionPod(targetPod *corev1.Pod, instrumentedApp *v1.AppDetector) (*corev1.Pod, error) {
	pod := &corev1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			GenerateName: fmt.Sprintf("%s-app-detection-", targetPod.Name),
			Namespace:    targetPod.Namespace,
			Annotations: map[string]string{
				consts.AppDetectorContainerAnnotationKey: "true",
			},
		},
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{
				{
					Name:  "app-detector",
					Image: fmt.Sprintf("%s:%s", r.AppDetectorImage, r.AppDetectorTag),
					Args: []string{
						fmt.Sprintf("--pod-uid=%s", targetPod.UID),
						fmt.Sprintf("--container-names=%s", strings.Join(r.getContainerNames(targetPod), ",")),
					},
					TerminationMessagePath: "/dev/detection-result",
					SecurityContext: &corev1.SecurityContext{
						Capabilities: &corev1.Capabilities{
							Add: []corev1.Capability{"SYS_PTRACE"},
						},
					},
				},
			},
			RestartPolicy: "Never",
			NodeName:      targetPod.Spec.NodeName,
			HostPID:       true,
		},
	}

	err := ctrl.SetControllerReference(instrumentedApp, pod, r.Scheme)
	if err != nil {
		return nil, err
	}

	return pod, nil
}

func (r *AppDetectorReconciler) getContainerNames(pod *corev1.Pod) []string {
	var result []string
	for _, c := range pod.Spec.Containers {
		result = append(result, c.Name)
	}

	return result
}

func (r *AppDetectorReconciler) getOwnerTemplateLabels(ctx context.Context, instrumentedApp *v1.AppDetector) (map[string]string, error) {
	owner := metav1.GetControllerOf(instrumentedApp)
	if owner == nil {
		return nil, errors.New("could not find owner for InstrumentedApp")
	}

	if owner.Kind == "Deployment" && owner.APIVersion == appsv1.SchemeGroupVersion.String() {
		var dep appsv1.Deployment
		err := r.Get(ctx, client.ObjectKey{
			Namespace: instrumentedApp.Namespace,
			Name:      owner.Name,
		}, &dep)
		if err != nil {
			return nil, err
		}

		return dep.Spec.Template.Labels, nil
	} else if owner.Kind == "StatefulSet" && owner.APIVersion == appsv1.SchemeGroupVersion.String() {
		var ss appsv1.StatefulSet
		err := r.Get(ctx, client.ObjectKey{
			Namespace: instrumentedApp.Namespace,
			Name:      owner.Name,
		}, &ss)
		if err != nil {
			return nil, err
		}

		return ss.Spec.Template.Labels, nil
	}

	return nil, errors.New("unrecognized owner kind")
}

// SetupWithManager sets up the controller with the Manager.
func (r *AppDetectorReconciler) SetupWithManager(mgr ctrl.Manager) error {
	// Index pods by owner for fast lookup
	if err := mgr.GetFieldIndexer().IndexField(context.Background(), &corev1.Pod{}, podOwnerKey, func(rawObj client.Object) []string {
		pod := rawObj.(*corev1.Pod)
		owner := metav1.GetControllerOf(pod)
		if owner == nil {
			return nil
		}

		if owner.APIVersion != apiGVStr || owner.Kind != "AppDetector" {
			return nil
		}

		return []string{owner.Name}
	}); err != nil {
		return err
	}

	return ctrl.NewControllerManagedBy(mgr).
		For(&v1.AppDetector{}).
		Owns(&corev1.Pod{}).
		Complete(r)
}
