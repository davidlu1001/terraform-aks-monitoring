# AKS Observability Design for Services

## Document Version History

| Version | Date           | Author | Key Changes                                                                                                                            |
| :------ | :------------- | :----- | :------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | August 2025    | Admin  | Initial comprehensive design with 55 alerts.                                                                                           |
| 1.1     | September 2025 | Admin  | Reviewed implementation feasibility, identified application monitoring gap, and refined alert definitions.                             |
| 2.0     | September 2025 | Admin  | Aligned document with the completed, fully parameterized Terraform module, updated implementation status, and standardized formatting. |

## Summary

This document outlines a comprehensive observability strategy for services running on Azure Kubernetes Service (AKS). The strategy is realized through a **fully generic, reusable Terraform module** that leverages Azure Monitor and Container Insights. The design incorporates Azure's recommended metric alerts and SRE best practices. It is optimized for multi-environment deployments (e.g., QA, Production), supports timezone-aware suppression rules, and provides a clear, actionable alert taxonomy.

## Design Objectives

- **Proactive Detection**: Identify issues before they impact users through comprehensive monitoring.
- **Cost Optimization**: Enable efficient use of Azure Monitor through intelligent data collection.
- **Scalability**: Support growing application workloads with minimal operational overhead.
- **Operational Clarity**: Provide clear alert classification and actionable metadata for efficient incident response.
- **Regional Optimization**: Allow for fully configurable, timezone-aware maintenance and alerting schedules.
- **Modular Implementation**: Ensure the design is fully implemented as a standardized, reusable Infrastructure-as-Code (IaC) module.

## Architecture Overview

### Approved Monitoring Stack
- **Azure Monitor**: Core telemetry platform and alerting engine.
- **Container Insights**: AKS-specific monitoring with enhanced container visibility.
- **Log Analytics Workspace**: Centralized log storage and analysis.
- **Action Groups**: Role-based notification system (Email, Teams).
- **Alert Processing Rules**: Intelligent suppression and grouping.

### Observability Data Flow
```

┌─────────────────────────────────────────────────────────────┐
│                     AKS Cluster Sources                     │
├─────────────────┬───────────────────┬─────────────────────┤
│ • App Pods      │ • Node Metrics    │ • Control Plane     │
│ • App Logs      │ • System Events   │ • API Server        │
│ • Health Checks │ • Resource Usage  │ • Etcd/Scheduler    │
└─────────────────┴───────────────────┴─────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│                Container Insights Collection                │
├─────────────────┬───────────────────┬─────────────────────┤
│ • Performance   │ • Health Data     │ • Log Aggregation   │
│ • Metrics Store │ • Event Capture   │ • Alert Evaluation  │
└─────────────────┴───────────────────┴─────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│                 Log Analytics Workspace                     │
├─────────────────┬───────────────────┬─────────────────────┤
│ • ContainerLogv2│ • Perf Tables     │ • KubeEvents        │
│ • InsightsMetrics│ • Alert Queries  │ • Custom Analytics  │
└─────────────────┴───────────────────┴─────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│                    Alert Classification                     │
├─────────────────┬───────────────────┬─────────────────────┤
│ • Symptom Alerts│ • Cause Alerts    │ • Severity Levels   │
│ • Customer Impact│ • Root Cause     │ • Escalation Paths  │
└─────────────────┴───────────────────┴─────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│                 Notification & Response                     │
├─────────────────┬───────────────────┬─────────────────────┤
│ • Email Groups  │ • Time-aware      │ • Runbook Links     │
│ • Role-based    │ • Suppression     │ • Escalation Matrix │
└─────────────────┴───────────────────┴─────────────────────┘

```

## 📊 Alert Taxonomy & Classification

### Alert Structure Overview
Based on SRE best practices, the alerts provided by the base Terraform module are organized into **4 primary categories**.

