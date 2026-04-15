# Known Issues

## Bicep Schema Warnings

The following Bicep schema warnings are **expected and safe to ignore**. These warnings occur because the Bicep type definitions for `Microsoft.Web/connections` have not been updated to reflect properties required for managed identity authentication.

### BCP187: Property "kind" does not exist in the resource or type definition

**Location:** `infra/modules/apiConnection.bicep:26`

**Warning Message:**
```
The property "kind" does not exist in the resource or type definition, although it might still be valid. 
If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues.
```

**Cause:** The `kind` property is required to specify a V1 API connection but is not included in the Bicep schema definition.

**Status:** ✅ **Safe to ignore** — the property is valid at deployment time and required for managed identity authentication.

**Reference:** [Microsoft Docs: Authenticate with managed identity](https://learn.microsoft.com/en-us/azure/logic-apps/authenticate-with-managed-identity?tabs=consumption#single-authentication)

---

### BCP037: Property "parameterValueType" is not allowed on objects of type "ApiConnectionDefinitionProperties"

**Location:** `infra/modules/apiConnection.bicep:33`

**Warning Message:**
```
The property "parameterValueType" is not allowed on objects of type "ApiConnectionDefinitionProperties". 
Permissible properties include "changedTime", "createdTime", "customParameterValues", "nonSecretParameterValues", 
"parameterValues", "statuses", "testLinks". If this is a resource type definition inaccuracy, report it using 
https://aka.ms/bicep-type-issues.
```

**Cause:** The `parameterValueType` property is required to enable managed service identity authentication but is not included in the Bicep schema definition.

**Status:** ✅ **Safe to ignore** — the property is valid at deployment time and required for MSI authentication to work.

**Reference:** [Microsoft Docs: Authenticate with managed identity](https://learn.microsoft.com/en-us/azure/logic-apps/authenticate-with-managed-identity?tabs=consumption#single-authentication)

---

## Deployment Validation

Despite these schema warnings, the Bicep template passes all Azure validation:

- ✅ **Compiles** successfully with `az bicep build`
- ✅ **Validates** successfully with `az deployment group validate`
- ✅ **Deploys** successfully with `az deployment group create`
- ✅ **Runtime** — Logic App correctly authenticates with the ARM API connection using managed identity

---

## How to Report Schema Updates

To monitor when the Bicep schema is updated:

1. Check [Azure Bicep GitHub Issues](https://github.com/Azure/bicep/issues)
   - Search for keywords: `apiConnection`, `kind`, `parameterValueType`, `Microsoft.Web/connections`

2. Reference the [Microsoft.Web/connections API Reference](https://learn.microsoft.com/en-us/azure/templates/microsoft.web/connections?tabs=bicep)

3. If you encounter issues with these properties, report to:
   - https://aka.ms/bicep-type-issues (Bicep schema issues)
   - https://github.com/Azure/bicep/issues (GitHub issues)

---

## Suppressing Warnings (Future Enhancement)

Once Bicep's type definitions are updated or if a warning suppression mechanism is added, these comments can be removed. Bicep does not currently support inline warning suppression like `@suppress` decorators found in other IaC tools.

