@description('Name of the API manager')
param apiManagerName string

@description('The name of the API')
param apiName string

@description('The API specification in openapi format')
param apiSpec string

@description('The name of backend service for this API')
param backendName string

@description('Fully qualified domain name of the app')
param appFdqn string

@description('Container app id for backend')
param appId string

// get reference to API manager
resource apiManager 'Microsoft.ApiManagement/service@2021-08-01' existing = {
  name: apiManagerName
}

// update API from swagger
resource api 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: apiName
  parent: apiManager
  properties: {
    displayName: apiName
    apiRevision: '1'
    // apiVersion: 'string'
    isCurrent: true
    path: '/${apiName}'
    type: 'http'
    protocols: [
      'https'
    ]
    subscriptionRequired: false
    format: 'swagger-json'
    value: apiSpec
  }
}

var apiPolicies = format('''
  <policies>
    <inbound>
      <base />
      <set-backend-service backend-id="{0}" />
    </inbound>
    <backend>
      <base />
    </backend>
    <outbound>
      <base />
    </outbound>
    <on-error>
      <base />
    </on-error>
  </policies>
''', backendName)

// set policies
resource policies 'Microsoft.ApiManagement/service/apis/policies@2021-08-01' = {
  name: 'policy'
  parent: api
  properties: {
    format: 'xml'
    value: apiPolicies
  }
}

// create backend for service
resource backend 'Microsoft.ApiManagement/service/backends@2021-12-01-preview' = {
  name: backendName
  parent: apiManager
  properties: {
    url: 'https://${appFdqn}'
    protocol: 'http'
    resourceId: '${environment().resourceManager}/${appId}'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}
