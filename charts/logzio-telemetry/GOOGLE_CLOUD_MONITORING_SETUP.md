# Google Cloud Monitoring Integration with Logzio Telemetry Chart

This guide explains how to configure the Logzio Telemetry Helm chart to collect metrics from Google Cloud Monitoring and send them to Logz.io.

## Prerequisites

- Kubernetes cluster with Helm installed
- kubectl configured to access your cluster
- Google Cloud project with monitoring enabled
- Logz.io account with metrics shipping token

## Step 1: Create Google Cloud Service Account

### 1.1 Create Service Account in Google Cloud Console

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **IAM & Admin** > **Service Accounts**
3. Click **Create Service Account**
4. Fill in the details:
   - **Service account name**: `otel-gcp-metrics-logzio-sa` (or your preferred name)
   - **Service account ID**: Will be auto-generated
   - **Description**: Service account for OpenTelemetry GCP metrics collection

### 1.2 Assign Required Permissions

Grant the following IAM roles to the service account:
- **Monitoring Viewer** (`roles/monitoring.viewer`) - Required to read metrics

### 1.3 Create and Download Service Account Key

1. In the Service Accounts list, click on your newly created service account
2. Go to the **Keys** tab
3. Click **Add Key** > **Create new key**
4. Select **JSON** format
5. Click **Create** and save the JSON file securely

### 1.4 Alternative: Using gcloud CLI

```bash
# Set your project ID
export PROJECT_ID="your-project-id"

# Create service account
gcloud iam service-accounts create otel-gcp-metrics-logzio-sa \
    --display-name="OpenTelemetry GCP Metrics Service Account" \
    --description="Service account for collecting GCP metrics via OpenTelemetry" \
    --project=$PROJECT_ID

# Assign monitoring viewer role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:otel-gcp-metrics-logzio-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/monitoring.viewer"

# Create and download key
gcloud iam service-accounts keys create gcp-credentials.json \
    --iam-account=otel-gcp-metrics-logzio-sa@$PROJECT_ID.iam.gserviceaccount.com \
    --project=$PROJECT_ID
```

## Step 2: Create Kubernetes Secret

### 2.1 Create Secret from JSON File

```bash
# Create namespace if it doesn't exist
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Create secret from the JSON file
kubectl create secret generic google-cloud-credentials \
    --from-file=your-credentials.json=/path/to/your/gcp-credentials.json \
    -n monitoring
```

### 2.2 Verify Secret Creation

```bash
# Check that the secret was created
kubectl get secret google-cloud-credentials -n monitoring

# Verify the secret contains the JSON file
kubectl describe secret google-cloud-credentials -n monitoring
```

## Step 3: Configure Helm Values

Create or update your `values.yaml` file with the following configuration:

```yaml
# Basic Logz.io configuration
global:
  logzioMetricsToken: "your-logzio-metrics-token"
  env_id: "your-environment-name"
  customMetricsEndpoint: "https://listener.logz.io:8053"  # Optional: override default endpoint

# Enable metrics collection
metrics:
  enabled: true

# Configure collector mode
collector:
  mode: standalone  # or daemonset

# Environment variables for Google Cloud credentials
extraEnvs:
  - name: GOOGLE_APPLICATION_CREDENTIALS
    value: /var/secrets/google/your-credentials.json  # Match the filename from your JSON

# Mount the Google Cloud credentials secret
secretMounts:
  - name: google-cloud-credentials
    secretName: google-cloud-credentials
    mountPath: /var/secrets/google
    readOnly: true

# Configure Google Cloud Monitoring receiver
metricsConfig:
  receivers:
    googlecloudmonitoring:
      collection_interval: 2m  # How often to collect metrics
      project_id: "your-gcp-project-id"
      metrics_list:
        # Example: Collect all compute metrics
        - metric_descriptor_filter: "metric.type = starts_with(\"compute.googleapis.com\")"
        # Example: Collect specific metrics
        # - metric_descriptor_filter: "metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
        # Add more metric filters as needed

  service:
    pipelines:
      metrics/infrastructure:
        exporters:
          - prometheusremotewrite/infrastructure
        processors:
          - attributes/env_id
          - batch
        receivers:
          - googlecloudmonitoring  # Add this to existing receivers
          - prometheus/kubelet
          - prometheus/cadvisor
          - prometheus/infrastructure
          - prometheus/collector
```

### 3.1 Available Metric Filters

