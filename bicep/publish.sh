
az ts create \
  --name ts-container-app \
  --version "1.0" \
  --resource-group "app-ticc-stg-ae-rg" \
  --location "australiaeast" \
  --template-file "./bicep/container-app.bicep"

az ts create \
  --name ts-container-api \
  --version "1.0" \
  --resource-group "app-ticc-stg-ae-rg" \
  --location "australiaeast" \
  --template-file "./bicep/container-api.bicep"

  # az bicep publish \
  #   --file "./bicep/containerapp.bicep" \
  #   --target br:ticctech.azurecr.io/bicep/modules/containerapp:v1
