# Simple Alert Logic App IaC (Bicep)

Modular Bicep Infrastructure as Code for deploying an Azure Monitor alerting flow using a Consumption Logic App.

## What this deploys

- **Azure Logic App (Consumption)** – receives an HTTP trigger from the Action Group and runs alert-handling workflow logic
- **Azure Monitor Action Group** – calls the Logic App trigger endpoint when an alert fires
- **Azure Monitor Metric Alert** *(optional)* – watches a target resource/metric and fires the Action Group when thresholds are met
- **Subscription-scope Reader role assignment** *(optional)* – grants the Logic App's managed identity read access so it can inspect resources

## Architecture

```
Metric Alert  →  Action Group  →  Logic App (HTTP trigger)  →  Workflow logic
```

All connection IDs and resource paths are computed at deploy time from the deployment context — no hardcoded subscription IDs or resource group names in the parameter files.

## Repository layout

```
infra/
  main.bicep                          Entry point — orchestrates all modules
  modules/
    logicAppConsumption.bicep         Logic App + SystemAssigned MSI + callback URL output
    actionGroup.bicep                 Action Group with Logic App receiver
    metricAlert.bicep                 Optional metric alert rule
    subscriptionReaderRoleAssignment.bicep  Optional subscription Reader for Logic App MSI
  parameters/
    main.dev.bicepparam               Dev environment parameter values
logic-app-config/
  workflow.definition.json            Logic App workflow definition (loaded via loadJsonContent)
.github/
  workflows/
    deploy-bicep.yml                  GitHub Actions OIDC deployment workflow
```

## Prerequisites

- Azure CLI with Bicep: `az bicep install`
- A resource group to deploy into
- An existing `arm` API connection resource in the same resource group (used by the Logic App to call Azure Resource Manager)
- For metric alerts: a target Azure resource to monitor

## Configure

Copy and edit the parameter file for your environment:

```bash
cp infra/parameters/main.dev.bicepparam infra/parameters/main.<env>.bicepparam
```

Key parameters:

| Parameter | Default | Description |
|---|---|---|
| `namePrefix` | `'Dev-'` | Prefix applied to all resource names |
| `location` | `'denmarkeast'` | Azure region |
| `logicAppName` | `'Alert_Router'` | Logic App resource name suffix |
| `armConnectionName` | `'arm'` | Name of the existing ARM API connection resource |
| `deployMetricAlert` | `false` | Set to `true` to also deploy a metric alert rule |
| `grantLogicAppSubscriptionReader` | `true` | Grant the Logic App MSI subscription Reader |
| `subscriptionId` | *(deployment subscription)* | Override only when assigning RBAC to a different subscription |

## Validate locally

```bash
az bicep build --file infra/main.bicep

az deployment group validate \
  --resource-group <your-resource-group> \
  --template-file infra/main.bicep \
  --parameters infra/parameters/main.dev.bicepparam
```

## Deploy locally

```bash
az deployment group create \
  --name simple-alert-logicapp \
  --resource-group <your-resource-group> \
  --template-file infra/main.bicep \
  --parameters infra/parameters/main.dev.bicepparam
```

## Deploy with GitHub Actions (OIDC)

1. Create a Microsoft Entra app registration and configure a federated credential for your repository and branch.
2. Grant the app registration at minimum **Contributor** on the deployment resource group (and **Owner** if using the Reader role assignment module).
3. Add the following repository **variables** (not secrets):
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_RESOURCE_GROUP`
4. Run the workflow: **Actions → Deploy Bicep → Run workflow**.

## Security notes

- The Logic App trigger callback URL is marked `@secure()` and is never written to state or logs.
- No subscription IDs, tenant IDs, or resource IDs are hardcoded in the templates or parameter files — all paths are computed at deploy time.
- Do not commit access keys, SAS tokens, or any credential material.
