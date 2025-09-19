#------------------------------------------------------------------------------
# General Settings
#------------------------------------------------------------------------------
variable "environment_name" {
  description = "The name of the environment (e.g., 'qa', 'prod'). Used for naming and tagging."
  type        = string
}

variable "environment_short_prefix" {
  description = "A short prefix for the environment (e.g., 'q', 'p'). Used for short names in resources."
  type        = string
}

variable "location" {
  description = "The Azure region where resources are deployed."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the AKS cluster resides."
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace to scope alerts to."
  type        = string
}

variable "aks_cluster_name" {
  description = "The name of the AKS cluster to scope alerts to."
  type        = string
}

variable "runbook_base_url" {
  description = "The base URL for runbooks to be included in alert notifications."
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Notification Settings
#------------------------------------------------------------------------------
variable "alert_email_sre" {
  description = "A list of email addresses for the SRE team."
  type        = list(string)
  default     = []
}

variable "alert_email_oncall_primary" {
  description = "A list of email addresses for the primary on-call."
  type        = list(string)
  default     = []
}

variable "alert_email_oncall_secondary" {
  description = "A list of email addresses for the secondary on-call."
  type        = list(string)
  default     = []
}

variable "alert_email_manager" {
  description = "A list of email addresses for manager escalation."
  type        = list(string)
  default     = []
}

variable "teams_webhook_standard" {
  description = "The webhook URL for standard Teams notifications."
  type        = string
  default     = ""
}

variable "teams_webhook_critical" {
  description = "The webhook URL for critical Teams notifications."
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Maintenance Window Settings
#------------------------------------------------------------------------------
variable "enable_maintenance_window_suppression" {
  description = "If true, the maintenance window alert suppression rule will be created."
  type        = bool
  default     = true
}

variable "maintenance_window_timezone" {
  description = "The IANA timezone name for the maintenance window schedule (e.g., 'Pacific/Auckland', 'UTC')."
  type        = string
  default     = "Pacific/Auckland"
}

variable "maintenance_window_start_time" {
  description = "The start time for the maintenance window in HH:MM:SS format."
  type        = string
  default     = "02:00:00"
}

variable "maintenance_window_end_time" {
  description = "The end time for the maintenance window in HH:MM:SS format."
  type        = string
  default     = "04:00:00"
}

variable "maintenance_window_days_of_week" {
  description = "A list of days of the week for the maintenance window. Allowed values are 'Sunday', 'Monday', etc."
  type        = list(string)
  default     = ["Sunday"]
}

#------------------------------------------------------------------------------
# After-Hours Suppression Settings
#------------------------------------------------------------------------------
variable "enable_after_hours_suppression" {
  description = "If true, the after-hours alert suppression rule will be created for specified environments."
  type        = bool
  default     = true
}

variable "after_hours_suppression_environments" {
  description = "A list of environment names (e.g., ['qa', 'dev']) where the after-hours suppression rule should be active."
  type        = list(string)
  default     = ["qa"]
}

variable "after_hours_suppression_timezone" {
  description = "The IANA timezone name for the after-hours suppression schedule."
  type        = string
  default     = "Pacific/Auckland"
}

variable "after_hours_start_time" {
  description = "The start time for after-hours suppression (e.g., start of the evening)."
  type        = string
  default     = "18:00:00"
}

variable "after_hours_end_time" {
  description = "The end time for after-hours suppression (e.g., start of the morning)."
  type        = string
  default     = "08:00:00"
}

#------------------------------------------------------------------------------
# Alert Threshold Variables
# Using QA/less-sensitive values from the design doc as safe defaults.
#------------------------------------------------------------------------------

# --- Azure Level Thresholds ---
variable "azure_subscription_quota_threshold" {
  description = "The subscription resource quota usage percentage to trigger an alert."
  type        = number
  default     = 85
}
variable "azure_cost_anomaly_percentage_threshold" {
  description = "The percentage increase in cost over the baseline to trigger an anomaly alert."
  type        = number
  default     = 50
}
variable "nsg_blocked_connections_threshold" {
  description = "The number of blocked connections by an NSG in 30 minutes to trigger an alert."
  type        = number
  default     = 100
}

# --- Node Thresholds ---
variable "node_cpu_warning_threshold" {
  description = "CPU percentage threshold for a node warning alert."
  type        = number
  default     = 80
}
variable "node_cpu_critical_threshold" {
  description = "CPU percentage threshold for a node critical alert."
  type        = number
  default     = 90
}
variable "node_memory_warning_threshold" {
  description = "Memory percentage threshold for a node warning alert."
  type        = number
  default     = 85
}
variable "node_memory_critical_threshold" {
  description = "Memory percentage threshold for a node critical alert."
  type        = number
  default     = 95
}
variable "node_disk_warning_threshold" {
  description = "Disk percentage threshold for a node warning alert."
  type        = number
  default     = 80
}
variable "node_disk_critical_threshold" {
  description = "Disk percentage threshold for a node critical alert."
  type        = number
  default     = 95
}
variable "node_readiness_flapping_count" {
  description = "The number of readiness status changes in 15 minutes to be considered 'flapping'."
  type        = number
  default     = 3
}

# --- Pod & Container Thresholds ---
variable "pod_cpu_warning_threshold" {
  description = "Pod CPU usage percentage vs request for a warning alert."
  type        = number
  default     = 70
}
variable "pod_cpu_critical_threshold" {
  description = "Pod CPU usage percentage vs request for a critical alert."
  type        = number
  default     = 90
}
variable "pod_memory_warning_threshold" {
  description = "Pod memory usage percentage vs request for a warning alert."
  type        = number
  default     = 75
}
variable "pod_memory_critical_threshold" {
  description = "Pod memory usage percentage vs request for a critical alert."
  type        = number
  default     = 90
}
variable "pod_restart_warning_threshold" {
  description = "Number of pod restarts in a 30-minute window to trigger a warning."
  type        = number
  default     = 5
}
variable "pod_restart_critical_threshold" {
  description = "Number of pod restarts in a 30-minute window to trigger a critical alert."
  type        = number
  default     = 10
}
variable "pod_container_waiting_minutes_threshold" {
  description = "The number of minutes a container can be in a 'Waiting' state before an alert is fired."
  type        = number
  default     = 60
}

# --- Control Plane Thresholds (in Milliseconds) ---
variable "api_server_latency_warning_ms" {
  description = "P95 API server latency in milliseconds to trigger a warning."
  type        = number
  default     = 200
}

variable "api_server_latency_critical_ms" {
  description = "P95 API server latency in milliseconds to trigger a critical alert."
  type        = number
  default     = 500
}

variable "etcd_latency_warning_ms" {
  description = "P95 etcd latency in milliseconds to trigger a warning."
  type        = number
  default     = 100
}

variable "etcd_latency_critical_ms" {
  description = "P95 etcd latency in milliseconds to trigger a critical alert."
  type        = number
  default     = 500
}

# --- Cluster & Workload Thresholds ---
variable "cluster_cpu_overcommit_ratio_threshold" {
  description = "The ratio of total CPU requests to allocatable capacity to trigger an overcommit alert (e.g., 1.5 for 150%)."
  type        = number
  default     = 1.5
}

variable "cluster_memory_overcommit_ratio_threshold" {
  description = "The ratio of total memory requests to allocatable capacity to trigger an overcommit alert (e.g., 1.5 for 150%)."
  type        = number
  default     = 1.5
}
