# AKS Monitoring & Alerts Terraform Module

This Terraform module deploys a comprehensive and production-ready monitoring and alerting solution for Azure Kubernetes Service (AKS). It is based on the SRE best practices outlined in the **"AKS Observability Design"** and is designed to be fully modular and reusable across multiple teams and environments.

## 🏛️ Design Philosophy

This module is designed to be **generic and reusable**. It contains no hardcoded environment-specific logic. All configurations, such as alert thresholds and notification emails, are passed in as variables from the calling Terraform project. This approach allows for maximum flexibility and a clear separation of concerns between the alert resource definitions (the module's responsibility) and the environment-specific configurations (the user's responsibility).

## ✨ Features

-   **Comprehensive Alert Suite**: Deploys a suite of **40+ detailed alerts** covering the most critical aspects of your AKS environment.
-   **Layered Coverage**: Alerts are logically grouped into four key areas:
    1.  **Azure Resources**: Subscription Quotas, Service Health, Cost Anomalies.
    2.  **AKS Infrastructure**: Node Health (CPU, Memory, Disk), Pods (Restarts, Status), and Storage.
    3.  **Kubernetes Control Plane**: API Server Latency, etcd Health.
    4.  **Platform Workloads**: Deployments, Jobs, StatefulSets, and other workload health signals.
-   **Flexible Notifications**: Creates fully configurable Action Groups for routing notifications to different teams based on severity (e.g., Standard vs. Critical).
-   **Intelligent Suppression**: Includes fully customizable Alert Suppression Rules for planned maintenance windows and after-hours periods to reduce alert fatigue.
-   **Fully Parameterized**: Every tunable value, from alert thresholds to suppression schedules, is exposed as an input variable for easy customization via `.tfvars` files.
-   **Actionable Alerts**: Enriches alerts with rich metadata (`custom_properties`), including links to runbooks, to accelerate incident response.

***

## 🚀 Getting Started

### Prerequisites

Before using this module, ensure you have the following:
* Terraform `~> 1.3`
* AzureRM Provider `~> 4.0`
* An existing Azure Resource Group.
* An existing AKS Cluster.
* An existing Log Analytics Workspace connected to the AKS cluster.

### Usage

1.  **Create a Configuration File**: Copy the `terraform.tfvars.example` file to a new file named `prod.tfvars` or `qa.tfvars`. Update the values in this file to match your target environment.

    **Example `prod.tfvars`:**
    ```hcl
    # General Settings
    environment_name               = "prod"
    environment_short_prefix       = "p"
    location                       = "australiaeast"
    resource_group_name            = "prod-app-aks-rg"
    log_analytics_workspace_name   = "prod-app-law"
    aks_cluster_name               = "prod-app-aks"

    # Notification Settings
    alert_email_sre                = ["sre-oncall@example.com"]
    alert_email_oncall_primary     = ["pagerduty-critical@example.com"]
    
    # Alert Thresholds
    node_cpu_critical_threshold    = 85
    pod_restart_warning_threshold  = 3
    api_server_latency_critical_ms = 300
    ```

2.  **Call the Module**: In your project's `main.tf`, call the module and pass in the variables that will be populated from your `.tfvars` file.

    ```terraform
    # main.tf in your root project
    
    # Define variables that will be populated from your .tfvars file
    variable "environment_name" {}
    variable "environment_short_prefix" {}
    variable "location" {}
    variable "resource_group_name" {}
    variable "log_analytics_workspace_name" {}
    variable "aks_cluster_name" {}
    # ... define all other variables from the .tfvars file
    
    module "aks_monitoring" {
      source = "./aks_monitoring_module" # Or use a Git source: "git::[https://github.com/your-org/terraform-aks-monitoring.git?ref=v1.0.0](https://github.com/your-org/terraform-aks-monitoring.git?ref=v1.0.0)"
    
      # Pass all variables from the .tfvars file
      environment_name               = var.environment_name
      environment_short_prefix       = var.environment_short_prefix
      location                       = var.location
      resource_group_name            = var.resource_group_name
      log_analytics_workspace_name   = var.log_analytics_workspace_name
      aks_cluster_name               = var.aks_cluster_name
      runbook_base_url               = var.runbook_base_url
      tags                           = var.tags
    
      # --- Notifications ---
      alert_email_sre                = var.alert_email_sre
      alert_email_oncall_primary     = var.alert_email_oncall_primary
      alert_email_oncall_secondary   = var.alert_email_oncall_secondary
      alert_email_manager            = var.alert_email_manager
      teams_webhook_standard         = var.teams_webhook_standard
      teams_webhook_critical         = var.teams_webhook_critical
    
      # --- Suppression Rules ---
      enable_maintenance_window_suppression = var.enable_maintenance_window_suppression
      maintenance_window_timezone         = var.maintenance_window_timezone
      # ... etc for all suppression variables
    
      # --- Alert Thresholds ---
      node_cpu_critical_threshold    = var.node_cpu_critical_threshold
      pod_restart_warning_threshold  = var.pod_restart_warning_threshold
      # ... etc for all threshold variables
    }
    ```

3.  **Run Terraform**: Execute the standard Terraform workflow, specifying your environment's variable file.

    ```bash
    # Initialize Terraform
    terraform init
    
    # Preview the changes
    terraform plan -var-file="prod.tfvars"
    
    # Apply the configuration
    terraform apply -var-file="prod.tfvars"
    ```

***

## 📝 Module Reference

### Inputs

For a complete list of all input variables, their descriptions, and default values, please see the **`variables.tf`** file.

### Outputs

The module exports the IDs of all created resources. For a complete list of outputs, please see the **`outputs.tf`** file. Key outputs include:
* `action_group_ids`: The IDs of the created standard and critical action groups.
* `metric_alert_ids`: A map of all metric-based alert rule IDs.
* `log_alert_ids`: A map of all log-based alert rule IDs.

***

## 📁 Module File Structure

-   `main.tf`: Core logic, defining data sources, Action Groups, and Suppression Rules.
-   `variables.tf`: All input variables for the module.
-   `terraform.tfvars.example`: A template file for user configuration.
-   `outputs.tf`: All module outputs.
-   `versions.tf`: Terraform and provider version constraints.
-   `locals.tf`: Internal local variables, primarily for constructing tags.
-   `alerts_azure.tf`: Alerts for Azure subscription and resource level health.
-   `alerts_infra.tf`: Alerts for AKS node, pod, and storage infrastructure health.
-   `alerts_platform.tf`: Alerts for Kubernetes control plane and platform workload health.