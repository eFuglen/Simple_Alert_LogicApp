# Simple Alert Logic App IaC (Bicep)

Public Infrastructure as Code repository for deploying an Azure Monitor alerting flow:

- Azure Logic App (Consumption)
- Azure Monitor Action Group that invokes the Logic App
- Azure Monitor Metric Alert that triggers the Action Group

This repository is now baselined from your existing resources:

- Tenant: 3krcloud (MngEnvMCAP634312.onmicrosoft.com)
- Subscription: 3krCloud Admin (`fc17f768-1dca-47c0-8f35-4e1d7ba501e3`)
- Resource group: `DevMachine`
- Logic App: `AlertMachine`
- Action Group: `TriggerLogicApp`

## Architecture

1. A metric alert watches a target Azure resource and metric.
2. When threshold conditions are met, the alert fires the action group.
3. The action group calls the Logic App request trigger endpoint.
4. The Logic App workflow runs your alert handling logic.

Note: no existing alert rule was found in `DevMachine` during baseline capture, so metric alert deployment is optional and disabled by default in the parameter file (`deployMetricAlert: false`).

## Repository layout

- infra/main.bicep: Entry point that orchestrates all modules.
- infra/modules/logicAppConsumption.bicep: Logic App deployment and callback URL output.
- infra/modules/actionGroup.bicep: Action Group with Logic App receiver.
- infra/modules/metricAlert.bicep: Metric Alert bound to target scope and Action Group.
- infra/parameters/main.dev.json: Single-environment parameter file.
- logic-app-config/workflow.definition.json: Parameterized Logic App workflow definition.
- .github/workflows/deploy-bicep.yml: GitHub Actions OIDC deployment workflow.

## Prerequisites

- Azure CLI installed and logged in
- Bicep CLI available through Azure CLI (`az bicep`)
- Existing resource group for deployment
- Existing target resource to monitor (for metric alert scope)
- GitHub repository variables for OIDC deployment:
  - AZURE_CLIENT_ID
  - AZURE_TENANT_ID
  - AZURE_SUBSCRIPTION_ID
  - AZURE_RESOURCE_GROUP

## Configure

1. Review infra/parameters/main.dev.json (already pre-populated with your current Logic App and Action Group baseline).
2. Confirm API connection resources exist (`arm` and `outlook`) in `DevMachine`.
3. If you want IaC to also create a metric alert rule, set `deployMetricAlert` to `true` and fill `metricTargetResourceId`, `metricNamespace`, and `metricName`.

## Validate locally

```bash
az bicep build --file infra/main.bicep
az deployment group validate \
  --resource-group <resource-group-name> \
  --template-file infra/main.bicep \
  --parameters @infra/parameters/main.dev.json
```

## Deploy locally

```bash
az deployment group create \
  --name simple-alert-logicapp \
  --resource-group <resource-group-name> \
  --template-file infra/main.bicep \
  --parameters @infra/parameters/main.dev.json
```

## Deploy with GitHub Actions (OIDC)

1. Create a Microsoft Entra app registration for GitHub OIDC.
2. Add a federated credential for your repository and branch/environment.
3. Grant least-privilege role on the deployment resource group.
4. Add required repository variables listed above.
5. Run the workflow: Actions -> Deploy Bicep -> Run workflow.

## Public repository safety

- Do not commit secrets, access keys, or callback URLs with tokens.
- Keep environment-specific IDs in parameter files that you control.
- Review pull requests for accidental sensitive data.

## Create and publish public repository

```bash
git init
git add .
git commit -m "Initial Bicep IaC for Logic App alert flow"
```

If GitHub CLI is installed:

```bash
gh repo create Simple_Alert_LogicApp --public --source . --remote origin --push
```

Otherwise, create an empty public repository in GitHub web UI, then add remote and push.
