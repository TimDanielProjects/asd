# Function App Deployment Modules

This folder contains Bicep modules for deploying Azure Function Apps with different logging configurations. The main `FunctionApp.bicep` file conditionally calls these modules based on the logging requirements.

## Module Files

### FunctionApp_NodiniteOnly.bicep
- Deploys Function App with only Nodinite logging enabled
- Configures diagnostic settings to send logs to Event Hub for Nodinite
- Returns systemAssignedPrincipalId for RBAC assignments

### FunctionApp_AppInsightsOnly.bicep
- Deploys Function App with only Application Insights logging enabled
- Configures Application Insights connection strings and instrumentation key
- Returns systemAssignedPrincipalId for RBAC assignments

### FunctionApp_BothLogging.bicep
- Deploys Function App with both Nodinite and Application Insights logging enabled
- Combines diagnostic settings for Event Hub and Application Insights configuration
- Returns systemAssignedPrincipalId for RBAC assignments

### FunctionApp_NoLogging.bicep
- Deploys Function App with no additional logging configuration
- Basic deployment with system-assigned managed identity
- Returns systemAssignedPrincipalId for RBAC assignments

## Usage

These modules are called conditionally from the main `FunctionApp.bicep` file based on the `NodiniteLoggingEnabled` and `ApplicationInsightsLoggingEnabled` parameters.

The main file handles the output logic to ensure the correct `systemAssignedPrincipalId` is returned regardless of which module was deployed.

## Outputs

All modules return the following outputs:
- `functionAppName`: The name of the deployed Function App
- `functionAppId`: The resource ID of the Function App
- `systemAssignedPrincipalId`: The principal ID of the system-assigned managed identity
- `defaultHostname`: The default hostname of the Function App

## Parameters

Common parameters across all modules:
- `location`: Azure region for deployment
- `functionAppName`: Name of the Function App to create
- `serverFarmResourceId`: Resource ID of the App Service Plan
- `functionAppSettings`: Object containing Function App configuration settings

Module-specific parameters:
- `applicationInsightResourceId`: Required for modules with Application Insights
- `sharedResources`: Required for modules with Nodinite logging

## Function App Configuration

The Function App is configured with:
- **.NET 9.0** runtime with isolated worker process
- **CORS enabled** for all origins
- **HTTPS only** with TLS 1.2 minimum
- **Always On** enabled
- **Storage connection** for Azure WebJobs and content
- **Nodinite logging settings** (connection string and container name)

## Required Parameters for Main Module

When calling the main `FunctionApp.bicep`, you need:
- `NodiniteLoggingEnabled`: 'true' or 'false'
- `ApplicationInsightsLoggingEnabled`: 'true' or 'false'
- `organisationSuffix`: Organization identifier for resource naming
- `environmentSuffix`: Environment identifier for resource naming
- `sharedResources`: Object containing shared resource information
- `appServicePlan`: Object with resourceId
- `storageAccount`: Object with resourceId and name
- `functionAppParameters`: Object with functionAppName
