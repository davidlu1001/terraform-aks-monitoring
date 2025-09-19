# main.tf
#
# Core module logic including:
# 1. Data sources to fetch information about the existing environment (RG, LAW, AKS).
# 2. Action Groups for routing standard and critical alert notifications.
# 3. Alert Processing Rules for alert suppression during maintenance and after hours.

# =========================================
# Data Sources
# =========================================

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_log_analytics_workspace" "main" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group_name
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

# =========================================
# Action Groups
# =========================================

# Standard alerts action group for warning-level notifications (P2)
resource "azurerm_monitor_action_group" "standard" {
  name                = "${var.environment_short_prefix}-ag-standard"
  resource_group_name = var.resource_group_name
  short_name          = "std-${var.environment_short_prefix}"
  enabled             = true

  # Dynamically create email receivers for the SRE team list
  dynamic "email_receiver" {
    for_each = var.alert_email_sre
    content {
      name                    = "sre-team-${index(var.alert_email_sre, email_receiver.value)}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.teams_webhook_standard != "" ? [1] : []
    content {
      name                    = "teams-standard"
      service_uri             = var.teams_webhook_standard
      use_common_alert_schema = true
    }
  }

  tags = local.alert_tags
}

# Critical alerts action group for high-priority notifications (P0, P1)
resource "azurerm_monitor_action_group" "critical" {
  name                = "${var.environment_short_prefix}-ag-critical"
  resource_group_name = var.resource_group_name
  short_name          = "crit-${var.environment_short_prefix}"
  enabled             = true

  # Dynamically create email receivers for the primary on-call list
  dynamic "email_receiver" {
    for_each = var.alert_email_oncall_primary
    content {
      name                    = "oncall-primary-${index(var.alert_email_oncall_primary, email_receiver.value)}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  # Dynamically create email receivers for the secondary on-call list
  dynamic "email_receiver" {
    for_each = var.alert_email_oncall_secondary
    content {
      name                    = "oncall-secondary-${index(var.alert_email_oncall_secondary, email_receiver.value)}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  # Dynamically create email receivers for the manager escalation list
  dynamic "email_receiver" {
    for_each = var.alert_email_manager
    content {
      name                    = "manager-escalation-${index(var.alert_email_manager, email_receiver.value)}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.teams_webhook_critical != "" ? [1] : []
    content {
      name                    = "teams-critical"
      service_uri             = var.teams_webhook_critical
      use_common_alert_schema = true
    }
  }

  tags = local.alert_tags
}

# =========================================
# Alert Processing Rules - Flood Prevention
# =========================================

# Maintenance window suppression
resource "azurerm_monitor_alert_processing_rule_suppression" "maintenance_window" {
  name                = "${var.environment_short_prefix}-suppress-maintenance"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_resource_group.main.id]
  description         = "Suppress non-critical alerts during the planned maintenance window."
  enabled             = var.enable_maintenance_window_suppression

  condition {
    severity {
      operator = "NotEquals"
      values   = ["Sev0"] # Suppress everything except Critical P0 alerts
    }
  }

  schedule {
    # This effective_from date can remain static, it just marks when the rule becomes active.
    effective_from = "2025-01-01T00:00:00Z"
    time_zone      = var.maintenance_window_timezone

    # A single 'recurrence' block contains both the 'weekly' and 'daily' blocks
    # to define a precise time window on specific days.
    recurrence {
      daily {
        start_time = var.maintenance_window_start_time
        end_time   = var.maintenance_window_end_time
      }
      weekly {
        days_of_week = var.maintenance_window_days_of_week
      }
    }
  }
  tags = local.alert_tags
}

# Low severity suppression during non-business hours for QA environments ONLY
resource "azurerm_monitor_alert_processing_rule_suppression" "after_hours_low_severity" {
  # This resource is now created if the current environment name is in the list of specified environments.
  count = contains(var.after_hours_suppression_environments, var.environment_name) ? 1 : 0

  name                = "${var.environment_short_prefix}-suppress-afterhours"
  resource_group_name = var.resource_group_name
  scopes              = [data.azurerm_resource_group.main.id]
  description         = "Suppress low severity alerts outside business hours."
  enabled             = var.enable_after_hours_suppression

  condition {
    severity {
      operator = "Equals"
      values   = ["Sev2", "Sev3", "Sev4"]
    }
  }

  schedule {
    effective_from = "2025-01-01T00:00:00Z"
    time_zone      = var.after_hours_suppression_timezone

    recurrence {
      daily {
        start_time = var.after_hours_start_time
        end_time   = var.after_hours_end_time
      }
    }
  }
  tags = local.alert_tags
}