```

Infrastructure & Platform Alerts
├── Azure Resource Level (4 alerts)
├── Kubernetes Infrastructure (30 alerts)
├── Control Plane Health (7 alerts)
└── Platform Workload Health (15 alerts)

````
*Note: Application-specific alerts are to be built on top of this foundational module.*

### Alert Type Classification
- **Symptom Alerts**: Alerts that indicate direct customer or service impact (e.g., `PodUnavailableCritical`).
- **Cause Alerts**: Alerts that help identify the root cause of an issue (e.g., `NodeCPUWarning`).

### Severity Distribution
- **Critical (Sev0 / P0)**: Service-down or imminent failure scenarios. Requires immediate action.
- **High (Sev1 / P1)**: Significant service degradation or potential for critical failure. Requires urgent attention.
- **Warning (Sev2 / P2)**: Service degradation, early warning signs, or non-critical failures. Requires attention within business hours.

## 🔍 Detailed Alert Categories

*(Note: All thresholds in this section are examples. The actual values are controlled by the user via `.tfvars` files.)*

### 1. Azure Resource Level Alerts
**Purpose**: Monitor Azure subscription and regional service health impacting the AKS cluster.

| Alert Name                         | Description                        | Default Threshold  | Severity |
| :--------------------------------- | :--------------------------------- | :----------------- | :------- |
| **Azure Subscription Quota Usage** | Resource quota approaching limits  | >85% quota usage   | Warning  |
| **Azure Service Health Incidents** | Regional Azure service incidents   | Any incident       | High     |
| **Cost Anomaly Detection**         | Unusual spending patterns          | >50% cost increase | Warning  |
| **Network Security Group Blocks**  | High volume of blocked connections | >100 blocks/30min  | Warning  |

### 2. Kubernetes Infrastructure Alerts
**Purpose**: Monitor the underlying AKS cluster infrastructure, including nodes and pods.

#### 2.1 Node Infrastructure Health
| Alert Name                    | Description                         | Default Threshold    | Severity |
| :---------------------------- | :---------------------------------- | :------------------- | :------- |
| **Node CPU Critical**         | Critical node CPU usage             | 90%                  | High     |
| **Node Memory Critical**      | Critical node memory usage          | 95%                  | High     |
| **KubeNodeUnreachable**       | Node marked unreachable             | Any unreachable node | High     |
| **KubeNodeReadinessFlapping** | Node status changing frequently     | >3 changes/15min     | Warning  |
| **Node Pressure Events**      | Resource pressure (Memory/Disk/PID) | Any pressure event   | High     |
| **Kubelet Health Issues**     | Kubelet service problems            | Any Kubelet error    | High     |

#### 2.2 Pod & Container Health
| Alert Name                   | Description                           | Default Threshold     | Severity |
| :--------------------------- | :------------------------------------ | :-------------------- | :------- |
| **Pod Restart Rate High**    | High pod restart frequency            | >5 restarts/30min     | Warning  |
| **KubeContainerWaiting**     | Container waiting for extended period | >60 minutes           | Warning  |
| **Pod Unavailable Critical** | Critical pods are unavailable         | Any critical pod down | Critical |

*(... and many other alerts as defined in the Terraform files.)*

### 3. Control Plane Health Alerts
**Purpose**: Monitor the Kubernetes master components that manage the cluster.

| Alert Name                      | Description                       | Default Threshold | Severity |
| :------------------------------ | :-------------------------------- | :---------------- | :------- |
| **API Server Latency Critical** | Critical API response latency     | >500ms P95        | High     |
| **Etcd Latency Critical**       | Critical etcd transaction latency | >500ms P95        | High     |
| **Etcd Health Issues**          | Etcd cluster reports errors       | Any etcd error    | Critical |

### 4. Platform Workload Health Alerts
**Purpose**: Monitor Kubernetes workload patterns and application lifecycle events.

| Alert Name                         | Description                          | Default Threshold     | Severity |
| :--------------------------------- | :----------------------------------- | :-------------------- | :------- |
| **KubePodCrashLooping**            | Pod is in a `CrashLoopBackOff` state | Any pod crash-looping | High     |
| **KubeContainerOOMKilled**         | Container killed due to OOM          | Any OOMKilled event   | High     |
| **KubeDeploymentReplicasMismatch** | Deployment replicas mismatch         | Spec ≠ Available      | Warning  |
| **Failed Pod Scheduling**          | Pods are unable to be scheduled      | Any unschedulable pod | High     |

### 5. Application-Specific Monitoring
**Purpose**: To be built by application teams using the foundational module. This involves creating separate Terraform configurations that define KQL queries for application-specific metrics (e.g., error rates, business transaction latency).

## 🚨 Alert Configuration Strategy

### Alert Metadata and Actionability
To enhance operational clarity, all Terraform alert resources include a `custom_properties` block. This metadata directly links an alert to this design document and the team's runbooks.

**Example Terraform Implementation**:
```terraform
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pod_storage_latency" {
  # ... other properties
  action {
    action_groups = [azurerm_monitor_action_group.standard.id]
    
    custom_properties = {
      alert_name      = "Pod Storage Latency High"
      alert_type      = "Cause"
      severity_level  = "P2"
      runbook_url     = "${var.runbook_base_url}/aks-pod-storage-latency"
      design_doc      = "AKS Observability Design v5.1"
    }
  }
}
````

### Environment-Specific Thresholds

The Terraform module is designed to accept all thresholds as input variables. This allows each team to maintain separate `.tfvars` files for their environments, such as `qa.tfvars` and `prod.tfvars`, with different sensitivity levels.

**Example `prod.tfvars` snippet:**

```hcl
# Stricter thresholds for Production
node_cpu_critical_threshold    = 85  # vs 90 in QA
pod_restart_warning_threshold  = 3   # vs 5 in QA
```

## 🛡️ Alert Processing & Suppression Rules

The module provides two fully configurable suppression rules. The schedule for these rules is controlled entirely by variables in the user's `.tfvars` file.

#### Maintenance Window Suppression

  - **Purpose**: Suppress non-critical alerts during planned maintenance activities.
  - **Configuration**: `maintenance_window_*` variables in `variables.tf`.
  - **Default**: Suppresses Sev1-Sev4 alerts on Sundays from 2:00 AM to 4:00 AM (Pacific/Auckland).

#### After-Hours Suppression (for non-production)

  - **Purpose**: Reduce alert fatigue by suppressing low-severity alerts outside of business hours in non-production environments.
  - **Configuration**: `after_hours_*` variables in `variables.tf`.
  - **Default**: Suppresses Sev2-Sev4 alerts from 6:00 PM to 8:00 AM (Pacific/Auckland) in environments specified in `after_hours_suppression_environments` (defaults to `["qa"]`).

## 🔧 Implementation Roadmap & Status

### Module Status: ✅ **Complete & Ready for Use**

The foundational Terraform module (`terraform-aks-monitoring`) is complete. It has been fully parameterized and aligns with the best practices outlined in this document.

## 🎯 Success Metrics & KPIs

### Monitoring Effectiveness

  - **Mean Time to Detection (MTTD)**: Target \< 5 minutes for critical infrastructure issues.
  - **Alert Accuracy**: Target \> 95% true positive rate (low noise).
  - **Module Adoption**: Track the number of teams/projects successfully using this module.

### Operational Excellence

  - **Service Availability**: Maintain 99.9% uptime for critical services.
  - **Incident Response**: Reduce MTTR by providing actionable alerts with clear runbook links.