You can customize which metrics to collect using [metric descriptor filters](https://cloud.google.com/monitoring/api/v3/filters#metric-descriptor-filter), for example:

```yaml
metrics_list:
  # All compute metrics
  - metric_descriptor_filter: "metric.type = starts_with(\"compute.googleapis.com\")"
  
  # All Cloud SQL metrics
  - metric_descriptor_filter: "metric.type = starts_with(\"cloudsql.googleapis.com\")"
  
  # All BigQuery metrics
  - metric_descriptor_filter: "metric.type = starts_with(\"bigquery.googleapis.com\")"
  
  # All Cloud Storage metrics
  - metric_descriptor_filter: "metric.type = starts_with(\"storage.googleapis.com\")"
  
  # Specific CPU utilization metric
  - metric_descriptor_filter: "metric.type = \"compute.googleapis.com/instance/cpu/utilization\""
  
  # Multiple specific metrics
  - metric_descriptor_filter: "metric.type = one_of(\"compute.googleapis.com/instance/cpu/utilization\", \"compute.googleapis.com/instance/memory/utilization\")"
```

## Step 4: Deploy the Chart

```bash

# Deploy using Helm
helm upgrade --install logzio-telemetry logzio-helm/logzio-k8s-telemetry \
    -n monitoring \
    --create-namespace \
    -f your-values.yaml
```

## Step 5: Verify Deployment

### 5.1 Check Pod Status

```bash
# Check if pods are running
kubectl get pods -n monitoring

# Check pod logs for any errors
kubectl logs -n monitoring -l app.kubernetes.io/name=otel-collector --tail=50
```

### 5.2 Verify Google Cloud Credentials Mount

```bash
# Get the pod name
POD_NAME=$(kubectl get pods -n monitoring -l component=logzio-telemetry-collector-standalone -o jsonpath='{.items[0].metadata.name}')

# Check if the credentials file is mounted correctly
kubectl exec -n monitoring $POD_NAME -- ls -la /var/secrets/google/

# Verify environment variable is set
kubectl exec -n monitoring $POD_NAME -- env | grep GOOGLE_APPLICATION_CREDENTIALS
```

### 5.3 Test Google Cloud API Access

```bash
# Test if the service account can access Google Cloud Monitoring API
kubectl exec -n monitoring $POD_NAME -- gcloud auth list
```

## Troubleshooting

### Common Issues

1. **"no such file or directory" error for credentials**
   - Verify the secret was created correctly
   - Check that the filename in `GOOGLE_APPLICATION_CREDENTIALS` matches the actual file in the secret
   - Ensure `secretMounts` is used in values.yaml

2. **Permission denied errors**
   - Verify the service account has the required IAM roles
   - Check that the project ID in the configuration matches your GCP project

3. **Pod crash loops**
   - Check pod logs: `kubectl logs -n monitoring <pod-name>`
   - Verify all required configuration is present
   - Ensure the Kubernetes secret exists in the correct namespace

4. **No metrics appearing in Logz.io**
   - Verify the Logz.io metrics token is correct
   - Check that the metrics endpoint URL is accessible
   - Confirm the metric filters are returning data

### Useful Commands

```bash
# View current chart values
helm get values logzio-telemetry -n monitoring

# Check OpenTelemetry collector configuration
kubectl get configmap -n monitoring -o yaml

# Monitor pod events
kubectl describe pod -n monitoring <pod-name>

# Check service account permissions (if using GKE)
kubectl describe serviceaccount -n monitoring
```

## Security Considerations

1. **Least Privilege**: Only grant the minimum required IAM roles to the service account
2. **Secret Management**: Store the service account JSON securely and rotate keys regularly
3. **Network Security**: Ensure proper network policies are in place if required
4. **RBAC**: Use appropriate Kubernetes RBAC settings for the collector pods

## Additional Configuration Options

### Custom Metric Collection Intervals

```yaml
metricsConfig:
  receivers:
    googlecloudmonitoring:
      collection_interval: 5m  # Collect every 5 minutes
      # ... other config
```

### Multiple Projects

```yaml
metricsConfig:
  receivers:
    googlecloudmonitoring_project1:
      project_id: "project-1"
      # ... config for project 1
    googlecloudmonitoring_project2:
      project_id: "project-2"
      # ... config for project 2
```

For more information about available metrics and configuration options, refer to the [OpenTelemetry Google Cloud Monitoring Receiver documentation](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/googlecloudmonitoringreceiver).
