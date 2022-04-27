terraform {
  cloud {
    organization = "logzio-testing"

    workspaces {
      name = "logzio-monitoring-tests"
    }
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.2.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.10.0"
    }

    helm = {
      source = "hashicorp/helm"
      version = "2.5.1"
    }
  }
}

# ============================= AKS CLUSTER =============================
variable "client_id" {
  type = string
  description = "your Azure client id"
  sensitive = true
}

variable "subscription_id" {
  type = string
  description = "your Azure subscription id"
  sensitive = true
}

variable "client_secret" {
  type = string
  description = "your Azure client secret"
  sensitive = true
}

variable "tenant_id" {
  type = string
  description = "your Azure tenant id"
  sensitive = true
}

variable "win_user" {
  type = string
  description = "username for windows profile"
  sensitive = true
}

variable "win_password" {
  type = string
  description = "password for windows profile"
  sensitive = true
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

resource "azurerm_resource_group" "integration_tests_helm_rg" {
  name     = "integration-tests-helm"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "integration_tests_helm_cluster" {
  depends_on = [azurerm_resource_group.integration_tests_helm_rg]
  name                = "integration_tests_cluster"
  location            = azurerm_resource_group.integration_tests_helm_rg.location
  resource_group_name = azurerm_resource_group.integration_tests_helm_rg.name
  dns_prefix          = "intgtst"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  # https://stackoverflow.com/a/68121045
  network_profile {
    network_plugin = "azure"
  }

  windows_profile {
    admin_username = var.win_user
    admin_password = var.win_password
  }

  tags = {
    Owners = "Integrations"
    Purpose = "Automated tests"
    Note = "Do not delete!"
  }
}

# Windows node
resource "azurerm_kubernetes_cluster_node_pool" "integration_tests_helm_cluster_windows_nodepool" {
  depends_on = [azurerm_kubernetes_cluster.integration_tests_helm_cluster]
  name                  = "winnp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.integration_tests_helm_cluster.id
  os_type = "Windows"
  vm_size               = "Standard_D2s_v3"
  node_count            = 1
  os_disk_size_gb = "128"

  tags = {
    Owners = "Integrations"
    Purpose = "Automated tests"
    Note = "Do not delete!"
  }
}

# Node with taint
resource "azurerm_kubernetes_cluster_node_pool" "integration_tests_helm_cluster_taint_nodepool" {
  depends_on = [azurerm_kubernetes_cluster.integration_tests_helm_cluster]
  name                  = "taintnp"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.integration_tests_helm_cluster.id
  vm_size               = "Standard_DS2_v2"
  node_count            = 1
  node_taints = ["taint=true:NoSchedule"]

  tags = {
    Owners = "Integrations"
    Purpose = "Automated tests"
    Note = "Do not delete!"
  }
}



# =========================== PREPARE CLUSTER ===========================

provider "kubernetes" {
    host                   = azurerm_kubernetes_cluster.integration_tests_helm_cluster.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.integration_tests_helm_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.integration_tests_helm_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.integration_tests_helm_cluster.kube_config.0.cluster_ca_certificate)
}

variable "jaeger_endpoint" {
  type = string
  description = "jaeger endpoint for traces sample app"
  sensitive = true
}

resource "kubernetes_namespace" "ns_monitoring" {
  depends_on = [azurerm_kubernetes_cluster.integration_tests_helm_cluster]
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_deployment" "windows_app_sample" {
  depends_on = [kubernetes_namespace.ns_monitoring, azurerm_kubernetes_cluster_node_pool.integration_tests_helm_cluster_windows_nodepool]
  metadata {
    name = "windows-demo-app"
    namespace = "monitoring"
    labels = {
      app = "windows-demo-app"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "windows-demo-app"
      }
    }
    template {
      metadata {
        name = "windows-demo-app"
        labels = {
          app = "windows-demo-app"
        }
      }
      spec {
        node_selector = {
          "kubernetes.io/os" = "windows"
        }

        container {
          name = "windows-demo-app"
          image = "tamirmich/dot-net-demo:0.0.1"
          resources {
            limits = {
              cpu = "1"
              memory = "800M"
            }
            requests = {
              cpu = "0.1"
              memory = "300M"
            }
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "win_app_service" {
  metadata {
    name = "windows-demo-app"
    namespace = "monitoring"
  }

  spec {
    type = "LoadBalancer"
    port {
      port = "80"
      protocol = "TCP"
    }
    selector = {
      app = "windows-demo-app"
    }
  }
}

# Traces demo app

resource "kubernetes_deployment" "traces_app_sample" {
  metadata {
    name = "jaeger-hotrod"
    namespace = "monitoring"
    labels = {
      "app.kubernetes.io/component" = "hotrod"
      "app.kubernetes.io/instance" = "jaeger"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/component" = "hotrod"
        "app.kubernetes.io/instance" = "jaeger"
        "app.kubernetes.io/name" = "jaeger"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/component" = "hotrod"
          "app.kubernetes.io/instance" = "jaeger"
          "app.kubernetes.io/name" = "jaeger"
        }
      }
      
      spec {
        toleration {
          effect = "NoSchedule"
          key = "taint"
          value = "true"
          operator = "Equal"
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }
        container {
          name = "jaeger-hotrod"
          image = "jaegertracing/example-hotrod:latest"
          port {
            container_port = 8080
          }
          env {
            name = "JAEGER_ENDPOINT"
            value = var.jaeger_endpoint
          }
          image_pull_policy = "Always"
          liveness_probe {
            http_get {
              path = "/"
              port = "8080"
            }
          }
          readiness_probe {
            http_get {
              path = "/"
              port = "8080"
            }
          }
        }
      }
    }
  }
}


# ============================= HELM RELEASE ============================

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.integration_tests_helm_cluster.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.integration_tests_helm_cluster.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.integration_tests_helm_cluster.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.integration_tests_helm_cluster.kube_config.0.cluster_ca_certificate)
  }
}

variable "logzio_logs_shipping_token" {
  type = string
  description = "your logzio logs shipping token"
  sensitive = true
}

variable "logzio_listener" {
  type = string
  description = "your logzio logs listener"
  sensitive = true
}

variable "logzio_metrics_shipping_token" {
  type = string
  description = "your logzio metrics shipping token"
  sensitive = true
}

variable "logzio_metrics_listener" {
  type = string
  description = "your logzio metrics listener"
  sensitive = true
}

variable "p8s_logzio_name" {
  type = string
  description = "p8s logzio name"
  sensitive = true
}

variable "logzio_traces_shipping_token" {
  type = string
  description = "your logzio traces shipping token"
  sensitive = true
}

variable "logzio_region" {
  type = string
  description = "your logzio region"
  sensitive = true
}


resource "helm_release" "logzio-monitoring" {
  depends_on = [kubernetes_namespace.ns_monitoring]
  name       = "logzio-monitoring"
  namespace = "monitoring"
  chart      = "../../../charts/logzio-monitoring"
  dependency_update = true

  set_sensitive {
    name = "logzio-fluentd.secrets.logzioShippingToken"
    value = var.logzio_logs_shipping_token
    type = "string"
  }

  set_sensitive {
    name = "logzio-fluentd.secrets.logzioListener"
    value = var.logzio_listener
    type = "string"
  }

  set_sensitive {
    name = "logzio-k8s-telemetry.secrets.MetricsToken"
    value = var.logzio_metrics_shipping_token
    type = "string"
  }

  set_sensitive {
    name = "logzio-k8s-telemetry.secrets.ListenerHost"
    value = var.logzio_metrics_listener
    type = "string"
  }

  set_sensitive {
    name = "logzio-k8s-telemetry.secrets.p8s_logzio_name"
    value = var.p8s_logzio_name
    type = "string"
  }

  set_sensitive {
    name = "logzio-k8s-telemetry.secrets.TracesToken"
    value = var.logzio_traces_shipping_token
    type = "string"
  }

  set_sensitive {
    name = "logzio-k8s-telemetry.secrets.LogzioRegion"
    value = var.logzio_region
    type = "string"
  }

  set {
    name  = "logs.enabled"
    value = true
  }

  set {
    name  = "logzio-fluentd.daemonset.tolerations[0].key"
    value = "taint"
    type = "string"
  }

  set {
    name  = "logzio-fluentd.daemonset.tolerations[0].operator"
    value = "Equal"
    type = "string"
  }

  set {
    name  = "logzio-fluentd.daemonset.tolerations[0].value"
    value = "true"
    type = "string"
  }

  set {
    name  = "logzio-fluentd.daemonset.tolerations[0].effect"
    value = "NoSchedule"
    type = "string"
  }

  set {
    name = "metricsOrTraces.enabled"
    value = true
  }

  set {
    name = "logzio-k8s-telemetry.metrics.enabled"
    value = true
  }

  set {
    name  = "logzio-k8s-telemetry.tolerations[0].key"
    value = "taint"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.tolerations[0].operator"
    value = "Equal"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.tolerations[0].value"
    value = "true"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.tolerations[0].effect"
    value = "NoSchedule"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.prometheus-pushgateway.tolerations[0].key"
    value = "taint"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.prometheus-pushgateway.tolerations[0].operator"
    value = "Equal"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.prometheus-pushgateway.tolerations[0].value"
    value = "true"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.prometheus-pushgateway.tolerations[0].effect"
    value = "NoSchedule"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.kube-state-metrics.tolerations[0].key"
    value = "taint"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.kube-state-metrics.tolerations[0].operator"
    value = "Equal"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.kube-state-metrics.tolerations[0].value"
    value = "true"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.kube-state-metrics.tolerations[0].effect"
    value = "NoSchedule"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.prometheus-node-exporter.tolerations[0].key"
    value = "taint"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.prometheus-node-exporter.tolerations[0].operator"
    value = "Equal"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.prometheus-node-exporter.tolerations[0].value"
    value = "true"
    type = "string"
  }

  set {
    name  = "logzio-k8s-telemetry.prometheus-node-exporter.tolerations[0].effect"
    value = "NoSchedule"
    type = "string"
  }

  set {
    name = "logzio-k8s-telemetry.traces.enabled"
    value = true
  }
}

# =======================================================================