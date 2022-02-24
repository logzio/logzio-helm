### Example usage

* Go to `hotrod.yml` file inside this directory.
* Define the logzio-otel-traces service name:
    In most cases, the service name will be `logzio-otel-spm.default.svc.cluster.local`, where default is the namespace where you deployed the helm chart and svc.cluster.name is your cluster domain name.

    If you are not sure what your cluster domain name is, you can run the following command to look it up:
    ```
    kubectl run -it --image=k8s.gcr.io/e2e-test-images/jessie-dnsutils:1.3 --restart=Never shell -- \
    sh -c 'nslookup kubernetes.default | grep Name | sed "s/Name:\skubernetes.default//"'
    ```
    It will deploy a small pod that extracts your cluster domain name from your Kubernetes environment. You can remove this pod after it has returned the cluster domain name.
* Change the `<<logzio-spm-service-name>>` parameter to the with the **service name** obtained previously. on port `14268`
* Deploy the `hotrod.yml` to your kubernetes cluster (example: `kubectl apply -f hotrod.yml`).
* Access the hotrod pod on port 8080 and start sending traces.
