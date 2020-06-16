#!/bin/bash
echo "Checking for installed prerequisites.."
echo -n "Checking for kubectl ............. "
has_kubectl=$(kubectl 2>&1)
if [[ $has_kubectl == *"command not found"* ]]; then
  echo -n "kubectl not found! Please install and configure kubectl first."
  exit 1
fi

echo "Passed"
echo -n "Checking for jq ............. "

has_jq=$(jq --version 2>&1)
if [[ $has_jq == *"not found"* ]]; then
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
     sudo apt-get install jq
  elif [[ "$OSTYPE" == "darwin"* ]]; then
      brew install jq
  else
      echo -n "This OS is not supported by this installation script. Please follow the manual instructions at https://docs.logz.io/shipping/metrics-sources/kubernetes.html"
      exit 1
  fi
fi

echo "Passed"
echo -n "Checking for helm    ............. "

has_helm=$(helm version 2>&1)
if [[ $has_helm == *"not found"* ]]; then
      curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
fi

echo "Passed"
echo -n "Checking for kubectl ............. "

has_kube_stat_metrics=$(kubectl get deployments --all-namespaces | grep kube-state-metrics)
if [[ -z $has_kube_stat_metrics ]]; then
  echo "ERROR: kube-state-metrics is not deployed in your cluster. Please deploy it from https://github.com/kubernetes/kube-state-metrics and run this script again"
  exit 1
fi

echo "Passed"

kube_stat_ns=$(kubectl get deployments --all-namespaces -o json | jq '.items[] | select(.metadata.name == "kube-state-metrics")' | jq -r '.metadata.namespace')
kube_stat_port=$(kubectl get deployments --all-namespaces -o json | jq '.items[] | select(.metadata.name == "kube-state-metrics")' | jq '.spec.template.spec.containers[0].ports[] | select(.name == "http-metrics")' | jq '.containerPort')

configmap_api=$(kubectl explain configmap | awk 'NR==2')
configmap_api=${configmap_api:10}
daemonset_api=$(kubectl explain daemonset | awk 'NR==2')
daemonset_api=${daemonset_api:10}
clusterrolebinding_api=$(kubectl explain clusterrolebinding | awk 'NR==2')
clusterrolebinding_api=${clusterrolebinding_api:10}
clusterrole_api=$(kubectl explain clusterrole | awk 'NR==2')
clusterrole_api=${clusterrole_api:10}
serviceaccount_api=$(kubectl explain serviceaccount | awk 'NR==2')
serviceaccount_api=${serviceaccount_api:10}
deployment_api=$(kubectl explain deployment | awk 'NR==2')
deployment_api=${deployment_api:10}

read -esp "Logz.io metrics shipping token:🔒" metrics_token
printf "\n"
read -ep "Logz.io region [us]: " logzio_region
if [[ ! -z $logzio_region ]] && [[ $logzio_region != "us" ]]; then
  logzio_region="-${logzio_region}"
else
  logzio_region=""
fi
listener_host="listener${logzio_region}.logz.io"

read -ep "Kubelet shipping protocol [http]: " shipping_protocol
shipping_protocol=${shipping_protocol:-"http"}
shipping_port="10255"
if [[ $shipping_protocol == "https" ]]; then
  shipping_port="10250"
fi

read -ep "Target namespace to deploy [kube-system]: " namespace
namespace=${namespace:-"kube-system"}

kubectl --namespace=${namespace} create secret generic logzio-metrics-secret \
  --from-literal=logzio-metrics-shipping-token=$metrics_token \
  --from-literal=logzio-metrics-listener-host=$listener_host

cluster_name=$(kubectl config current-context)
if [[ $cluster_name == *"cluster/"* ]]; then
  cluster_name=${cluster_name#*"cluster/"}
fi
read -ep "Cluster name [${cluster_name}]: " real_cluster_name
real_cluster_name=${real_cluster_name:-"${cluster_name}"}

kubectl --namespace=${namespace} create secret generic cluster-details \
  --from-literal=kube-state-metrics-namespace=$kube_stat_ns \
  --from-literal=kube-state-metrics-port=$kube_stat_port \
  --from-literal=cluster-name=$cluster_name

read -ep "Show yaml before deploying? (y/n) " answer
if [ "$answer" = "y" ]; then
  debug="--debug"
fi

helm install ${debug} \
--set=namespace=${namespace} \
--set=shippingProtocol=${shipping_protocol} \
--set=shippingPort=${shipping_port} \
--set=apiVersions.Deployment=${deployment_api} \
--set=apiVersions.ConfigMap=${configmap_api} \
--set=apiVersions.DaemonSet=${daemonset_api} \
--set=apiVersions.ServiceAccount=${serviceaccount_api} \
--set=apiVersions.ClusterRole=${clusterrole_api} \
--set=apiVersions.ClusterRoleBinding=${clusterrolebinding_api} \
--repo https://logzio.github.io/logzio-helm/metricbeat logzio-k8s-metrics logzio-k8s-metrics
