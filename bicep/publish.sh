
RESOURCE_GROUP="app-ticc-dev-ae-rg"

az ts create \
  --name ts-container-app \
  --version "1.2" \
  --resource-group "$RESOURCE_GROUP" \
  --location "australiaeast" \
  --template-file "./bicep/container-app.bicep"

az ts create \
  --name ts-api-backend \
  --version "1.0" \
  --resource-group "$RESOURCE_GROUP" \
  --location "australiaeast" \
  --template-file "./bicep/api-backend.bicep"


