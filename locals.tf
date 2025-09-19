# locals.tf
#
# Defines local variables used throughout the module.
# In this .tfvars-driven pattern, its primary role is to construct a consistent set of tags.

locals {
  # Common tags to be applied to all resources created by this module.
  alert_tags = merge(var.tags, {
    Component   = "Monitoring"
    Environment = var.environment_name
    Timezone    = "Pacific/Auckland"
    DesignDoc   = "AKS-Observability"
  })
}
