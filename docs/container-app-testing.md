# Container App Split Testing with APIM

This setup enables testing new features by deploying test revisions to the same container app environment while using Azure API Management (APIM) to route traffic based on subdomain.

## How It Works

### Environments and Routing

- **Production**: `api.prod.domain` → Production container app
- **Staging**: `api.staging.domain` → Staging container app  
- **Development**: `api.dev.domain` → Development container app (stable revision)
- **Test**: `api.test.domain` → Development container app (test revision)

### Container App Strategy

Instead of creating separate container apps for testing, this approach:
1. Creates a new revision within the existing dev container app
2. Uses revision suffix `test` to distinguish test revisions
3. Maintains the same underlying infrastructure
4. Uses APIM to route traffic based on the Host header (configured in Terraform)

## Deployment

### Repository Structure

Each container app has its own repository with deployment workflows:
- `deploy-development.yaml` - Deploys to dev environment (triggers on push to main)
- `deploy-staging.yaml` - Deploys to staging environment
- `deploy-test.yaml` - Deploys test revisions (manual trigger)

### Deploy to Test Environment

```bash
# Deploy latest version as test revision
gh workflow run deploy-test.yaml

# Deploy specific version for testing
gh workflow run deploy-test.yaml -f tag=v1.2.3-beta

# Deploy older version for comparison
gh workflow run deploy-test.yaml -f tag=v1.1.0
```

This will:
1. Build a new container image (or use specified tag)
2. Create a new revision in the dev container app with suffix `test`
3. Create an APIM backend named `{app-name}-test`
4. Your Terraform APIM policies route `api.test.domain` to the test backend

### Deploy to Development

Development deployments happen automatically on push to main branch and update the stable dev revision normally.

## API Management Configuration

The APIM setup is managed by your Terraform configuration and includes:
- **Backend Services**: Regular backends for each environment + test-specific backends (with `-test` suffix)
- **Host-based Routing**: Terraform-managed policies that examine the Host header to determine routing
- **Automatic Fallback**: If test backend is unavailable, requests fall back to stable backend

The Bicep templates only create the APIM backends - all routing policies are handled by Terraform.

## Infrastructure

### Bicep Templates

1. **container-app.bicep**: Standard container app deployment (dev, staging, prod)
2. **container-app-revision.bicep**: Creates new revisions in existing container apps (test only)
3. **api-backend.bicep**: APIM backend configuration (handles both regular and test backends)

### Template Specs Required

You'll need to create these template specs in Azure:
- `ts-container-app`: For standard container app deployments
- `ts-container-app-revision`: For test revision deployments
- `ts-api-backend`: For APIM backend configuration

## Example deploy-test.yaml

For each container app repository, create a `deploy-test.yaml`:

```yaml
name: Deploy Test

on:
  workflow_dispatch:
    inputs:
      tag:
        type: string
        description: |
          GitHub tag to deploy. If empty, uses latest release.

permissions:
  contents: write
  packages: write
  id-token: write

jobs:
  build:
    uses: ticctech/github-tools/.github/workflows/build-go.yaml@main
    secrets: inherit

  test:
    needs: build
    uses: ticctech/github-tools/.github/workflows/deploy-go.yaml@main
    secrets: inherit
    with:
      environment: test
      tag: ${{ needs.build.outputs.tag }}
```

## Benefits

1. **Cost Efficient**: No additional container app infrastructure for testing
2. **Isolated Testing**: Test revisions are completely separate from production traffic
3. **Quick Rollback**: Simply redeploy development to remove test revisions
4. **Subdomain Routing**: Clean separation of test vs production URLs
5. **Zero Downtime**: Both stable and test revisions run simultaneously

## Usage Examples

### Testing a New Feature

1. **Manual test deployment**: Run the "Deploy Test" workflow in your container app repository
2. **Access via test subdomain**: Use `api.test.domain` to access the test revision
3. **Validate functionality**: Test the new features in isolation
4. **Promote to dev**: Push to main branch to deploy to stable dev environment

### Testing Specific Versions

```bash
# Test a specific release version
gh workflow run deploy-test.yaml -f tag=v1.2.3

# Test a beta version
gh workflow run deploy-test.yaml -f tag=v1.2.4-beta

# Test an older version for comparison
gh workflow run deploy-test.yaml -f tag=v1.1.0
```

### Rolling Back

If issues are found:
1. Deploy a previous stable version to the test environment
2. Or simply redeploy the current development version
3. The test revision gets replaced with the new deployment

## Monitoring

Use Azure Monitor to track:
- Request distribution between revisions
- Error rates per revision
- Performance metrics per subdomain
- APIM analytics for routing effectiveness
