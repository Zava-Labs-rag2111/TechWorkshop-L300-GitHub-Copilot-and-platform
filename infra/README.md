# ZavaStorefront Azure Infrastructure

This directory contains the Azure infrastructure as code (IaC) for the ZavaStorefront application using Bicep templates and Azure Developer CLI (azd).

## Structure

```
infra/
├── main.bicep                    # Main orchestration template
├── main.parameters.json          # Parameter file
└── modules/
    ├── appService.bicep          # App Service (Web App)
    ├── appServicePlan.bicep      # App Service Plan
    ├── applicationInsights.bicep # Application Insights
    ├── containerRegistry.bicep   # Azure Container Registry
    ├── storage.bicep             # Storage Account
    ├── keyVault.bicep            # Key Vault
    ├── logAnalytics.bicep        # Log Analytics Workspace
    ├── aiFoundry.bicep           # Microsoft Foundry (AI Hub & Project)
    └── roleAssignments.bicep     # RBAC role assignments
```

## Resources Deployed

### Core Infrastructure
- **Resource Group**: Contains all resources
- **App Service Plan**: Linux hosting plan (F1/Free tier for dev)
- **App Service**: Web App for Containers with system-assigned managed identity
- **Azure Container Registry**: Stores Docker images (Basic SKU)
- **Application Insights**: Application monitoring and telemetry
- **Log Analytics Workspace**: Backend for Application Insights

### AI & Storage
- **Microsoft Foundry**: AI Hub and Project for GPT-4 and Phi models
- **Key Vault**: Secure storage for secrets and configuration
- **Storage Account**: Required for AI Foundry

### Security & RBAC
- **App Service → ACR**: AcrPull role for pulling container images
- **App Service → Key Vault**: Key Vault Secrets User role
- **Managed Identity**: System-assigned identity for all service-to-service auth

## Prerequisites

- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install)
- Azure subscription with appropriate permissions

## Deployment

### Initialize azd environment

```bash
azd init
```

Follow the prompts to configure your environment name and Azure location (recommended: westus3 for AI models).

### Provision infrastructure

```bash
azd provision
```

This will:
1. Create the resource group
2. Deploy all Azure resources
3. Configure RBAC role assignments
4. Output connection strings and endpoints

### Deploy the application

```bash
azd deploy
```

This will:
1. Build the Docker container
2. Push to Azure Container Registry
3. Update App Service to use the new container image

### Full workflow (provision + deploy)

```bash
azd up
```

## Configuration

### Environment Variables

Key environment variables are configured in `.azure/<env-name>/.env`:

- `AZURE_ENV_NAME`: Name of the environment (dev, staging, prod)
- `AZURE_LOCATION`: Azure region (default: westus3)
- `AZURE_PRINCIPAL_ID`: Your Azure AD user/service principal ID

### Parameters

Modify `main.parameters.json` to customize:
- Region/location
- Environment name
- Resource naming

### SKU Configuration

Update SKUs in the respective module files:
- App Service Plan: `appServicePlan.bicep` (default: F1)
- Container Registry: `containerRegistry.bicep` (default: Basic)
- Storage Account: `storage.bicep` (default: Standard_LRS)

## Security Features

### No Secrets in Code
- All service-to-service authentication uses managed identities
- ACR admin user is disabled
- App Service pulls images using RBAC (AcrPull role)

### Encrypted Communication
- HTTPS enforced on App Service
- TLS 1.2 minimum for all resources
- FTP disabled on App Service

### Network Security
- Public network access controlled
- Azure Service bypass enabled for internal services
- Soft delete enabled on Key Vault

## Monitoring

### Application Insights
Access via Azure Portal or use connection string from outputs:
```bash
azd env get-values | grep APPLICATIONINSIGHTS_CONNECTION_STRING
```

### Log Analytics
Query logs using Kusto Query Language (KQL) in Azure Portal.

## Outputs

After deployment, the following values are available:

```bash
azd env get-values
```

Key outputs:
- `SERVICE_WEB_URI`: Public URL of the web application
- `AZURE_CONTAINER_REGISTRY_ENDPOINT`: ACR login server
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: App Insights connection
- `AZURE_KEY_VAULT_ENDPOINT`: Key Vault URI

## Clean Up

To delete all resources:

```bash
azd down
```

Add `--purge` to also purge soft-deleted resources:

```bash
azd down --purge
```

## Troubleshooting

### Deployment Failures

Check deployment logs:
```bash
az deployment group list --resource-group <rg-name>
```

### Container Registry Access Issues

Verify managed identity has AcrPull role:
```bash
az role assignment list --assignee <app-service-identity-id> --scope <acr-id>
```

### AI Foundry Quota

Ensure your subscription has quota for Microsoft Foundry in the selected region:
```bash
az provider show --namespace Microsoft.MachineLearningServices
```

## Cost Management

Expected monthly costs for dev environment:
- App Service Plan (F1): Free
- Container Registry (Basic): ~$5
- Application Insights: ~$2-5
- Log Analytics: ~$2-3
- Storage Account: ~$1-2
- **Total**: ~$10-15/month (excluding AI usage)

AI Foundry costs are pay-per-use based on model consumption.

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service on Linux](https://learn.microsoft.com/azure/app-service/overview-linux)
- [Microsoft Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
