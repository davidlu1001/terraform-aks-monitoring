# alerts_azure.tf
#
# Contains alerts related to the Azure Resource Level.
# These monitor subscription quotas, service health, cost, and networking.

# =========================================
# 1. Azure Resource Level Alerts (4 Alerts)
# =========================================

# Azure Subscription Quota Usage
resource "azurerm_monitor_metric_alert" "subscription_quota_usage" {
  name                = "${var.environment_short_prefix}-alert-subscription-quota"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  description         = "Azure subscription resource quota usage is approaching limits."
  severity            = 2
  auto_mitigate       = true
  window_size         = "PT1H"
  frequency           = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Capacity/resourceProviders"
    metric_name      = "UsagePercent"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = var.azure_subscription_quota_threshold

    dimension {
      name     = "resourceType"
      operator = "Include"
      values   = ["virtualMachines", "cores"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.standard.id
  }

  tags = local.alert_tags
}

# Azure Service Health Incidents
resource "azurerm_monitor_activity_log_alert" "service_health_incidents" {
  name                = "${var.environment_short_prefix}-alert-service-health"
  resource_group_name = var.resource_group_name
  scopes              = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}"]
  description         = "An Azure service health incident has been reported that may affect our services."
  enabled             = true
  location            = "global"

  criteria {
    category = "ServiceHealth"
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }

  tags = local.alert_tags
}

# Cost Anomaly Detection
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "cost_anomalies" {
  name                 = "${var.environment_short_prefix}-alert-cost-anomalies"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "Unusual spending patterns detected."
  severity             = 2
  evaluation_frequency = "PT6H"
  window_duration      = "P1D"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      Usage
      | where TimeGenerated > ago(1d)
      | summarize TotalCost = sum(PretaxCost) by bin(TimeGenerated, 6h)
      | extend BaselineCost = 100.0 // NOTE: This baseline is an example. For a real-world scenario, a more dynamic baseline query would be needed.
      | extend CostIncrease = ((TotalCost - BaselineCost) / BaselineCost) * 100.0
      | project CostIncrease
    QUERY
    time_aggregation_method = "Maximum"
    operator                = "GreaterThan"
    threshold               = var.azure_cost_anomaly_percentage_threshold
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "Cost Anomaly Detection"
      alert_type     = "Cause"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/cost-management"
    }
  }

  tags = local.alert_tags
}

# Network Security Group Blocks
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "nsg_blocks" {
  name                 = "${var.environment_short_prefix}-alert-nsg-blocks"
  resource_group_name  = var.resource_group_name
  location             = var.location
  description          = "High number of blocked connections by NSGs."
  severity             = 2
  evaluation_frequency = "PT15M"
  window_duration      = "PT30M"
  scopes               = [data.azurerm_log_analytics_workspace.main.id]

  criteria {
    query                   = <<-QUERY
      AzureNetworkAnalytics_CL
      | where TimeGenerated > ago(30m)
      | where FlowStatus_s == "D" // Denied flows
      | summarize BlockedConnections = count()
      | project BlockedConnections
    QUERY
    time_aggregation_method = "Total"
    operator                = "GreaterThan"
    threshold               = var.nsg_blocked_connections_threshold
  }

  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    custom_properties = {
      alert_name     = "Network Security Group Blocks"
      alert_type     = "Cause"
      severity_level = "P2"
      runbook_url    = "${var.runbook_base_url}/network-troubleshooting"
    }
  }

  tags = local.alert_tags
}
