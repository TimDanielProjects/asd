# Logic App Standard Deployment Modules

This folder contains Bicep modules for deploying Azure Logic App Standard with different logging configurations. The main `LogicAppStandard.bicep` file conditionally calls these modules based on the logging requirements.

## Module Files

### LogicAppStandard_NodiniteOnly.bicep
- Deploys Logic App Standard with only Nodinite logging enabled
- Configures diagnostic settings to send logs to Event Hub for Nodinite
- Returns systemAssignedPrincipalId for RBAC assignments

### LogicAppStandard_AppInsightsOnly.bicep
- Deploys Logic App Standard with only Application Insights logging enabled
- Configures Application Insights connection strings and instrumentation key
- Returns systemAssignedPrincipalId for RBAC assignments

### LogicAppStandard_BothLogging.bicep
- Deploys Logic App Standard with both Nodinite and Application Insights logging enabled
- Combines diagnostic settings for Event Hub and Application Insights configuration
- Returns systemAssignedPrincipalId for RBAC assignments

### LogicAppStandard_NoLogging.bicep
- Deploys Logic App Standard with no additional logging configuration
- Basic deployment with system-assigned managed identity
- Returns systemAssignedPrincipalId for RBAC assignments

## Usage

These modules are called conditionally from the main `LogicAppStandard.bicep` file based on the `NodiniteLoggingEnabled` and `ApplicationInsightsLoggingEnabled` parameters.

The main file handles the output logic to ensure the correct `systemAssignedPrincipalId` is returned regardless of which module was deployed.

## Outputs

All modules return the following outputs:
- `logicAppName`: The name of the deployed Logic App
- `logicAppId`: The resource ID of the Logic App
- `systemAssignedPrincipalId`: The principal ID of the system-assigned managed identity
- `logicAppUrl`: The default URL of the Logic App

## Parameters

Common parameters across all modules:
- `location`: Azure region for deployment
- `logicAppName`: Name of the Logic App to create
- `serverFarmResourceId`: Resource ID of the App Service Plan
- `logicAppSettings`: Object containing Logic App configuration settings

**Note**: The `logicAppSettings` object now includes required storage connection strings:
- `AzureWebJobsStorage`: Primary storage connection for Logic App runtime
- `WEBSITE_CONTENTAZUREFILECONNECTIONSTRING`: File share connection for Logic App content
- `WEBSITE_CONTENTSHARE`: File share name (defaults to Logic App name)
- `AzureWebJobsSecretStorageType`: Set to 'Blob' for blob-based secret storage

Module-specific parameters:
- `applicationInsightResourceId`: Required for modules with Application Insights
- `sharedResources`: Required for modules with Nodinite logging

## Required Storage Account

The main `LogicAppStandard.bicep` file now requires a `storageAccount` parameter with:
- `resourceId`: The Azure resource ID of the storage account
- `name`: The name of the storage account

This storage account is used for:
- Logic App runtime files and secrets
- Workflow state and execution data
- Content share for the Logic App
