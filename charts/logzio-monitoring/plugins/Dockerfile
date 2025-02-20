################## K8S TOOLS IMAGE ######################
## Required for the webhook-ready-check-job.
## ref: https://hub.docker.com/r/logzio/kube-tools/tags
#########################################################
FROM alpine:3.21.2
LABEL version="0.0.1"

RUN apk add --no-cache curl kubectl

CMD ["/bin/sh"]