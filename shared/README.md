# Introduction 
This is a shared repository containing the most common resources used for most projects in Azure.


# Prerequisites
Make sure that the app registration has the right permissions in your subscription!
Required permissions are either:

**"User Access Administrator"** with full permissions (Highly privilegied)

or

**"User Access Administrator"** with some permissions (Recommended) AND **"Role Based Access Control Administrator"** (Recommended)

**"Storage Account Contributor"**

**"Storage Blob Data Contributor"**

**"Contributor"**

# In case Nodinite is used
Make sure that the app registration used for Nodinites access to Azure has the right permisions.
See this link:
https://docs.nodinite.com/Documentation/InstallAndUpdate?doc=/Troubleshooting/Azure%20Application%20Access#least-privileges



# Purge APIM instance
To Purge an APIM instance from Azure, first delete the resource manually in the portal, then do the following:

Log in to Azure Cli using az login

Replace the {placeholders} in the URL and execute this command:

az rest --method delete --url "https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.ApiManagement/locations/{location}/deletedservices/{serviceName}?api-version=2021-08-01"

Dev subscription: 

Test subscription: 

Prod subscription:
