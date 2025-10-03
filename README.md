# Azure Private Endpoint DNS integration : one policy to rule them all !

![one policy to rule them all !](images/azure-policy.png)

# Overview
The challenge with Privte Endpoint is clearly the DNS integration and configuration. 
It's important to correctly configure the DNS to resolve the endpoint name with the private IP address.

Existing Microsoft Azure services might already have a DNS configuration for a public endpoint. This configuration must be overridden to connect using private endpoint.

The network interface associated with the private endpoint contains the information to configure DNS. The network interface information includes FQDN and private IP addresses for the private link resource.

# Azure services DNS zone configuration
Azure creates a canonical name DNS record (CNAME) on the public DNS. The CNAME record redirects the resolution to the private domain name. You can override the resolution with the private IP address of your private endpoints.

# Implementation
## Terraform deployment
### Requirements
You will need to install : 
* [Terraform](https://www.terraform.io/downloads.html)
* Terraform Providers (installed using command *terraform init*): 
  * azurerm (> v4.0)
  * random

### Quickstart
You can review and edit the mapping in file : private-zones.json and customize options in file : variables.tf
Once everything is ready, you just have to start terraform deployment : 
````
> terraform init
> terraform plan
> terraform apply
````
After severals minutes, everything must be deployed: 
![terraform apply](images/terraform.png)

You will have one dedicated Ressource Group for Private DNS Zone: 
![](images/private-dns-zones-rg.png)

If you check on [Policy Assignments](https://portal.azure.com/#view/Microsoft_Azure_Policy/PolicyMenuBlade/~/Assignments) you must have all the assignments done for all the type of private endpoint: 
![](images/policy-assignments.png)

## Manual configuration
You can use deploy-policy.json file to create a new policy definition using Azure portal or CLI : 
```
az policy definition create --name 'AzurePaaSPrivateDNSZone' --rules "`jq '.[].policyRule' deploy-policy.json`" --params "`jq '.[].parameters' deploy-policy.json`"
```

You have to create in advance the Private DNS Zone corresponding to the type of private endpoint you want to manage with the policy. 

You can create one assignement for each type of private endpoint (privateLinkResourceType / subresource). For example if you want to manage Storage Account blob private endpoint : 
```
az policy assignment create --name 'private-dns-storageAccounts-blob' --policy 'AzurePaaSPrivateDNSZone' --mi-system-assigned --location westeurope --params '{"privateDnsZoneIds": {"value": [  "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/private-dns-zones-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]},"privateEndpointGroupId": {"value": "blob"},"privateEndpointPrivateLinkServiceId": {"value": "Microsoft.Storage/storageAccounts"}}'
```

If you want to deny the creation of private DNS zone, you can use the deny policy using provided definition : 
```
az policy definition create --name 'DenyPrivateDNSZones' --rules "`jq '.properties.policyRule' deny-policy.json`" --params "`jq '.properties.parameters' deny-policy.json`"
az policy assignment create --name 'deny-private-dns-zone' --policy 'DenyPrivateDNSZones'

```

## Excluded DNS Zones

The following DNS zones have been excluded from the configuration because they contain variables that need to be replaced at deployment time:

### Completely Excluded Services
- **Azure Kubernetes Service** (`Microsoft.ContainerService/managedClusters`)
  - Excluded zones: `privatelink.{regionName}.azmk8s.io`, `{subzone}.privatelink.{regionName}.azmk8s.io`
  - Reason: All zones contain region-specific variables

- **Azure Container Apps** (`Microsoft.App/ManagedEnvironments`) 
  - Excluded zones: `privatelink.{regionName}.azurecontainerapps.io`
  - Reason: Zone contains region-specific variable

- **Azure SQL Managed Instance** (`Microsoft.Sql/managedInstances`)
  - Excluded zones: `privatelink.{dnsPrefix}.database.windows.net`
  - Reason: Zone contains DNS prefix variable

### Partially Excluded Zones
- **Azure Data Explorer** (`Microsoft.Kusto/Clusters`)
  - Excluded zone: `privatelink.{regionName}.kusto.windows.net`
  - Kept zones: `privatelink.blob.core.windows.net`, `privatelink.queue.core.windows.net`, `privatelink.table.core.windows.net`

- **Azure Container Registry** (`Microsoft.ContainerRegistry/registries`)
  - Excluded zone: `{regionName}.data.privatelink.azurecr.io`
  - Kept zone: `privatelink.azurecr.io`

- **Azure Backup** (`Microsoft.RecoveryServices/vaults`)
  - Excluded zone: `privatelink.{regionCode}.backup.windowsazure.com`
  - Kept zones: `privatelink.blob.core.windows.net`, `privatelink.queue.core.windows.net`

- **Azure Static Web Apps** (`Microsoft.Web/staticSites`)
  - Excluded zone: `privatelink.{partitionId}.azurestaticapps.net`
  - Kept zone: `privatelink.azurestaticapps.net`

### Note
These zones require manual configuration with appropriate region codes, DNS prefixes, or partition IDs specific to your deployment environment.

