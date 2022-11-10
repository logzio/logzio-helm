package patch

import (
	"github.com/logzio/app-type-detector/api/v1alpha1"
	v1 "k8s.io/api/core/v1"
)

const LogzioApplicationTypeAnnotation = "logzio/application_type"

var annotationPatcher = &AnnotationPatcher{}

type AnnotationPatcher struct{}

func (d *AnnotationPatcher) Patch(podSpec *v1.PodTemplateSpec, applicationType *v1alpha1.AppDetector) {
	if d.shouldPatch(podSpec) {
		if podSpec.Annotations == nil {
			podSpec.Annotations = make(map[string]string)
		}

		podSpec.Annotations[LogzioApplicationTypeAnnotation] = string(applicationType.Spec.Applications[0].Application)
	}
}

func (d *AnnotationPatcher) shouldPatch(podSpec *v1.PodTemplateSpec) bool {
	if _, exists := podSpec.Annotations[LogzioApplicationTypeAnnotation]; exists {
		return false
	}

	return true
}
