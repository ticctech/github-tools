// ----------------------------------------------------------------------------
// Deploys a Container App and updates the API Manager to reference the app
// TODO: change ghcr user and PAT to ticctech-muser
// TODO: scale range from 1 to 5?
// TODO: add support for Dapr
// ----------------------------------------------------------------------------

@description('Location of the Container Apps environment')
param location string = resourceGroup().location

@description('Name of Container Apps Managed Environment')
param managedEnvName string

@description('Container App HTTP port')
param appName string

@description('Container App image name')
param imageName string = 'ghcr.io/ticctech/${appName}:latest'

@description('Container App HTTP port')
param httpPort int = 8080

@description('Container App gRPC port')
param grpcPort int = 8080

@secure()
@description('Mongo DB URI')
param mongoUri string

@secure()
@description('GitHub container registry user')
param ghcrUser string

@secure()
@description('GitHub container registry personal access token')
param ghcrPat string

@description('Name of the API manager to add API reference to')
param apiManagerName string = 'apim-ticc-dev'

@description('Prefix for API manager resource id')
param apiResource string

// deploy container app
module app 'containerapp.bicep' = {
  name: '${appName}-app'
  params: {
    location: location
    managedEnvName: managedEnvName
    appName: appName
    imageName: imageName
    ghcrUser: ghcrUser
    ghcrPat: ghcrPat
    httpPort: httpPort
    grpcPort: grpcPort
    mongoUri: mongoUri
  }
}

// create API reference to app
module api 'api.bicep' = {
  name: '${appName}-api'
  params: {
    apiResource: apiResource
    apiName: 'workflows'
    displayName: 'Workflows'
    backendName: appName
    apiSpec: loadTextContent('../../gen/proto/openapi/workflow/v1/workflow.swagger.json')
    apiManagerName: apiManagerName
    appId: app.outputs.appId
    appFdqn: app.outputs.fdqn
  }
}
