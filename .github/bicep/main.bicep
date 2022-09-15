// ----------------------------------------------------------------------------
// Deploys a Container App and updates the API Manager to reference the app
// ----------------------------------------------------------------------------

@description('Location of the Container Apps environment')
param location string = resourceGroup().location

@description('Environment short name')
param env string

// @description('Name of Container Apps Managed Environment')
// param managedEnvName string

@description('Container App HTTP port')
param appName string

@description('Container App image name')
param imageName string

@secure()
@description('GitHub container registry user')
param ghcrUser string

@secure()
@description('GitHub container registry personal access token')
param ghcrPat string

@secure()
@description('Mongo DB URI')
param mongoUri string

// @description('Name of the API manager to add API reference to')
// param apiManagerName string

@description('Open API spec')
param apiSpec string

// deploy container app
module app 'containerapp.bicep' = {
  name: '${appName}-app'
  params: {
    location: location
    managedEnvName: 'cae-ticc-${env}'
    appName: appName
    imageName: imageName
    ghcrUser: ghcrUser
    ghcrPat: ghcrPat
    mongoUri: mongoUri
  }
}

// create API reference to app
module api 'api.bicep' = {
  name: '${appName}-api'
  params: {
    apiManagerName: 'apim-ticc-${env}'
    appName: appName
    apiSpec: apiSpec
    backendName: appName
    appFdqn: app.outputs.fdqn
    appId: app.outputs.appId
  }
}
