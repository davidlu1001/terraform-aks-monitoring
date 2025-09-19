# outputs.tf
#
# Defines the output values from this module.
# These outputs can be used by other resources in the root Terraform project.

# =========================================
# Output: Action Groups
# =========================================

output "action_group_ids" {
  description = "The IDs of the created action groups for standard and critical alerts."
  value = {
    standard = azurerm_monitor_action_group.standard.id
    critical = azurerm_monitor_action_group.critical.id
  }
}

# =========================================
# Output: Alert Processing Rules
# =========================================

output "alert_processing_rule_ids" {
  description = "The IDs of the created alert processing (suppression) rules."
  value = {
    maintenance_suppression = azurerm_monitor_alert_processing_rule_suppression.maintenance_window.id
    # Note: after_hours_suppression is conditional and may not exist for prod environments.
    after_hours_suppression = length(azurerm_monitor_alert_processing_rule_suppression.after_hours_low_severity) > 0 ? azurerm_monitor_alert_processing_rule_suppression.after_hours_low_severity[0].id : null
  }
}

# =========================================
# Output: Alert Rule IDs
# =========================================

output "metric_alert_ids" {
  description = "A map of all metric-based alert rule IDs created by this module."
  value = {
    # Azure Level
    subscription_quota_usage = azurerm_monitor_metric_alert.subscription_quota_usage.id

    # Node Level
    node_cpu_warning     = azurerm_monitor_metric_alert.node_cpu_warning.id
    node_cpu_critical    = azurerm_monitor_metric_alert.node_cpu_critical.id
    node_memory_warning  = azurerm_monitor_metric_alert.node_memory_warning.id
    node_memory_critical = azurerm_monitor_metric_alert.node_memory_critical.id

    # Pod Level
    pod_restart_rate_warning = azurerm_monitor_metric_alert.pod_restart_alert_warning.id
    # Note: A critical restart alert resource would need to be added to alerts_infra.tf to be outputted.
  }
}

output "log_alert_ids" {
  description = "A map of all log-based (KQL) alert rule IDs created by this module."
  value = {
    # Azure Level
    cost_anomalies = azurerm_monitor_scheduled_query_rules_alert_v2.cost_anomalies.id
    nsg_blocks     = azurerm_monitor_scheduled_query_rules_alert_v2.nsg_blocks.id

    # Infrastructure - Node Level
    node_status_issues      = azurerm_monitor_scheduled_query_rules_alert_v2.node_status_issues.id
    node_readiness_flapping = azurerm_monitor_scheduled_query_rules_alert_v2.node_readiness_flapping.id
    node_pressure_events    = azurerm_monitor_scheduled_query_rules_alert_v2.node_pressure_events.id

    # Infrastructure - Pod & Container Level
    kube_container_waiting   = azurerm_monitor_scheduled_query_rules_alert_v2.kube_container_waiting.id
    pod_unavailable_critical = azurerm_monitor_scheduled_query_rules_alert_v2.pod_unavailable_critical.id

    # Infrastructure - Cluster Resource Management
    cluster_cpu_overcommit    = azurerm_monitor_scheduled_query_rules_alert_v2.kube_cpu_quota_overcommit.id
    cluster_memory_overcommit = azurerm_monitor_scheduled_query_rules_alert_v2.kube_memory_quota_overcommit.id

    # Platform - Control Plane
    api_server_latency_warning  = azurerm_monitor_scheduled_query_rules_alert_v2.api_server_latency_warning.id
    api_server_latency_critical = azurerm_monitor_scheduled_query_rules_alert_v2.api_server_latency_critical.id
    etcd_latency_warning        = azurerm_monitor_scheduled_query_rules_alert_v2.etcd_latency_warning.id
    etcd_latency_critical       = azurerm_monitor_scheduled_query_rules_alert_v2.etcd_latency_critical.id
    etcd_health                 = azurerm_monitor_scheduled_query_rules_alert_v2.etcd_health.id

    # Platform - Workload Health
    crashloop_backoff            = azurerm_monitor_scheduled_query_rules_alert_v2.crashloop_backoff.id
    oom_killed                   = azurerm_monitor_scheduled_query_rules_alert_v2.oom_killed.id
    deployment_replica_mismatch  = azurerm_monitor_scheduled_query_rules_alert_v2.deployment_replica_mismatch.id
    job_failed                   = azurerm_monitor_scheduled_query_rules_alert_v2.kube_job_failed.id
    job_stale                    = azurerm_monitor_scheduled_query_rules_alert_v2.kube_job_stale.id
    statefulset_replica_mismatch = azurerm_monitor_scheduled_query_rules_alert_v2.kube_statefulset_replica_mismatch.id
    failed_pod_scheduling        = azurerm_monitor_scheduled_query_rules_alert_v2.failed_pod_scheduling.id
  }
}

# =========================================
# Output: Summary
# =========================================

output "alert_summary" {
  description = "A summary of the monitoring configuration deployed by this module."
  value = {
    module_pattern       = ".tfvars driven for maximum flexibility"
    coverage_scope       = "Azure Resources, AKS Infrastructure, and Kubernetes Platform"
    total_alerts_defined = "Approx. 30+" # The count of alert resources defined in the module.
  }
}
