## PREREQUISITES ##

RESOURCE_GROUP="devops-pipeline-rg"
RESOURCES_LOCATION="ukwest"
KEYVAULT_NAME="devops-ade-kv"
STORAGE_ACCOUNT="devterraformbackendsadey"
CONTAINER_NAME="terraform-backend-files"
TF_SUBSCRIPTION="c88c8f23-28fa-446c-9737-a0a749bb194f"
TF_TENANT_ID=375b0336-"a057-4ecb-b117-e02bf5b9a1a9"
SERVICE_PRINCIPLE_NAME="aks-devops-terraform-sp"
SUBSCRIPTION_NAME="Visual Studio Enterprise"
SP_ID="9bb7506a-1e92-4d2b-adba-6f2e20a97d35"

######################################################
## step 1 CREATE KEY VAULT
######################################################

### Create the key vault resource group and the key vault
az group create -n $RESOURCE_GROUP -l $RESOURCES_LOCATION
az keyvault create -n $KEYVAULT_NAME -g $RESOURCE_GROUP -l $RESOURCES_LOCATION

# Make a note of the key vault resource id which will be in the format “/subscriptions/XXXXXXXX-XX86–47XX-X8Xf-XXXXXXXXXX/resourceGroups/dev-pipeline-dependencies-rg/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME”. We will need this in a subsequent step to give the AzDO dev subscription SP access to this key vault
KV_SUBSCRIPTION="/subscriptions/c88c8f23-28fa-446c-9737-a0a749bb194f/resourceGroups/devops-pipeline-rg/providers/Microsoft.KeyVault/vaults/devops-ade-kv"
echo $KV_SUBSCRIPTION

######################################################
## step 2 CREATE STORAGE ACCOUNT & CONTAINER
######################################################
az group create -n $RESOURCE_GROUP -l $RESOURCES_LOCATION
# Create storage account
az storage account create --resource-group $RESOURCE_GROUP --name $STORAGE_ACCOUNT --sku Standard_LRS --encryption-services blob
# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query [0].value -o tsv)
# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT --account-key $ACCOUNT_KEY

# Make a note of the storage account id


######################################################
## step 3 UPDATE KEY VAULT
######################################################
# Add the storage account key as a secret in the key vault
az keyvault secret set --vault-name $KEYVAULT_NAME --name "tf-backend-sa-access-key" --value "$ACCOUNT_KEY"


######################################################
## step 4 TF & DEVOPS SERVICE PRINCIPLE
######################################################
# Create terraform service principal with required access and add corresponding secrets to key vault
# save the tenant, appId and password use them to add in the keyvault as secrets below
az ad sp create-for-rbac -n $SERVICE_PRINCIPLE_NAME
TF_CLIENT_ID="9bb7506a-1e92-4d2b-adba-6f2e20a97d35"
TF_CLIENT_SECRET="NFA6D6n1uMP5z5ftR7Df-Nqwo23HYDSWlt"
# Add the values as secrets to key vault
az keyvault secret set --vault-name $KEYVAULT_NAME --name "tf-sp2-id" --value "$TF_CLIENT_ID"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "tf-sp2-secret" --value "$TF_CLIENT_SECRET"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "tf-tenant-id" --value "$TF_TENANT_ID"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "tf-subscription-id" --value "$TF_SUBSCRIPTION"

# Grant contributor role over the subscription to our service principal
az role assignment create --assignee $SERVICE_PRINCIPLE_NAME \
--scope "/subscriptions/$TF_SUBSCRIPTION" \
--role Contributor

az keyvault set-policy --name $KEYVAULT_NAME --spn $TF_SP --subscription $TF_SUBSCRIPTION --secret-permissions get

######################################################
## step 6 AKS SERVICE PRINCIPLE
######################################################
# Create AKS service principal and add corresponding secrets to key vault
AKS_SP=$(az ad sp create-for-rbac -n dev-aks-sp)
AKS_CLIENT_ID=""
AKS_CLIENT_SECRET=""
az keyvault secret set --vault-name $KEYVAULT_NAME --name "aks-sp-id" --value "$AKS_CLIENT_ID"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "aks-sp-secret" --value "$AKS_CLIENT_SECRET"


######################################################
## step 9 ADD SP TO DEVOPS PROJECT
######################################################

az devops service-endpoint azurerm create --azure-rm-service-principal-id $SP_ID --azure-rm-subscription-id $TF_SUBSCRIPTION --azure-rm-subscription-name "Visual" --azure-rm-tenant-id $TENANT_ID --name dev-sp --organization "https://dev.azure.com/sadey2k/" --project "aks-demo-01"

######################################################
## step 10 ADDITIONAL VARIABLES
######################################################
SSH_KEY="C:/Users/Shola/.ssh/aks-prod-sshkeys/aksprodsshkey.pub" \
