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
resourceGroupName=$1
storageAccountName=$2
resourceLocation=$3

if [ -z "$resourceGroupName" ] || [ -z "$storageAccountName" ] || [ -z "$resourceLocation" ]; then
    print_error "Missing required parameters!"
    echo "Usage: $0 <resource-group> <storage-account-name> <location>"
    exit 1
fi

# Verify Azure CLI is logged in and get subscription
print_status "Verifying Azure authentication..."
subscription=$(az account show --query id -o tsv 2>/dev/null)
if [ $? -ne 0 ]; then
    print_error "Not logged into Azure. Please run 'az login' first."
    exit 1
fi
print_success "Using subscription: $(az account show --query name -o tsv)"



# Verify permissions
print_status "Verifying permissions..."
if ! az role assignment list --query "[?roleDefinitionName=='Storage Account Contributor' || roleDefinitionName=='Contributor']" -o tsv > /dev/null; then
    print_warning "Current identity might not have sufficient permissions (Storage Account Contributor or Contributor role required)"
fi

# Create or verify storage account
print_status "Checking storage account $storageAccountName..."
if az storage account show --name $storageAccountName --resource-group $resourceGroupName --only-show-errors &>/dev/null; then
    print_success "Storage account already exists"
else
    print_status "Creating storage account..."
    if ! az storage account create \
        --name $storageAccountName \
        --resource-group $resourceGroupName \
        --location $resourceLocation \
        --sku Standard_LRS \
        --kind StorageV2 \
        --enable-hierarchical-namespace true \
        --enable-large-file-share \
        --min-tls-version TLS1_2 \
        --only-show-errors; then
        
        print_error "Failed to create storage account"
        print_status "Performing diagnostics..."
        
        # Quick diagnostic checks
        az account show --query "state" --output tsv || print_error "Cannot access subscription"
        az group show --name $resourceGroupName --output tsv &>/dev/null || print_error "Cannot access resource group"
        
        exit 1
    fi
    print_success "Storage account created successfully"
fi

# Configure storage account
print_status "Configuring storage account settings..."
if ! az storage account update \
    --name $storageAccountName \
    --resource-group $resourceGroupName \
    --set defaultToOAuthAuthentication=true \
    --only-show-errors; then
    print_error "Failed to update storage account settings"
    exit 1
fi

print_success "Storage account configuration complete"
print_success "Storage account '$storageAccountName' is ready to use"
exit 0


