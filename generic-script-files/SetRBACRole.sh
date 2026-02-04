#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to print status messages
print_status() {
    echo -e "${BOLD}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Validate input parameters
sharedResourceGroupName=$1
sharedStorageAccountName=$2
clientId=$3
subscriptionId=$4
tenantId=$5
clientSecret=$6

if [ -z "$sharedResourceGroupName" ] || [ -z "$sharedStorageAccountName" ] || [ -z "$clientId" ] || [ -z "$subscriptionId" ] || [ -z "$tenantId" ] || [ -z "$clientSecret" ]; then
    print_error "Missing required parameters!"
    echo "Usage: $0 <resource-group> <storage-account> <client-id> <subscription-id> <tenant-id> <client-secret>"
    exit 1
fi

# Login using service principal
print_status "Logging in with service principal..."
if ! az login --service-principal -u "$clientId" -p "$clientSecret" --tenant "$tenantId" --only-show-errors; then
    print_error "Failed to login with service principal"
    exit 1
fi

# Set subscription
print_status "Setting subscription..."
if ! az account set --subscription "$subscriptionId" --only-show-errors; then
    print_error "Failed to set subscription"
    exit 1
fi

# Construct the storage account scope
storageAccountScope=/subscriptions/$subscriptionId/resourceGroups/$sharedResourceGroupName/providers/Microsoft.Storage/storageAccounts/$sharedStorageAccountName
print_status "Storage account scope: $storageAccountScope"

# Check if the service principal has the necessary permissions
print_status "Checking permissions..."
# First check at subscription level
sub_permissions=$(az role assignment list --assignee "$clientId" --scope "/subscriptions/$subscriptionId" --query "[].roleDefinitionName" -o json)
# Then check at resource group level
rg_permissions=$(az role assignment list --assignee "$clientId" --scope "/subscriptions/$subscriptionId/resourceGroups/$sharedResourceGroupName" --query "[].roleDefinitionName" -o json)

print_status "Permissions at subscription level: $sub_permissions"
print_status "Permissions at resource group level: $rg_permissions"

has_permission=false
if echo "$sub_permissions$rg_permissions" | grep -qi "User Access Administrator\|Owner"; then
    has_permission=true
fi

if [ "$has_permission" = false ]; then
    print_error "The service principal does not have sufficient permissions."
    print_error "Required permissions:"
    echo "  - User Access Administrator role"
    echo "  - OR Owner role"
    echo ""
    print_status "Current roles at subscription level:"
    echo "$sub_permissions"
    print_status "Current roles at resource group level:"
    echo "$rg_permissions"
    print_error "Please assign one of the required roles at subscription or resource group level"
    exit 1
fi

# Verify storage account exists
print_status "Verifying storage account exists..."
if ! az storage account show --name "$sharedStorageAccountName" --resource-group "$sharedResourceGroupName" --only-show-errors &>/dev/null; then
    print_error "Storage account '$sharedStorageAccountName' not found in resource group '$sharedResourceGroupName'"
    exit 1
fi

# Attempt to create the role assignment
print_status "Creating role assignment..."
if az role assignment create \
    --assignee "$clientId" \
    --role "Storage Blob Data Contributor" \
    --scope "$storageAccountScope" \
    --only-show-errors; then
    
    print_success "Successfully assigned 'Storage Blob Data Contributor' role to service principal '$clientId'"
else
    print_error "Failed to create role assignment"
    print_status "Verifying service principal exists..."
    if ! az ad sp show --id "$clientId" --only-show-errors &>/dev/null; then
        print_error "Service principal with client ID '$clientId' not found"
    else
        print_error "Service principal exists but lacks necessary permissions to assign roles"
        print_error "Please ensure the service principal has one of these roles:"
        echo "  - User Access Administrator at subscription level (/subscriptions/$subscriptionId)"
        echo "  - OR Owner at subscription level (/subscriptions/$subscriptionId)"
        echo "  - OR User Access Administrator at resource group level (/subscriptions/$subscriptionId/resourceGroups/$sharedResourceGroupName)"
        echo "  - OR Owner at resource group level (/subscriptions/$subscriptionId/resourceGroups/$sharedResourceGroupName)"
    fi
    exit 1
fi

