# Deployment Workflow Setup

The workflow authenticates to Azure using **OIDC (Workload Identity Federation)** — no long-lived credentials are stored as secrets.

## 1. Create a Service Principal with Federated Credentials

```powershell
# ── Variables ────────────────────────────────────────────────────────────────
# Azure portal → Subscriptions, or: az account show --query id -o tsv
$subscriptionId   = "e783ed43-f070-476f-85dc-13e2393afbf8"

# Azure portal → Subscriptions → your sub → Overview → Tenant ID, or: az account show --query tenantId -o tsv

$tenantId         = "60b20c52-6462-4ab8-b261-32d173b5e51c"

# Azure portal → Resource Groups, or: az group list --query "[].name" -o tsv
$resourceGroup    = "rg-l300ghcopilot"

# Azure portal → Container Registries → your ACR → Overview → Login server
$acrName          = "cr4fsk7c4ej7jfm"
$acrLoginServer   = "$acrName.azurecr.io"

# Azure portal → App Services → your app → Overview → Name
$webAppName       = "app-4fsk7c4ej7jfm"

# GitHub → your org/account and repo name (org/repo format)
$githubRepo       = "Tom-Org-2026/TechWorkshop-L300-GitHub-Copilot-and-platform"
# ─────────────────────────────────────────────────────────────────────────────

# Create the service principal and capture its clientId
$sp = az ad sp create-for-rbac --name "github-zavastorefront" --role Contributor `
  --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroup `
  --json-auth | ConvertFrom-Json
$appId = $sp.clientId

# Add a federated credential for the repository
$federatedCredential = @{
    name      = "github-actions"
    issuer    = "https://token.actions.githubusercontent.com"
    subject   = "repo:$($githubRepo):ref:refs/heads/main"
    audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json

az ad app federated-credential create --id $appId --parameters $federatedCredential

# Grant AcrPush role on the ACR
az role assignment create `
  --assignee $appId `
  --role AcrPush `
  --scope /subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ContainerRegistry/registries/$acrName

# Print values to configure as GitHub Secrets / Variables
Write-Host "`n── GitHub Secrets ───────────────────────────────"
Write-Host "AZURE_CLIENT_ID:       $appId"
Write-Host "AZURE_TENANT_ID:       $tenantId"
Write-Host "AZURE_SUBSCRIPTION_ID: $subscriptionId"
Write-Host "`n── GitHub Variables ─────────────────────────────"
Write-Host "ACR_LOGIN_SERVER:      $acrLoginServer"
Write-Host "AZURE_WEBAPP_NAME:     $webAppName"
Write-Host "AZURE_RESOURCE_GROUP:  $resourceGroup"
```

## 2. GitHub Secrets

Set these under **Settings → Secrets and variables → Actions → Secrets**.
The script prints all values at the end — copy them from the terminal output.

| Secret | Source |
|---|---|
| `AZURE_CLIENT_ID` | Script output / `$sp.clientId` |
| `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | `az account show --query id -o tsv` |

## 3. GitHub Variables

Set these under **Settings → Secrets and variables → Actions → Variables**.
The script prints all values at the end — copy them from the terminal output.

| Variable | Source |
|---|---|
| `ACR_LOGIN_SERVER` | Azure portal → Container Registries → Overview → Login server |
| `AZURE_WEBAPP_NAME` | Azure portal → App Services → Overview → Name |
| `AZURE_RESOURCE_GROUP` | Azure portal → Resource Groups |
