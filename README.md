# terraform-aws-infra

[![CI](https://github.com/hermes-93/terraform-aws-infra/actions/workflows/ci.yml/badge.svg)](https://github.com/hermes-93/terraform-aws-infra/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Production-ready AWS infrastructure as code with Terraform. Deploys [cicd-pipeline-demo](https://github.com/hermes-93/cicd-pipeline-demo) as a containerised service behind an Application Load Balancer using ECS Fargate, inside a multi-AZ VPC.

> Part of the [DevOps portfolio](https://github.com/hermes-93) series.

---

## Architecture

```
                          ┌─── AWS Region (us-east-1) ────────────────────────┐
                          │                                                    │
  Internet ──► Route 53   │  ┌─ VPC 10.0.0.0/16 ──────────────────────────┐  │
                     │    │  │                                              │  │
                     ▼    │  │  Public subnets (us-east-1a / 1b)           │  │
              ┌────────┐  │  │  ┌──────────┐  ┌──────────┐                │  │
              │  ALB   │──┼──┼─►│  ALB     │  │  NAT GW  │                │  │
              └────────┘  │  │  └────┬─────┘  └────┬─────┘                │  │
                          │  │       │              │                       │  │
                          │  │  Private subnets (us-east-1a / 1b)          │  │
                          │  │  ┌────▼──────────────────────────────────┐  │  │
                          │  │  │          ECS Fargate Tasks             │  │  │
                          │  │  │  ┌──────────────┐ ┌──────────────┐   │  │  │
                          │  │  │  │  Task (0.25  │ │  Task (0.25  │   │  │  │
                          │  │  │  │  vCPU/512MB) │ │  vCPU/512MB) │   │  │  │
                          │  │  │  └──────────────┘ └──────────────┘   │  │  │
                          │  │  └───────────────────────────────────────┘  │  │
                          │  │                                              │  │
                          │  │  CloudWatch Logs ◄── ECS task logs          │  │
                          │  └──────────────────────────────────────────────┘  │
                          └────────────────────────────────────────────────────┘
```

### Resource summary

| Module | Resources |
|--------|-----------|
| `vpc` | VPC, 2×public + 2×private subnets, IGW, NAT GW(s), route tables |
| `alb` | Application Load Balancer, target group, HTTP listener, security group |
| `ecs` | ECS cluster (Container Insights), task definition, Fargate service, IAM roles, CloudWatch log group, App Autoscaling |

---

## Environment comparison

| Feature | dev | prod |
|---------|-----|------|
| NAT Gateways | 1 (single) | 1 per AZ (HA) |
| Task CPU | 256 (.25 vCPU) | 512 (.5 vCPU) |
| Task memory | 512 MB | 1024 MB |
| Replicas (desired) | 1 | 2 |
| Autoscaling | 1–2 | 2–10 |
| Capacity | FARGATE_SPOT | FARGATE (on-demand) |
| ALB deletion protection | off | on |
| Log retention | 3 days | 30 days |
| CPU scale target | 70% | 60% |

---

## CI pipeline

| Stage | Tool | Checks |
|-------|------|--------|
| fmt | `terraform fmt` | HCL formatting — all files |
| validate | `terraform validate` | Syntax + references — dev & prod |
| lint | `tflint` | Best practices, deprecated resources |
| security | Checkov | AWS CIS benchmark, 150+ rules |

---

## Usage

### Prerequisites
- Terraform ≥ 1.7
- AWS credentials with sufficient IAM permissions
- S3 bucket + DynamoDB table for state (see backend config in `envs/*/versions.tf`)

### Deploy dev

```bash
cd envs/dev

# 1. Uncomment and configure the backend block in versions.tf
# 2. Init
terraform init

# 3. Plan
terraform plan -out=tfplan

# 4. Apply
terraform apply tfplan
```

### Deploy prod

```bash
cd envs/prod
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Useful commands

```bash
# Check ALB URL after deploy
terraform output alb_dns_name

# Stream ECS logs
aws logs tail /ecs/cicd-pipeline-demo-dev --follow

# Force new ECS deployment (e.g. after image update)
aws ecs update-service \
  --cluster cicd-pipeline-demo-dev \
  --service cicd-pipeline-demo-dev \
  --force-new-deployment
```

---

## Key design decisions

| Decision | Reason |
|----------|--------|
| ECS Fargate over EC2/EKS | No node management; right-sized for a single-app portfolio |
| Single NAT in dev | Saves ~$32/month vs per-AZ NAT |
| Per-AZ NAT in prod | HA: AZ outage won't break outbound connectivity |
| FARGATE_SPOT in dev | 70% cheaper; dev tolerates occasional interruptions |
| `readonlyRootFilesystem` in task | Mirrors the container security posture from the Helm chart |
| App Autoscaling on CPU | ECS service scales independently of the Terraform state |
| `ignore_changes = [desired_count]` | Prevents Terraform from overriding autoscaler decisions |
| S3 + DynamoDB backend | Encrypted state, state locking, team-safe |

---

## Module structure

```
terraform-aws-infra/
├── modules/
│   ├── vpc/       main.tf  variables.tf  outputs.tf  versions.tf
│   ├── alb/       main.tf  variables.tf  outputs.tf  versions.tf
│   └── ecs/       main.tf  variables.tf  outputs.tf  versions.tf
└── envs/
    ├── dev/       versions.tf  main.tf  variables.tf  outputs.tf
    └── prod/      versions.tf  main.tf  variables.tf  outputs.tf
```

---

## Module reference

### `modules/vpc`

**Inputs**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Name prefix applied to all resources |
| `cidr` | `string` | `10.0.0.0/16` | VPC CIDR block |
| `availability_zones` | `list(string)` | — | AZs to use (≥ 2) |
| `single_nat_gateway` | `bool` | `true` | Share one NAT GW (cost-optimised dev) |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

**Outputs**

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_cidr` | CIDR block of the VPC |
| `public_subnet_ids` | IDs of the public subnets |
| `private_subnet_ids` | IDs of the private subnets |
| `nat_gateway_ids` | IDs of the NAT gateways |

---

### `modules/alb`

**Inputs**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Name prefix for all ALB resources |
| `vpc_id` | `string` | — | VPC ID where the ALB is deployed |
| `public_subnet_ids` | `list(string)` | — | Public subnet IDs (min 2) |
| `app_port` | `number` | `8000` | Port the application containers listen on |
| `health_check_path` | `string` | `/health` | ALB health check path |
| `enable_deletion_protection` | `bool` | `false` | Enable deletion protection |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

**Outputs**

| Name | Description |
|------|-------------|
| `alb_arn` | ARN of the Application Load Balancer |
| `alb_dns_name` | DNS name of the ALB |
| `target_group_arn` | ARN of the target group |
| `security_group_id` | ID of the ALB security group |

---

### `modules/ecs`

**Inputs**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Name prefix for all ECS resources |
| `vpc_id` | `string` | — | VPC ID |
| `private_subnet_ids` | `list(string)` | — | Private subnet IDs for ECS tasks |
| `alb_security_group_id` | `string` | — | ALB security group ID |
| `target_group_arn` | `string` | — | ALB target group ARN |
| `container_image` | `string` | — | Docker image to run |
| `container_port` | `number` | `8000` | Port the container listens on |
| `task_cpu` | `number` | `256` | Task CPU units (256 = 0.25 vCPU) |
| `task_memory` | `number` | `512` | Task memory in MB |
| `desired_count` | `number` | `1` | Initial replica count |
| `min_capacity` | `number` | `1` | Minimum replicas (autoscaling) |
| `max_capacity` | `number` | `4` | Maximum replicas (autoscaling) |
| `cpu_target_percent` | `number` | `70` | CPU utilisation target for autoscaling |
| `use_spot` | `bool` | `false` | Use FARGATE_SPOT capacity provider |
| `environment` | `map(string)` | `{}` | Container environment variables |
| `aws_region` | `string` | — | AWS region (for CloudWatch log config) |
| `log_retention_days` | `number` | `7` | CloudWatch log retention in days |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

**Outputs**

| Name | Description |
|------|-------------|
| `cluster_id` | ID of the ECS cluster |
| `cluster_name` | Name of the ECS cluster |
| `service_name` | Name of the ECS service |
| `task_definition_arn` | ARN of the latest task definition |
| `task_security_group_id` | Security group ID attached to ECS tasks |
| `log_group_name` | CloudWatch log group name |

---

## License

[MIT](LICENSE)
