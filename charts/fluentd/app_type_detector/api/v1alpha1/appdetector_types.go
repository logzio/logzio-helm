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

// TODO we dont need intrumented app information?

package v1alpha1

import (
	"github.com/logzio/app-type-detector/common"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// AppDetectorSpec defines the desired state of AppDetector
type AppDetectorSpec struct {
	Applications []common.ApplicationByContainer `json:"applications,omitempty"`
	Detected     *bool                           `json:"detected,omitempty"`
}

// AppDetectorStatus defines the observed state of AppDetector
type AppDetectorStatus struct {
	AppDetection AppDetectionStatus `json:"appDetection,omitempty"`
	Detected     bool               `json:"detected,omitempty"`
}

type AppDetectionStatus struct {
	Phase AppDetectionPhase `json:"phase,omitempty"`
}

type AppDetectionPhase string

const (
	PendingAppDetectionPhase   AppDetectionPhase = "Pending"
	RunningAppDetectionPhase   AppDetectionPhase = "Running"
	CompletedAppDetectionPhase AppDetectionPhase = "Completed"
	ErrorAppDetectionPhase     AppDetectionPhase = "Error"
)

// AppDetector is the Schema for the appdetector API
type AppDetector struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   AppDetectorSpec   `json:"spec,omitempty"`
	Status AppDetectorStatus `json:"status,omitempty"`
}

// AppDetectorList contains a list of AppDetector
type AppDetectorList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []AppDetector `json:"items"`
}

func init() {
	SchemeBuilder.Register(&AppDetector{}, &AppDetectorList{})
}
