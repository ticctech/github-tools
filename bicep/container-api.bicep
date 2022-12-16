// ----------------------------------------------------------------------------
// Exposes a Container App via an API gateway
// ----------------------------------------------------------------------------

@allowed([
  'dev'
  'stg'
  'prd'
])
@description('Environment short name')
param env string

@description('Name of the API name')
param apiName string

@description('Container App HTTP port')
param backendName string

@description('The base path to use for resources associated with this API')
param basePath string = '/'

@description('The API specification in openapi format')
param apiSpec string

@description('Container App ID')
param containerAppId string

@description('Container App FDQN')
param containerAppFqdn string

// get reference to API manager
resource apiManager 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: 'apim-ticc-${env}'
}

// endpoint specification
resource api 'Microsoft.ApiManagement/service/apis@2021-08-01' = if (apiName != '') {
  name: apiName
  parent: apiManager
  properties: {
    displayName: apiName
    apiRevision: '1'

    // apiVersion: 'string'
    isCurrent: true
    path: basePath
    type: 'http'
    protocols: [
      'https'
    ]
    subscriptionRequired: false
    format: 'swagger-json'
    value: base64ToJson(apiSpec)
  }
}

// create backend for service
resource backend 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' =  {
  name: backendName
  parent: apiManager
  properties: {
    url: 'https://${containerAppFqdn}'
    protocol: 'http'
    resourceId: '${environment().resourceManager}/${containerAppId}'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}
