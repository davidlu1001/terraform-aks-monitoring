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

The module exports the IDs of all created resources. For a complete list of outputs, please see the **`outputs.tf`** file.

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                      | Version |
| ------------------------------------------------------------------------- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3  |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm)       | ~> 4.0  |

## Providers

| Name                                                          | Version |
| ------------------------------------------------------------- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.0  |

## Modules

No modules.

## Resources

| Name                                                                                                                                                                                                       | Type        |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [azurerm_monitor_action_group.critical](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group)                                                              | resource    |
| [azurerm_monitor_action_group.standard](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group)                                                              | resource    |
| [azurerm_monitor_activity_log_alert.service_health_incidents](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_activity_log_alert)                                  | resource    |
| [azurerm_monitor_alert_processing_rule_suppression.after_hours_low_severity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_alert_processing_rule_suppression)    | resource    |
| [azurerm_monitor_alert_processing_rule_suppression.maintenance_window](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_alert_processing_rule_suppression)          | resource    |
| [azurerm_monitor_metric_alert.node_cpu_critical](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                                     | resource    |
| [azurerm_monitor_metric_alert.node_cpu_warning](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                                      | resource    |
| [azurerm_monitor_metric_alert.node_memory_critical](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                                  | resource    |
| [azurerm_monitor_metric_alert.node_memory_warning](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                                   | resource    |
| [azurerm_monitor_metric_alert.pod_restart_alert_warning](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                             | resource    |
| [azurerm_monitor_metric_alert.subscription_quota_usage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_metric_alert)                                              | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.api_server_latency_critical](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)       | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.api_server_latency_warning](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)        | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.cost_anomalies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)                    | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.crashloop_backoff](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)                 | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.deployment_replica_mismatch](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)       | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.etcd_health](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)                       | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.etcd_latency_critical](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)             | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.etcd_latency_warning](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)              | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.failed_pod_scheduling](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)             | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.kube_container_waiting](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)            | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.kube_cpu_quota_overcommit](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)         | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.kube_job_failed](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)                   | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.kube_memory_quota_overcommit](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)      | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.kube_statefulset_replica_mismatch](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2) | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.node_pressure_events](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)              | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.node_readiness_flapping](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)           | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.node_status_issues](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)                | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.nsg_blocks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)                        | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.oom_killed](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)                        | resource    |
| [azurerm_monitor_scheduled_query_rules_alert_v2.pod_unavailable_critical](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_scheduled_query_rules_alert_v2)          | resource    |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config)                                                                          | data source |
| [azurerm_kubernetes_cluster.aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/kubernetes_cluster)                                                                    | data source |
| [azurerm_log_analytics_workspace.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/log_analytics_workspace)                                                         | data source |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group)                                                                           | data source |

## Inputs

