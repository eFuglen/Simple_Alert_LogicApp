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
    apiConnection.bicep               Deploys ARM API connection used by the Logic App
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
- For metric alerts: a target Azure resource to monitor

## Configure

Copy and edit the parameter file for your environment:

```bash
cp infra/parameters/main.dev.bicepparam infra/parameters/main.<env>.bicepparam
```

The **default values** in `main.bicep` apply to all deployments. The **parameter files** (`.bicepparam`) override these defaults for specific environments. For example, `main.dev.bicepparam` sets `namePrefix = 'Dev-'` to prefix all resources with `Dev-`.

### Parameter file example

```bicep
using '../main.bicep'

param location = 'denmarkeast'
param namePrefix = 'Dev-'
param logicAppName = 'Alert_Router'
param actionGroupName = 'Trigger Alert Router Logic App'
param actionGroupShortName = 'RouteAlert'
param actionGroupLogicAppReceiverName = 'Trigger alert router'
param deployMetricAlert = true
param metricNamespace = 'Microsoft.Compute/virtualMachines'
param metricName = 'Percentage CPU'
```

## Parameters reference

| Parameter | Default | Description |
|---|---|---|
| `namePrefix` | `''` | Prefix applied to all resource names |
| `location` | `resourceGroup().location` | Azure region |
| `logicAppName` | *(required)* | Logic App resource name |
| `actionGroupName` | *(required)* | Action Group resource name |
| `actionGroupShortName` | *(required)* | Action Group short name (max 12 chars) |
| `actionGroupLogicAppReceiverName` | *(required)* | Display name for Logic App receiver in Action Group |
| `armConnectionName` | `'arm'` | Name of the ARM API connection resource |
| `deployMetricAlert` | `true` | Set to `false` to skip metric alert deployment |
| `metricNamespace` | `''` | Metric namespace (e.g., `Microsoft.Compute/virtualMachines`) |
| `metricName` | `''` | Metric name (e.g., `Percentage CPU`) |
| `metricThreshold` | `80` | Threshold value for metric alert |
| `metricEvaluationFrequency` | `'PT1M'` | How often to evaluate the alert |
| `metricWindowSize` | `'PT5M'` | Time window for metric aggregation |
| `grantLogicAppSubscriptionReader` | `true` | Grant Logic App MSI subscription Reader role |
| `subscriptionId` | `subscription().subscriptionId` | Override only when assigning RBAC to a different subscription |

> **Note:** To deploy a metric alert, set `deployMetricAlert = true` and provide both `metricNamespace` and `metricName` in your parameter file.

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
