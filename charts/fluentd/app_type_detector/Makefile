.PHONY: build-images
build-images:
	docker build -t logzio/kubernetes-app-detector:$(TAG)  -f appDetector/Dockerfile . --build-arg SERVICE_NAME=appDetector
	docker build -t logzio/kubernetes-app-detector-instrumentor:$(TAG) . --build-arg SERVICE_NAME=instrumentor

.PHONY: push-images
push-images:
	docker push logzio/kubernetes-app-detector:$(TAG)
	docker push logzio/kubernetes-app-detector-instrumentor:$(TAG)
