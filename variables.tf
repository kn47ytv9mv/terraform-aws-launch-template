variable "name" {
  default     = null
  description = "Name of the launch template. If null, a unique name is generated."
}

variable "description" {
  default     = null
  description = "Description of this version of the template."
}

variable "image_id" {
  default     = null
  description = "AMI the instance boots from. AMI IDs are region-specific, so a template referencing one is not portable across regions."
}

variable "instance_type" {
  default     = null
  description = "Instance type (e.g. 't3.micro', 'm7g.large'). Leave null when an autoscaling group supplies the type instead, through a mixed instances policy or attribute-based selection."
}

variable "key_name" {
  default     = null
  description = "Name of an EC2 key pair for SSH access. Leave null and reach for SSM Session Manager instead — it needs no open SSH port and no key to distribute or rotate."
}

variable "user_data" {
  default     = null
  description = "Base64-encoded data run at first boot. Wrap plain text in base64encode(). Capped at 16 KB after encoding; anything larger belongs in S3, fetched by a small script here."
}

variable "vpc_security_group_ids" {
  default     = null
  description = "IDs of the security groups applied to the instance, from terraform-aws-vpc-security-groups. Mutually exclusive with network_interfaces — set security groups there instead when specifying interfaces explicitly."
}

variable "iam_instance_profile_arn" {
  default     = null
  description = "ARN of an IAM instance profile granting the instance its AWS permissions. Mutually exclusive with iam_instance_profile_name."
}

variable "iam_instance_profile_name" {
  default     = null
  description = "Name of an IAM instance profile granting the instance its AWS permissions. Mutually exclusive with iam_instance_profile_arn."

  validation {
    condition     = var.iam_instance_profile_arn == null || var.iam_instance_profile_name == null
    error_message = "At most one of iam_instance_profile_arn or iam_instance_profile_name may be set."
  }
}

variable "http_tokens" {
  default     = "required"
  description = "Whether the instance metadata service requires a session token, which is IMDSv2. Defaults to 'required' rather than AWS's own 'optional' — IMDSv1 lets any process that can make an HTTP request from the instance, including one reached through a server-side request forgery bug, read the instance's IAM credentials. Set 'optional' only for software that genuinely cannot speak IMDSv2."

  validation {
    condition     = contains(["required", "optional"], var.http_tokens)
    error_message = "http_tokens must be either 'required' (IMDSv2) or 'optional'."
  }
}

variable "http_endpoint" {
  default     = null
  description = "Whether the instance metadata service is reachable at all ('enabled' or 'disabled'). Disabling it removes the instance's ability to read its own IAM credentials. If null, AWS's own default ('enabled') applies."
}

variable "http_put_response_hop_limit" {
  default     = null
  description = "Network hops a metadata response may travel. The default of 1 stops a container on the instance from reaching the metadata service; raise it to 2 for a containerized workload that genuinely needs instance credentials."
}

variable "instance_metadata_tags" {
  default     = null
  description = "Whether instance tags are readable through the metadata service ('enabled' or 'disabled'). If null, AWS's own default ('disabled') applies."
}

variable "monitoring_enabled" {
  default     = null
  description = "Whether detailed CloudWatch monitoring collects metrics every minute rather than every five. Billed per instance. If null, AWS's own default (disabled) applies."
}

variable "ebs_optimized" {
  default     = null
  description = "Whether the instance is EBS-optimized, giving EBS its own dedicated bandwidth. Most current-generation instance types are optimized by default and reject being told otherwise. If null, AWS's own default applies."
}

variable "disable_api_termination" {
  default     = null
  description = "Whether the instance refuses termination through the API until the flag is cleared. Does not prevent termination by an autoscaling group. If null, AWS's own default (disabled) applies."
}

variable "instance_initiated_shutdown_behavior" {
  default     = null
  description = "What a shutdown issued from inside the instance does ('stop' or 'terminate'). If null, AWS's own default ('stop') applies."
}

variable "block_device_mappings" {
  default     = []
  description = "Volumes attached to the instance. device_name is the mount point AWS exposes ('/dev/xvda' is conventionally the root volume). Each entry's ebs block sets the volume's size, type, and encryption; encrypted defaults true here, since an unencrypted volume cannot be encrypted in place later."
  type = list(object({
    device_name = string
    ebs = optional(object({
      volume_size           = optional(number)
      volume_type           = optional(string)
      iops                  = optional(number)
      throughput            = optional(number)
      encrypted             = optional(bool, true)
      kms_key_id            = optional(string)
      delete_on_termination = optional(bool, true)
      snapshot_id           = optional(string)
    }))
  }))
}

variable "tag_specifications" {
  default     = []
  description = "Tags applied to resources the template creates, per resource type ('instance', 'volume', 'network-interface', 'spot-instances-request'). Tags on the template itself do not reach the instances it launches — that is what this is for."
  type = list(object({
    resource_type = string
    tags          = map(string)
  }))
}

variable "update_default_version" {
  default     = true
  description = "Whether creating a new version of the template also makes it the default. Defaults true, so an autoscaling group tracking '$Default' actually picks up changes rather than silently continuing to launch the original version."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the launch template itself. These do not propagate to launched instances — use tag_specifications for that."
}
