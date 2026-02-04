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

# Function to check and register provider with progress
check_and_register_provider() {
    local provider=$1
    local state=$(az provider show --namespace $provider --query "registrationState" -o tsv 2>/dev/null)
    
    if [ "$state" != "Registered" ]; then
        print_status "Registering $provider..."
        az provider register --namespace $provider --only-show-errors
    fi
}

# Function to verify all providers are registered
verify_providers() {
    local providers=("$@")
    local all_registered=true
    
    for provider in "${providers[@]}"; do
        local state=$(az provider show --namespace $provider --query "registrationState" -o tsv 2>/dev/null)
        if [ "$state" != "Registered" ]; then
            all_registered=false
            print_warning "$provider is still registering..."
        fi
    done
    
    return $([ "$all_registered" = true ])
}

# Essential providers for Azure Integration Services
PROVIDERS=(
    "Microsoft.Storage"
    "Microsoft.Web"
    "Microsoft.ServiceBus"
    "Microsoft.Logic"
    "Microsoft.KeyVault"
    "Microsoft.Insights"
    "Microsoft.EventGrid"
    "Microsoft.EventHub"
    "Microsoft.ApiManagement"
    "Microsoft.OperationalInsights"
    "Microsoft.ManagedIdentity"
)

# Verify Azure CLI is logged in
print_status "Verifying Azure authentication..."
if ! az account show --query id -o tsv &>/dev/null; then
    print_error "Not logged into Azure. Please run 'az login' first."
    exit 1
fi
print_success "Using subscription: $(az account show --query name -o tsv)"

# Register providers in parallel
print_status "Registering required Azure providers..."
for provider in "${PROVIDERS[@]}"; do
    check_and_register_provider "$provider" &
done
wait

# Wait for all providers to be registered
print_status "Waiting for provider registration to complete..."
while ! verify_providers "${PROVIDERS[@]}"; do
    sleep 5
done
print_success "All providers registered successfully"
exit 0
