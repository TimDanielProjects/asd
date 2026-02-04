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
keyVaultName=$2
CLIResourceLocation=$3

if [ -z "$sharedResourceGroupName" ] || [ -z "$keyVaultName" ] || [ -z "$CLIResourceLocation" ]; then
    print_error "Missing required parameters!"
    echo "Usage: $0 <resource-group> <key-vault-name> <location>"
    exit 1
fi

# Function to check if Key Vault exists
check_keyvault() {
    az keyvault show --name "$keyVaultName" --resource-group "$sharedResourceGroupName" --query "name" -o tsv 2>/dev/null
}

# Function to create Key Vault with required policy settings
create_keyvault() {
    print_status "Creating Key Vault '$keyVaultName' in resource group '$sharedResourceGroupName'..."
    if az keyvault create \
        --name "$keyVaultName" \
        --resource-group "$sharedResourceGroupName" \
        --location "$CLIResourceLocation" \
        --enabled-for-template-deployment true \
        --enable-purge-protection true \
        --retention-days 90 \
        --sku standard \
        --only-show-errors; then
        print_success "Key Vault created successfully"
        return 0
    else
        local error_message=$(az keyvault create \
            --name "$keyVaultName" \
            --resource-group "$sharedResourceGroupName" \
            --location "$CLIResourceLocation" \
            --enabled-for-template-deployment true \
            --enable-purge-protection true \
            --retention-days 90 \
            --sku standard \
            2>&1)
        print_error "Failed to create Key Vault:"
        echo "$error_message"
        return 1
    fi
}

# Main logic
print_status "Checking if Key Vault '$keyVaultName' exists in resource group '$sharedResourceGroupName'..."

# First check if the Key Vault exists
if ! check_keyvault; then
    print_status "Key Vault not found. Attempting to create..."
    if ! create_keyvault; then
        exit 1
    fi
fi

# Verify the Key Vault is available and properly configured
for i in {1..12}; do # Retry for 2 minutes (12 * 10 seconds)
    if vault_name=$(check_keyvault); then
        print_success "Key Vault '$vault_name' is available and properly configured."
        # Verify purge protection is enabled
        if [[ $(az keyvault show --name "$keyVaultName" --resource-group "$sharedResourceGroupName" --query "properties.enablePurgeProtection" -o tsv) == "true" ]]; then
            print_success "Purge protection is enabled as required by policy."
            exit 0
        else
            print_warning "Purge protection is not enabled. This is required by policy."
            print_error "Please enable purge protection manually or contact your administrator."
            exit 1
        fi
    else
        print_warning "Key Vault not yet available, attempt $i/12. Retrying in 10 seconds..."
        sleep 10
    fi
done

print_error "Key Vault could not be verified after 2 minutes."
exit 1