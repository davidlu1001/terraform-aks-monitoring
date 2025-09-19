# alerts_infra.tf
#
# Contains all alerts related to the core Kubernetes Infrastructure.
# This includes Nodes, Pods, Storage, and general cluster resource management.

# =========================================
# 2. Kubernetes Infrastructure Alerts
# =========================================

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 2.1 Node Infrastructure Health
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Node CPU Usage - Warning
resource "azurerm_monitor_metric_alert" "node_cpu_warning" {
  name                = "${var.environment_short_prefix}-alert-node-cpu-warning"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_kubernetes_cluster.aks.id]
  description         = "Node CPU usage is consistently high (Warning level)."
  severity            = 2
  auto_mitigate       = true
  window_size         = "PT15M"
  frequency           = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.node_cpu_warning_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.standard.id
  }

  tags = local.alert_tags
}

# Node CPU Usage - Critical
resource "azurerm_monitor_metric_alert" "node_cpu_critical" {
  name                = "${var.environment_short_prefix}-alert-node-cpu-critical"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_kubernetes_cluster.aks.id]
  description         = "Node CPU usage is critically high."
  severity            = 1
  auto_mitigate       = true
  window_size         = "PT10M"
  frequency           = "PT1M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.node_cpu_critical_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = local.alert_tags
}

# Node Memory Usage - Warning
resource "azurerm_monitor_metric_alert" "node_memory_warning" {
  name                = "${var.environment_short_prefix}-alert-node-memory-warning"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_kubernetes_cluster.aks.id]
  description         = "Node memory usage is consistently high (Warning level)."
  severity            = 2
  auto_mitigate       = true
  window_size         = "PT15M"
  frequency           = "PT5M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.node_memory_warning_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.standard.id
  }

  tags = local.alert_tags
}

# Node Memory Usage - Critical
resource "azurerm_monitor_metric_alert" "node_memory_critical" {
  name                = "${var.environment_short_prefix}-alert-node-memory-critical"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_kubernetes_cluster.aks.id]
  description         = "Node memory usage is critically high."
  severity            = 1
  auto_mitigate       = true
  window_size         = "PT15M"
  frequency           = "PT2M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.node_memory_critical_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = local.alert_tags
}

# KubeNodeUnreachable (Node Status Issues)
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "node_status_issues" {
  name                 = "${var.environment_short_prefix}-alert-node-unreachable"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "One or more nodes are in a 'NotReady' or 'Unknown' state."
  severity             = 1
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      KubeNodeInventory
      | where TimeGenerated > ago(15m)
      | where Status != "Ready"
      | summarize by Computer, Status
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
    custom_properties = {
      alert_name     = "KubeNodeUnreachable"
      alert_type     = "Symptom"
      severity_level = "P1"
      runbook_url    = "${var.runbook_base_url}/node-unreachable"
    }
  }

  tags = local.alert_tags
}

# KubeNodeReadinessFlapping
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "node_readiness_flapping" {
  name                 = "${var.environment_short_prefix}-alert-node-readiness-flapping"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "A node's readiness status is changing frequently, indicating instability."
  severity             = 2
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      KubeEvents
      | where TimeGenerated > ago(15m)
      | where ObjectKind == "Node" and Reason has "NodeNotReady"
      | summarize FlapCount = count() by Computer
      | project FlapCount
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = var.node_readiness_flapping_count
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "KubeNodeReadinessFlapping"
      alert_type     = "Cause"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/node-flapping"
    }
  }

  tags = local.alert_tags
}

# Node Pressure Events
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "node_pressure_events" {
  name                 = "${var.environment_short_prefix}-alert-node-pressure-events"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "Node is reporting pressure for Memory, Disk, or PIDs."
  severity             = 1
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      KubeEvents
      | where TimeGenerated > ago(15m)
      | where Reason has_any ("MemoryPressure", "DiskPressure", "PIDPressure")
      | summarize by Computer, Reason, Message
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
    custom_properties = {
      alert_name     = "NodePressureEvent"
      alert_type     = "Symptom"
      severity_level = "P1"
      runbook_url    = "${var.runbook_base_url}/node-pressure"
    }
  }

  tags = local.alert_tags
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 2.2 Pod & Container Infrastructure Health
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Pod Restart Rate High - Warning
resource "azurerm_monitor_metric_alert" "pod_restart_alert_warning" {
  name                = "${var.environment_short_prefix}-alert-pod-restart-rate-warning"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_kubernetes_cluster.aks.id]
  description         = "Pods are restarting frequently (Warning)."
  severity            = 2
  auto_mitigate       = true
  window_size         = "PT30M"
  frequency           = "PT10M"

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "kube_pod_container_status_restarts_total"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.pod_restart_warning_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.standard.id
  }

  tags = local.alert_tags
}

