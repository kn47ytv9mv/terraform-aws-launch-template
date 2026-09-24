resource "random_uuid" "resource" {}

resource "aws_launch_template" "resource" {
  name        = coalesce(var.name, random_uuid.resource.id)
  description = var.description

  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  user_data     = var.user_data

  vpc_security_group_ids = var.vpc_security_group_ids

  ebs_optimized                        = var.ebs_optimized
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  update_default_version               = var.update_default_version

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_arn != null || var.iam_instance_profile_name != null ? [1] : []

    content {
      arn  = var.iam_instance_profile_arn
      name = var.iam_instance_profile_name
    }
  }

  metadata_options {
    http_tokens                 = var.http_tokens
    http_endpoint               = var.http_endpoint
    http_put_response_hop_limit = var.http_put_response_hop_limit
    instance_metadata_tags      = var.instance_metadata_tags
  }

  dynamic "monitoring" {
    for_each = var.monitoring_enabled[*]

    content {
      enabled = monitoring.value
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings

    content {
      device_name = block_device_mappings.value.device_name

      dynamic "ebs" {
        for_each = block_device_mappings.value.ebs[*]

        content {
          volume_size           = ebs.value.volume_size
          volume_type           = ebs.value.volume_type
          iops                  = ebs.value.iops
          throughput            = ebs.value.throughput
          encrypted             = ebs.value.encrypted
          kms_key_id            = ebs.value.kms_key_id
          delete_on_termination = ebs.value.delete_on_termination
          snapshot_id           = ebs.value.snapshot_id
        }
      }
    }
  }

  dynamic "tag_specifications" {
    for_each = var.tag_specifications

    content {
      resource_type = tag_specifications.value.resource_type
      tags          = tag_specifications.value.tags
    }
  }

  tags = var.tags
}

output "id" {
  description = "The ID of the launch template. Feed this into terraform-aws-autoscaling-group's launch_template_id."
  value       = aws_launch_template.resource.id
}

output "arn" {
  description = "The ARN of the launch template."
  value       = aws_launch_template.resource.arn
}

output "name" {
  description = "The name of the launch template."
  value       = aws_launch_template.resource.name
}

output "latest_version" {
  description = "The most recently created version number of the template."
  value       = aws_launch_template.resource.latest_version
}

output "default_version" {
  description = "The version launched when a consumer asks for '$Default'."
  value       = aws_launch_template.resource.default_version
}
