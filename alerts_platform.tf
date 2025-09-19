# alerts_platform.tf
#
# Contains alerts related to the Kubernetes Platform, including:
# 1. Control Plane components (API Server, etcd, Scheduler, Controller Manager).
# 2. Platform Workload health (Deployments, StatefulSets, Jobs, etc.).

# =========================================
# 3. Control Plane Health Alerts
# =========================================

# API Server Latency High - Warning
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "api_server_latency_warning" {
  name                 = "${var.environment_short_prefix}-alert-api-server-latency-warning"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "Kubernetes API server response latency is high (Warning)."
  severity             = 2
  evaluation_frequency = "PT5M"
  window_duration      = "PT10M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    # CORRECTED: The KQL query now only projects the value. The threshold logic is handled here.
    query                   = <<-QUERY
      InsightsMetrics
      | where TimeGenerated > ago(10m)
      | where Namespace == "kube-system" and Name == "apiserver_request_latencies_bucket"
      | extend LatencyInMs = Val / 1000 // Convert microseconds to ms
      | summarize P95Latency = percentile(LatencyInMs, 95)
      | project P95Latency
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = var.api_server_latency_warning_ms
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "APIServerLatencyHighWarning"
      alert_type     = "Cause"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/control-plane-health"
    }
  }
  tags = local.alert_tags
}

# API Server Latency High - Critical
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "api_server_latency_critical" {
  name                 = "${var.environment_short_prefix}-alert-api-server-latency-critical"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "Kubernetes API server response latency is critically high."
  severity             = 1
  evaluation_frequency = "PT2M"
  window_duration      = "PT5M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      InsightsMetrics
      | where TimeGenerated > ago(5m)
      | where Namespace == "kube-system" and Name == "apiserver_request_latencies_bucket"
      | extend LatencyInMs = Val / 1000 // Convert microseconds to ms
      | summarize P95Latency = percentile(LatencyInMs, 95)
      | project P95Latency
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = var.api_server_latency_critical_ms
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
    custom_properties = {
      alert_name     = "APIServerLatencyHighCritical"
      alert_type     = "Cause"
      severity_level = "P1"
      runbook_url    = "${var.runbook_base_url}/control-plane-health"
    }
  }
  tags = local.alert_tags
}

# Etcd Latency High - Warning
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "etcd_latency_warning" {
  name                 = "${var.environment_short_prefix}-alert-etcd-latency-warning"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "etcd request latency is high (Warning)."
  severity             = 2
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      InsightsMetrics
      | where TimeGenerated > ago(15m)
      | where Namespace == "kube-system" and Name == "etcd_request_latencies_bucket"
      | extend LatencyInMs = Val / 1000 // Convert microseconds to ms
      | summarize P95Latency = percentile(LatencyInMs, 95)
      | project P95Latency
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = var.etcd_latency_warning_ms
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "EtcdLatencyHighWarning"
      alert_type     = "Cause"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/control-plane-health"
    }
  }
  tags = local.alert_tags
}

# Etcd Latency High - Critical
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "etcd_latency_critical" {
  name                 = "${var.environment_short_prefix}-alert-etcd-latency-critical"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "etcd request latency is critically high."
  severity             = 1
  evaluation_frequency = "PT2M"
  window_duration      = "PT10M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      InsightsMetrics
      | where TimeGenerated > ago(10m)
      | where Namespace == "kube-system" and Name == "etcd_request_latencies_bucket"
      | extend LatencyInMs = Val / 1000 // Convert microseconds to ms
      | summarize P95Latency = percentile(LatencyInMs, 95)
      | project P95Latency
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = var.etcd_latency_critical_ms
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
    custom_properties = {
      alert_name     = "EtcdLatencyHighCritical"
      alert_type     = "Cause"
      severity_level = "P1"
      runbook_url    = "${var.runbook_base_url}/control-plane-health"
    }
  }
  tags = local.alert_tags
}


# Etcd Health Issues
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "etcd_health" {
  name                    = "${var.environment_short_prefix}-alert-etcd-health"
  resource_group_name     = var.resource_group_name
  location                = var.location
  description             = "etcd cluster is reporting health issues, which is critical for cluster state."
  severity                = 0 # Critical P0
  evaluation_frequency    = "PT2M"
  window_duration         = "PT5M"
  scopes                  = [data.azurerm_log_analytics_workspace.main.id]
  auto_mitigation_enabled = false

  criteria {
    query                   = <<-QUERY
      ContainerLog
      | where TimeGenerated > ago(5m)
      | where PodName hasprefix "etcd"
      | where LogEntry has_any ("error", "failed", "unhealthy", "leader election")
      | summarize by LogEntry, PodName
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
    custom_properties = {
      alert_name     = "EtcdHealthIssues"
      alert_type     = "Symptom"
      severity_level = "P0"
      runbook_url    = "${var.runbook_base_url}/control-plane-health"
    }
  }
  tags = local.alert_tags
}

# =========================================
# 4. Platform Workload Health Alerts
# =========================================

