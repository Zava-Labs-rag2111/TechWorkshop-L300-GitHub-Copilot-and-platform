# GitHub Actions quickstart for Azure Web App container deploy

1) Create three **repository secrets** (Settings > Secrets and variables > Actions > New repository secret):
   - `AZURE_CLIENT_ID` – app registration client ID used for workload identity/OIDC.
   - `AZURE_TENANT_ID` – tenant ID for the app registration.
   - `AZURE_SUBSCRIPTION_ID` – subscription that contains the resource group and App Service.

   Use a federated credential on the app registration for this repo and branch (push and workflow_dispatch), then grant the app registration access: `AcrPush` on the Azure Container Registry and `Contributor` (or `Website Contributor` + `Managed Identity Operator`) on the resource group that holds the App Service.

2) Create three **repository variables** (Settings > Secrets and variables > Actions > New variable):
   - `AZURE_CONTAINER_REGISTRY_NAME` – ACR name (for example, `cr<token>` from infra outputs).
   - `AZURE_CONTAINER_REGISTRY_LOGIN_SERVER` – ACR login server (for example, `cr<token>.azurecr.io`).
   - `AZURE_WEBAPP_NAME` – App Service name (for example, `app-<token>` from infra outputs).

   The workflow defaults the image name to `zavastorefront`. To change it, edit the `IMAGE_NAME` value in `.github/workflows/azure-webapp-container.yml`.

3) Trigger the workflow: push to `main` or run it manually via the **Actions** tab. The workflow builds the container from `./src` with `./Dockerfile`, pushes it to ACR, and updates the App Service to pull that tag using its managed identity.
