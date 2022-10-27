
az ts create \
  --name ts-containerapp \
  --version "1.0" \
  --resource-group "app-ticc-stg-ae-rg" \
  --location "australiaeast" \
  --template-file "./bicep/containerapp.bicep"

  az bicep publish \
    --file "./bicep/containerapp.bicep" \
    --target br:ticctech.azurecr.io/bicep/modules/containerapp:v1
