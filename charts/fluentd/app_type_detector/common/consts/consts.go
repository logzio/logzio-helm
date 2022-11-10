package consts

import "errors"

const (
	AppDetectorContainerAnnotationKey = "logzio/app-detection-pod"
	CurrentNamespaceEnvVar            = "CURRENT_NS"
	DefaultMonitoringNamespace        = "monitoring"
)

var (
	PodsNotFoundErr = errors.New("could not find a ready pod")
)