| Name                                                                                                                                                                  | Description                                                                                                     | Type           | Default                           | Required |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | -------------- | --------------------------------- | :------: |
| <a name="input_after_hours_end_time"></a> [after\_hours\_end\_time](#input\_after\_hours\_end\_time)                                                                  | The end time for after-hours suppression (e.g., start of the morning).                                          | `string`       | `"08:00:00"`                      |    no    |
| <a name="input_after_hours_start_time"></a> [after\_hours\_start\_time](#input\_after\_hours\_start\_time)                                                            | The start time for after-hours suppression (e.g., start of the evening).                                        | `string`       | `"18:00:00"`                      |    no    |
| <a name="input_after_hours_suppression_environments"></a> [after\_hours\_suppression\_environments](#input\_after\_hours\_suppression\_environments)                  | A list of environment names (e.g., ['qa', 'dev']) where the after-hours suppression rule should be active.      | `list(string)` | <pre>[<br/>  "qa"<br/>]</pre>     |    no    |
| <a name="input_after_hours_suppression_timezone"></a> [after\_hours\_suppression\_timezone](#input\_after\_hours\_suppression\_timezone)                              | The IANA timezone name for the after-hours suppression schedule.                                                | `string`       | `"Pacific/Auckland"`              |    no    |
| <a name="input_aks_cluster_name"></a> [aks\_cluster\_name](#input\_aks\_cluster\_name)                                                                                | The name of the AKS cluster to scope alerts to.                                                                 | `string`       | n/a                               |   yes    |
| <a name="input_alert_email_manager"></a> [alert\_email\_manager](#input\_alert\_email\_manager)                                                                       | A list of email addresses for manager escalation.                                                               | `list(string)` | `[]`                              |    no    |
| <a name="input_alert_email_oncall_primary"></a> [alert\_email\_oncall\_primary](#input\_alert\_email\_oncall\_primary)                                                | A list of email addresses for the primary on-call.                                                              | `list(string)` | `[]`                              |    no    |
| <a name="input_alert_email_oncall_secondary"></a> [alert\_email\_oncall\_secondary](#input\_alert\_email\_oncall\_secondary)                                          | A list of email addresses for the secondary on-call.                                                            | `list(string)` | `[]`                              |    no    |
| <a name="input_alert_email_sre"></a> [alert\_email\_sre](#input\_alert\_email\_sre)                                                                                   | A list of email addresses for the SRE team.                                                                     | `list(string)` | `[]`                              |    no    |
| <a name="input_api_server_latency_critical_ms"></a> [api\_server\_latency\_critical\_ms](#input\_api\_server\_latency\_critical\_ms)                                  | P95 API server latency in milliseconds to trigger a critical alert.                                             | `number`       | `500`                             |    no    |
| <a name="input_api_server_latency_warning_ms"></a> [api\_server\_latency\_warning\_ms](#input\_api\_server\_latency\_warning\_ms)                                     | P95 API server latency in milliseconds to trigger a warning.                                                    | `number`       | `200`                             |    no    |
| <a name="input_azure_cost_anomaly_percentage_threshold"></a> [azure\_cost\_anomaly\_percentage\_threshold](#input\_azure\_cost\_anomaly\_percentage\_threshold)       | The percentage increase in cost over the baseline to trigger an anomaly alert.                                  | `number`       | `50`                              |    no    |
| <a name="input_azure_subscription_quota_threshold"></a> [azure\_subscription\_quota\_threshold](#input\_azure\_subscription\_quota\_threshold)                        | The subscription resource quota usage percentage to trigger an alert.                                           | `number`       | `85`                              |    no    |
| <a name="input_cluster_cpu_overcommit_ratio_threshold"></a> [cluster\_cpu\_overcommit\_ratio\_threshold](#input\_cluster\_cpu\_overcommit\_ratio\_threshold)          | The ratio of total CPU requests to allocatable capacity to trigger an overcommit alert (e.g., 1.5 for 150%).    | `number`       | `1.5`                             |    no    |
| <a name="input_cluster_memory_overcommit_ratio_threshold"></a> [cluster\_memory\_overcommit\_ratio\_threshold](#input\_cluster\_memory\_overcommit\_ratio\_threshold) | The ratio of total memory requests to allocatable capacity to trigger an overcommit alert (e.g., 1.5 for 150%). | `number`       | `1.5`                             |    no    |
| <a name="input_enable_after_hours_suppression"></a> [enable\_after\_hours\_suppression](#input\_enable\_after\_hours\_suppression)                                    | If true, the after-hours alert suppression rule will be created for specified environments.                     | `bool`         | `true`                            |    no    |
| <a name="input_enable_maintenance_window_suppression"></a> [enable\_maintenance\_window\_suppression](#input\_enable\_maintenance\_window\_suppression)               | If true, the maintenance window alert suppression rule will be created.                                         | `bool`         | `true`                            |    no    |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name)                                                                                  | The name of the environment (e.g., 'qa', 'prod'). Used for naming and tagging.                                  | `string`       | n/a                               |   yes    |
| <a name="input_environment_short_prefix"></a> [environment\_short\_prefix](#input\_environment\_short\_prefix)                                                        | A short prefix for the environment (e.g., 'q', 'p'). Used for short names in resources.                         | `string`       | n/a                               |   yes    |
| <a name="input_etcd_latency_critical_ms"></a> [etcd\_latency\_critical\_ms](#input\_etcd\_latency\_critical\_ms)                                                      | P95 etcd latency in milliseconds to trigger a critical alert.                                                   | `number`       | `500`                             |    no    |
| <a name="input_etcd_latency_warning_ms"></a> [etcd\_latency\_warning\_ms](#input\_etcd\_latency\_warning\_ms)                                                         | P95 etcd latency in milliseconds to trigger a warning.                                                          | `number`       | `100`                             |    no    |
| <a name="input_location"></a> [location](#input\_location)                                                                                                            | The Azure region where resources are deployed.                                                                  | `string`       | n/a                               |   yes    |
| <a name="input_log_analytics_workspace_name"></a> [log\_analytics\_workspace\_name](#input\_log\_analytics\_workspace\_name)                                          | The name of the Log Analytics Workspace to scope alerts to.                                                     | `string`       | n/a                               |   yes    |
| <a name="input_maintenance_window_days_of_week"></a> [maintenance\_window\_days\_of\_week](#input\_maintenance\_window\_days\_of\_week)                               | A list of days of the week for the maintenance window. Allowed values are 'Sunday', 'Monday', etc.              | `list(string)` | <pre>[<br/>  "Sunday"<br/>]</pre> |    no    |
| <a name="input_maintenance_window_end_time"></a> [maintenance\_window\_end\_time](#input\_maintenance\_window\_end\_time)                                             | The end time for the maintenance window in HH:MM:SS format.                                                     | `string`       | `"04:00:00"`                      |    no    |
| <a name="input_maintenance_window_start_time"></a> [maintenance\_window\_start\_time](#input\_maintenance\_window\_start\_time)                                       | The start time for the maintenance window in HH:MM:SS format.                                                   | `string`       | `"02:00:00"`                      |    no    |
| <a name="input_maintenance_window_timezone"></a> [maintenance\_window\_timezone](#input\_maintenance\_window\_timezone)                                               | The IANA timezone name for the maintenance window schedule (e.g., 'Pacific/Auckland', 'UTC').                   | `string`       | `"Pacific/Auckland"`              |    no    |
| <a name="input_node_cpu_critical_threshold"></a> [node\_cpu\_critical\_threshold](#input\_node\_cpu\_critical\_threshold)                                             | CPU percentage threshold for a node critical alert.                                                             | `number`       | `90`                              |    no    |
| <a name="input_node_cpu_warning_threshold"></a> [node\_cpu\_warning\_threshold](#input\_node\_cpu\_warning\_threshold)                                                | CPU percentage threshold for a node warning alert.                                                              | `number`       | `80`                              |    no    |
| <a name="input_node_disk_critical_threshold"></a> [node\_disk\_critical\_threshold](#input\_node\_disk\_critical\_threshold)                                          | Disk percentage threshold for a node critical alert.                                                            | `number`       | `95`                              |    no    |
| <a name="input_node_disk_warning_threshold"></a> [node\_disk\_warning\_threshold](#input\_node\_disk\_warning\_threshold)                                             | Disk percentage threshold for a node warning alert.                                                             | `number`       | `80`                              |    no    |
| <a name="input_node_memory_critical_threshold"></a> [node\_memory\_critical\_threshold](#input\_node\_memory\_critical\_threshold)                                    | Memory percentage threshold for a node critical alert.                                                          | `number`       | `95`                              |    no    |
| <a name="input_node_memory_warning_threshold"></a> [node\_memory\_warning\_threshold](#input\_node\_memory\_warning\_threshold)                                       | Memory percentage threshold for a node warning alert.                                                           | `number`       | `85`                              |    no    |
| <a name="input_node_readiness_flapping_count"></a> [node\_readiness\_flapping\_count](#input\_node\_readiness\_flapping\_count)                                       | The number of readiness status changes in 15 minutes to be considered 'flapping'.                               | `number`       | `3`                               |    no    |
| <a name="input_nsg_blocked_connections_threshold"></a> [nsg\_blocked\_connections\_threshold](#input\_nsg\_blocked\_connections\_threshold)                           | The number of blocked connections by an NSG in 30 minutes to trigger an alert.                                  | `number`       | `100`                             |    no    |
| <a name="input_pod_container_waiting_minutes_threshold"></a> [pod\_container\_waiting\_minutes\_threshold](#input\_pod\_container\_waiting\_minutes\_threshold)       | The number of minutes a container can be in a 'Waiting' state before an alert is fired.                         | `number`       | `60`                              |    no    |
| <a name="input_pod_cpu_critical_threshold"></a> [pod\_cpu\_critical\_threshold](#input\_pod\_cpu\_critical\_threshold)                                                | Pod CPU usage percentage vs request for a critical alert.                                                       | `number`       | `90`                              |    no    |
| <a name="input_pod_cpu_warning_threshold"></a> [pod\_cpu\_warning\_threshold](#input\_pod\_cpu\_warning\_threshold)                                                   | Pod CPU usage percentage vs request for a warning alert.                                                        | `number`       | `70`                              |    no    |
| <a name="input_pod_memory_critical_threshold"></a> [pod\_memory\_critical\_threshold](#input\_pod\_memory\_critical\_threshold)                                       | Pod memory usage percentage vs request for a critical alert.                                                    | `number`       | `90`                              |    no    |
| <a name="input_pod_memory_warning_threshold"></a> [pod\_memory\_warning\_threshold](#input\_pod\_memory\_warning\_threshold)                                          | Pod memory usage percentage vs request for a warning alert.                                                     | `number`       | `75`                              |    no    |
| <a name="input_pod_restart_critical_threshold"></a> [pod\_restart\_critical\_threshold](#input\_pod\_restart\_critical\_threshold)                                    | Number of pod restarts in a 30-minute window to trigger a critical alert.                                       | `number`       | `10`                              |    no    |
| <a name="input_pod_restart_warning_threshold"></a> [pod\_restart\_warning\_threshold](#input\_pod\_restart\_warning\_threshold)                                       | Number of pod restarts in a 30-minute window to trigger a warning.                                              | `number`       | `5`                               |    no    |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)                                                                       | The name of the resource group where the AKS cluster resides.                                                   | `string`       | n/a                               |   yes    |
| <a name="input_runbook_base_url"></a> [runbook\_base\_url](#input\_runbook\_base\_url)                                                                                | The base URL for runbooks to be included in alert notifications.                                                | `string`       | `""`                              |    no    |
| <a name="input_tags"></a> [tags](#input\_tags)                                                                                                                        | A map of tags to apply to all resources.                                                                        | `map(string)`  | `{}`                              |    no    |
| <a name="input_teams_webhook_critical"></a> [teams\_webhook\_critical](#input\_teams\_webhook\_critical)                                                              | The webhook URL for critical Teams notifications.                                                               | `string`       | `""`                              |    no    |
| <a name="input_teams_webhook_standard"></a> [teams\_webhook\_standard](#input\_teams\_webhook\_standard)                                                              | The webhook URL for standard Teams notifications.                                                               | `string`       | `""`                              |    no    |

## Outputs

| Name                                                                                                                  | Description                                                            |
| --------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| <a name="output_action_group_ids"></a> [action\_group\_ids](#output\_action\_group\_ids)                              | The IDs of the created action groups for standard and critical alerts. |
| <a name="output_alert_processing_rule_ids"></a> [alert\_processing\_rule\_ids](#output\_alert\_processing\_rule\_ids) | The IDs of the created alert processing (suppression) rules.           |
| <a name="output_alert_summary"></a> [alert\_summary](#output\_alert\_summary)                                         | A summary of the monitoring configuration deployed by this module.     |
| <a name="output_log_alert_ids"></a> [log\_alert\_ids](#output\_log\_alert\_ids)                                       | A map of all log-based (KQL) alert rule IDs created by this module.    |
| <a name="output_metric_alert_ids"></a> [metric\_alert\_ids](#output\_metric\_alert\_ids)                              | A map of all metric-based alert rule IDs created by this module.       |
<!-- END_TF_DOCS -->