# KubePodCrashLooping
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "crashloop_backoff" {
  name                 = "${var.environment_short_prefix}-alert-crashloop-backoff"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "Pods are in a CrashLoopBackOff state, indicating a recurring startup failure."
  severity             = 1
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      KubePodInventory
      | where TimeGenerated > ago(15m)
      | where PodStatus == "CrashLoopBackOff"
      | summarize by PodName, Namespace
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
    custom_properties = {
      alert_name     = "KubePodCrashLooping"
      alert_type     = "Symptom"
      severity_level = "P1"
      runbook_url    = "${var.runbook_base_url}/pod-failures"
    }
  }
  tags = local.alert_tags
}

# KubeContainerOOMKilledCount
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "oom_killed" {
  name                 = "${var.environment_short_prefix}-alert-oom-killed"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "A container was OOMKilled (Out of Memory), indicating memory limits are too low."
  severity             = 1
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      KubeEvents
      | where TimeGenerated > ago(15m)
      | where Reason == "OOMKilling"
      | summarize by Name, Namespace, Message
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
    custom_properties = {
      alert_name     = "KubeContainerOOMKilled"
      alert_type     = "Symptom"
      severity_level = "P1"
      runbook_url    = "${var.runbook_base_url}/pod-oomkilled"
    }
  }
  tags = local.alert_tags
}

# KubeDeploymentReplicasMismatch
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "deployment_replica_mismatch" {
  name                 = "${var.environment_short_prefix}-alert-deployment-replica-mismatch"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "The number of available replicas for a deployment does not match the desired state."
  severity             = 2
  evaluation_frequency = "PT10M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      InsightsMetrics
      | where TimeGenerated > ago(15m)
      | where Name == 'kube_deployment_spec_replicas'
      | extend deployment_name = tostring(todynamic(Tags).deployment)
      | summarize desired_replicas = max(Val) by deployment_name, Namespace
      | join kind=inner (
          InsightsMetrics
          | where TimeGenerated > ago(15m)
          | where Name == 'kube_deployment_status_replicas_available'
          | extend deployment_name = tostring(todynamic(Tags).deployment)
          | summarize available_replicas = max(Val) by deployment_name, Namespace
      ) on deployment_name, Namespace
      | where desired_replicas > available_replicas
      | summarize MismatchedCount = count()
      | project MismatchedCount
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "KubeDeploymentReplicasMismatch"
      alert_type     = "Symptom"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/workload-mismatch"
    }
  }
  tags = local.alert_tags
}

# KubeJobFailed
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "kube_job_failed" {
  name                 = "${var.environment_short_prefix}-alert-kube-job-failed"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "A Kubernetes job has failed to complete successfully."
  severity             = 2
  evaluation_frequency = "PT10M"
  window_duration      = "PT20M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      KubePodInventory
      | where TimeGenerated > ago(20m)
      | where ControllerKind == "Job" and PodStatus == "Failed"
      | summarize by ControllerName, Namespace
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "KubeJobFailed"
      alert_type     = "Symptom"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/job-failures"
    }
  }
  tags = local.alert_tags
}

# KubeStatefulSetReplicasMismatch
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "kube_statefulset_replica_mismatch" {
  name                 = "${var.environment_short_prefix}-alert-statefulset-replica-mismatch"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "The number of ready replicas for a StatefulSet does not match the desired state."
  severity             = 2
  evaluation_frequency = "PT10M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      InsightsMetrics
      | where TimeGenerated > ago(15m)
      | where Name == 'kube_statefulset_replicas'
      | extend statefulset_name = tostring(todynamic(Tags).statefulset)
      | summarize desired_replicas = max(Val) by statefulset_name, Namespace
      | join kind=inner (
          InsightsMetrics
          | where TimeGenerated > ago(15m)
          | where Name == 'kube_statefulset_status_replicas_ready'
          | extend statefulset_name = tostring(todynamic(Tags).statefulset)
          | summarize ready_replicas = max(Val) by statefulset_name, Namespace
      ) on statefulset_name, Namespace
      | where desired_replicas > ready_replicas
      | summarize MismatchedCount = count()
      | project MismatchedCount
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = 0
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "KubeStatefulSetReplicasMismatch"
      alert_type     = "Symptom"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/workload-mismatch"
    }
  }
  tags = local.alert_tags
}

# FailedPodScheduling
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "failed_pod_scheduling" {
  name                 = "${var.environment_short_prefix}-alert-failed-pod-scheduling"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "A pod has failed to schedule, indicating resource pressure or misconfiguration."
  severity             = 1
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      KubeEvents
      | where TimeGenerated > ago(15m)
      | where Reason == "FailedScheduling"
      | summarize by Name, Namespace, Message
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [azurerm_monitor_action_group.critical.id]
    custom_properties = {
      alert_name     = "FailedPodScheduling"
      alert_type     = "Symptom"
      severity_level = "P1"
      runbook_url    = "${var.runbook_base_url}/pod-scheduling"
    }
  }
  tags = local.alert_tags
}