# KubeContainerWaiting
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "kube_container_waiting" {
  name                 = "${var.environment_short_prefix}-alert-kube-container-waiting"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "A container has been in a waiting state for an extended period."
  severity             = 2
  evaluation_frequency = "PT30M"
  window_duration      = "PT1H"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      KubePodInventory
      | where TimeGenerated > ago(1h)
      | where PodStatus in ("Pending", "ContainerCreating")
      | extend WaitDurationMinutes = todouble(datetime_diff('minute', now(), TimeGenerated))
      | summarize max(WaitDurationMinutes) by PodName, PodStatus, Namespace
      | project max_WaitDurationMinutes
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = var.pod_container_waiting_minutes_threshold
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "KubeContainerWaiting"
      alert_type     = "Symptom"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/pod-lifecycle"
    }
  }
  tags = local.alert_tags
}

# PodUnavailableCritical
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pod_unavailable_critical" {
  name                    = "${var.environment_short_prefix}-alert-pod-unavailable-critical"
  resource_group_name     = var.resource_group_name
  location                = var.location
  description             = "A critical pod is in a non-running state (e.g., Pending, Failed, Unknown)."
  severity                = 0
  evaluation_frequency    = "PT2M"
  window_duration         = "PT10M"
  scopes                  = [data.azurerm_log_analytics_workspace.main.id]
  auto_mitigation_enabled = false

  criteria {
    query                   = <<-QUERY
      KubePodInventory
      | where TimeGenerated > ago(10m)
      | where PodStatus !in ("Running", "Succeeded", "Completed")
      // Add a filter for critical pods by uncommenting and editing the line below
      // | where Namespace == "app" and PodName startswith "app-critical-component"
      | summarize by PodName, PodStatus, Namespace
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
    custom_properties = {
      alert_name     = "PodUnavailableCritical"
      alert_type     = "Symptom"
      severity_level = "P0"
      runbook_url    = "${var.runbook_base_url}/pod-unavailable"
    }
  }
  tags = local.alert_tags
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 2.3 Cluster Resource Management
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# KubeCPUQuotaOvercommit
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "kube_cpu_quota_overcommit" {
  name                 = "${var.environment_short_prefix}-alert-kube-cpu-quota-overcommit"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "Total CPU requests across all namespaces exceed the cluster's allocatable capacity."
  enabled              = true
  severity             = 2
  evaluation_frequency = "PT15M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      let requests = KubePodInventory
      | where TimeGenerated > ago(15m)
      | summarize PodRequests = sum(cpuRequestNanoCores);
      let capacity = KubeNodeInventory
      | where TimeGenerated > ago(15m)
      | summarize TotalCapacity = sum(allocatableCpuNanoCores);
      requests
      | extend joinKey = 1
      | join kind=inner (capacity | extend joinKey = 1) on joinKey
      | project Ratio = todouble(PodRequests) / todouble(TotalCapacity)
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = var.cluster_cpu_overcommit_ratio_threshold
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "KubeCPUQuotaOvercommit"
      alert_type     = "Cause"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/cluster-capacity"
    }
  }
  tags = local.alert_tags
}

# KubeMemoryQuotaOvercommit
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "kube_memory_quota_overcommit" {
  name                 = "${var.environment_short_prefix}-alert-kube-memory-quota-overcommit"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "Total Memory requests across all namespaces exceed the cluster's allocatable capacity."
  enabled              = true
  severity             = 2
  evaluation_frequency = "PT15M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      let requests = KubePodInventory
      | where TimeGenerated > ago(15m)
      | summarize PodRequests = sum(memoryRequestBytes);
      let capacity = KubeNodeInventory
      | where TimeGenerated > ago(15m)
      | summarize TotalCapacity = sum(allocatableMemoryBytes);
      requests
      | extend joinKey = 1
      | join kind=inner (capacity | extend joinKey = 1) on joinKey
      | project Ratio = todouble(PodRequests) / todouble(TotalCapacity)
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = var.cluster_memory_overcommit_ratio_threshold
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "KubeMemoryQuotaOvercommit"
      alert_type     = "Cause"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/cluster-capacity"
    }
  }
  tags = local.alert_tags
}
