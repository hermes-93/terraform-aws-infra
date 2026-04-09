# Contributing

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | ≥ 1.7 | [tfenv](https://github.com/tfutils/tfenv) |
| tflint | ≥ 0.55 | `brew install tflint` |
| Checkov | ≥ 3.0 | `pip install checkov` |
| tfsec | ≥ 1.28 | `brew install tfsec` |
| AWS CLI | ≥ 2.0 | [docs](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |

## Local validation

Run the same checks that CI runs before opening a PR:

```bash
# 1. Format check
terraform fmt -check -recursive

# 2. Validate each env
for env in dev prod; do
  echo "=== $env ==="
  cd envs/$env
  terraform init -backend=false
  terraform validate
  cd ../..
done

# 3. tflint (built-in rules)
tflint --init
for dir in modules/vpc modules/alb modules/ecs envs/dev envs/prod; do
  echo "=== $dir ==="
  tflint --chdir "$dir"
done

# 4. Checkov security scan
checkov -d . --framework terraform
```

## Module development

Each module lives under `modules/<name>/` and follows this structure:

```
modules/<name>/
├── main.tf       # Resources
├── variables.tf  # Input variables (all with description + type)
├── outputs.tf    # Output values (all with description)
└── versions.tf   # required_providers declaration
```

Rules:
- All variables must have `description` and `type`
- All outputs must have `description`
- Resources must include `tags = var.tags` or `tags = merge(var.tags, {...})`
- No hardcoded region, account ID, or credentials
- Security groups: always include `description` on rules

## Environment structure

Environments live under `envs/<name>/`:

```
envs/<name>/
├── versions.tf   # terraform + provider config + backend
├── main.tf       # Module calls
├── variables.tf  # Input variables with defaults
└── outputs.tf    # Useful outputs (ALB DNS, cluster name, etc.)
```

## Adding a new environment

1. Copy `envs/dev/` to `envs/<name>/`
2. Update `versions.tf`: adjust backend key, AWS region
3. Tune resource sizes in `main.tf`
4. Add the new env to CI matrix in `.github/workflows/ci.yml`:

```yaml
matrix:
  env: [dev, prod, <name>]
```

## Pull request guidelines

- One logical change per PR
- CI must be green before merge
- Include `## What` and `## Why` sections in the PR description
- Commit messages: English, imperative mood (`add`, `fix`, `update`)

## Checkov skip policy

Checks skipped in CI are documented in `.github/workflows/ci.yml`.  
New skips require a comment explaining why (e.g. `# no HTTPS cert in demo`).

Do not add broad skips like `CKV_AWS_*` — skip only specific checks.
