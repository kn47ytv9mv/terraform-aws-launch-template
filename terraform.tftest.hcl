mock_provider "aws" {}

run "invalid_http_tokens_is_rejected" {
  command = plan

  variables {
    http_tokens = "maybe"
  }

  expect_failures = [var.http_tokens]
}

run "both_instance_profile_forms_are_rejected" {
  command = plan

  variables {
    iam_instance_profile_arn  = "arn:aws:iam::123456789012:instance-profile/app"
    iam_instance_profile_name = "app"
  }

  expect_failures = [var.iam_instance_profile_name]
}

run "name_defaults_to_random_uuid" {
  command = apply

  assert {
    condition     = aws_launch_template.resource.name == random_uuid.resource.id
    error_message = "Leaving name unset should fall back to the generated random_uuid."
  }
}

run "imdsv2_is_required_by_default" {
  command = plan

  assert {
    condition     = aws_launch_template.resource.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 should be required by default, so instance credentials are not readable through a plain unauthenticated request."
  }
}

run "update_default_version_defaults_true" {
  command = plan

  assert {
    condition     = aws_launch_template.resource.update_default_version == true
    error_message = "A new version should become the default, so a consumer tracking '$Default' actually picks up changes."
  }
}

run "no_instance_profile_block_by_default" {
  command = plan

  assert {
    condition     = length(aws_launch_template.resource.iam_instance_profile) == 0
    error_message = "Leaving both instance profile variables unset should emit no iam_instance_profile block."
  }
}

run "instance_profile_name_creates_one_block" {
  command = plan

  variables {
    iam_instance_profile_name = "app"
  }

  assert {
    condition     = length(aws_launch_template.resource.iam_instance_profile) == 1
    error_message = "Setting an instance profile name should emit exactly one iam_instance_profile block."
  }

  assert {
    condition     = aws_launch_template.resource.iam_instance_profile[0].name == "app"
    error_message = "The instance profile name should pass through unchanged."
  }
}

run "block_device_mappings_default_to_encrypted" {
  command = plan

  variables {
    block_device_mappings = [
      { device_name = "/dev/xvda", ebs = { volume_size = 20 } },
    ]
  }

  assert {
    condition     = length(aws_launch_template.resource.block_device_mappings) == 1
    error_message = "Each block_device_mappings entry should produce one mapping block."
  }

  assert {
    condition     = aws_launch_template.resource.block_device_mappings[0].ebs[0].encrypted == "true"
    error_message = "A volume should be encrypted by default, since an unencrypted volume cannot be encrypted in place later."
  }

  assert {
    condition     = aws_launch_template.resource.block_device_mappings[0].ebs[0].delete_on_termination == "true"
    error_message = "A volume should be deleted with its instance by default, rather than left orphaned and billing."
  }
}

run "tag_specifications_create_one_block_each" {
  command = plan

  variables {
    tag_specifications = [
      { resource_type = "instance", tags = { Name = "app" } },
      { resource_type = "volume", tags = { Name = "app" } },
    ]
  }

  assert {
    condition     = length(aws_launch_template.resource.tag_specifications) == 2
    error_message = "Each tag_specifications entry should produce one block."
  }
}

run "no_monitoring_block_by_default" {
  command = plan

  assert {
    condition     = length(aws_launch_template.resource.monitoring) == 0
    error_message = "Leaving monitoring_enabled unset should emit no monitoring block."
  }
}

run "readme_default_example" {
  command = plan

  variables {
    name                      = "app"
    image_id                  = "ami-0123456789abcdef0"
    instance_type             = "t3.micro"
    vpc_security_group_ids    = ["sg-1111"]
    iam_instance_profile_name = "app"

    block_device_mappings = [
      { device_name = "/dev/xvda", ebs = { volume_size = 20, volume_type = "gp3" } },
    ]

    tag_specifications = [
      { resource_type = "instance", tags = { Name = "app" } },
    ]
  }
}

run "readme_user_data_example" {
  command = plan

  variables {
    image_id      = "ami-0123456789abcdef0"
    instance_type = "t3.micro"
    user_data     = base64encode("#!/bin/bash\ndnf install -y nginx\n")
  }
}
