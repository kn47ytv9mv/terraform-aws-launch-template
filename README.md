# terraform-aws-launch-template

Terraform module for an EC2 launch template — the reusable description
of an instance that an autoscaling group, a fleet, or a one-off
`RunInstances` call launches from.

## Cost

Launch templates carry no charge. What they launch does. This module
has no cost impact of its own.

## Design

Split from
[`terraform-aws-autoscaling-group`](https://github.com/kn47ytv9mv/terraform-aws-autoscaling-group)
because one template is routinely shared by several groups — a blue and
a green group, or one per availability zone — and an outside consumer
references it by ID. It is also useful entirely on its own, for a fleet
or a manual launch.

`http_tokens` defaults to `'required'`, which is IMDSv2, rather than
AWS's own `'optional'`. Under IMDSv1 any process that can make an HTTP
request from the instance — including one reached through a
server-side request forgery bug in the application — can read the
instance's IAM credentials straight out of the metadata service. IMDSv2
requires a session token obtained by a `PUT`, which such a request
cannot make. Set `'optional'` only for software that genuinely cannot
speak IMDSv2.

Volumes in `block_device_mappings` default to `encrypted = true` and
`delete_on_termination = true`. An unencrypted volume cannot be
encrypted in place later, and a volume left behind after its instance
terminates keeps billing.

`update_default_version` defaults **true**. A launch template is
versioned, and a consumer tracking `'$Default'` only picks up a change
when the default moves — without this, editing the template creates a
new version that nothing ever launches.

Tags set through `tags` land on the template itself and do **not** reach
launched instances. Use `tag_specifications` for that; it is the only
mechanism AWS offers, and the distinction catches people out.

## Usage

```hcl
module "template" {
  source = "kn47ytv9mv/launch-template/aws"

  name          = "app"
  image_id      = "ami-0123456789abcdef0"
  instance_type = "t3.micro"

  vpc_security_group_ids    = [module.security_group.id]
  iam_instance_profile_name = "app"

  block_device_mappings = [
    { device_name = "/dev/xvda", ebs = { volume_size = 20, volume_type = "gp3" } },
  ]

  tag_specifications = [
    { resource_type = "instance", tags = { Name = "app" } },
  ]
}
```

Or directly from this repository:

```hcl
module "template" {
  source = "github.com/kn47ytv9mv/terraform-aws-launch-template"

  image_id      = "ami-0123456789abcdef0"
  instance_type = "t3.micro"
  user_data     = base64encode("#!/bin/bash\ndnf install -y nginx\n")
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.9 |
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| name | Name of the launch template. If null, a unique name is generated. | `null` | no |
| description | Description of this version of the template. | `null` | no |
| image_id | AMI the instance boots from. AMI IDs are region-specific. | `null` | no |
| instance_type | Instance type (e.g. `'t3.micro'`). Leave null when an autoscaling group supplies the type instead. | `null` | no |
| key_name | Name of an EC2 key pair for SSH access. Prefer SSM Session Manager, which needs no open SSH port and no key to rotate. | `null` | no |
| user_data | Base64-encoded data run at first boot. Wrap plain text in `base64encode()`. Capped at 16 KB after encoding. | `null` | no |
| vpc_security_group_ids | IDs of the security groups applied to the instance, from `terraform-aws-vpc-security-groups`. | `null` | no |
| iam_instance_profile_arn | ARN of an IAM instance profile granting the instance its AWS permissions. Mutually exclusive with the name form. | `null` | no |
| iam_instance_profile_name | Name of an IAM instance profile. Mutually exclusive with the ARN form. | `null` | no |
| http_tokens | Whether the metadata service requires a session token (IMDSv2). Defaults to `'required'`. | `"required"` | no |
| http_endpoint | Whether the metadata service is reachable at all (`'enabled'`/`'disabled'`). | `null` | no |
| http_put_response_hop_limit | Network hops a metadata response may travel. Raise to 2 for a containerized workload needing instance credentials. | `null` | no |
| instance_metadata_tags | Whether instance tags are readable through the metadata service. | `null` | no |
| monitoring_enabled | Whether detailed CloudWatch monitoring collects metrics every minute rather than every five. Billed per instance. | `null` | no |
| ebs_optimized | Whether the instance is EBS-optimized. Most current-generation types are by default and reject being told otherwise. | `null` | no |
| disable_api_termination | Whether the instance refuses API termination. Does not prevent termination by an autoscaling group. | `null` | no |
| instance_initiated_shutdown_behavior | What a shutdown from inside the instance does (`'stop'` or `'terminate'`). | `null` | no |
| block_device_mappings | Volumes attached to the instance. `encrypted` and `delete_on_termination` default true within each `ebs` block. | `[]` | no |
| tag_specifications | Tags applied to resources the template creates, per resource type. Tags on the template itself do not reach launched instances. | `[]` | no |
| update_default_version | Whether a new version of the template also becomes the default. | `true` | no |
| tags | A map of tags to assign to the launch template itself. Does not propagate to instances. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the launch template. Feed this into `terraform-aws-autoscaling-group`'s `launch_template_id`. |
| arn | The ARN of the launch template. |
| name | The name of the launch template. |
| latest_version | The most recently created version number. |
| default_version | The version launched when a consumer asks for `'$Default'`. |

## License

MIT — see [LICENSE.md](LICENSE.md).
