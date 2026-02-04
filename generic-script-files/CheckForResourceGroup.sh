#!/bin/bash

resourceGroupName=$1
resourceLocation=$2
# Function to check the existence of the resource group
az group show --name $resourceGroupName &>/dev/null \
|| az group create --name $resourceGroupName --location $resourceLocation
echo "Checking if resource group $resourceGroupName exists..."
for i in {1..10}; do # Retry 10 times with a delay
  if az group show --name $resourceGroupName &>/dev/null; then
    echo "Resource group found."
    exit 0
  else
    echo "Resource group not found, attempt $i/10. Retrying in 10 seconds..."
    sleep 10
  fi
done
echo "Resource group could not be found after 10 attempts."
exit 1

