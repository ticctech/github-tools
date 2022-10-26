// ----------------------------------------------------------------------------
// Deploys a Container App
// ----------------------------------------------------------------------------

@description('Location of the Container Apps environment')
param location string = resourceGroup().location

@description('Name of Container Apps Managed Environment')
param managedEnvName string

@description('Name of Container Apps Managed Identity')
param managedIdName string

@description('Container App HTTP port')
param appName string

@description('Container App image name')
param imageName string

@description('Container App target port')
param targetPort int = 8080

@secure()
@description('GitHub container registry user')
param ghcrUser string

@secure()
@description('GitHub container registry personal access token')
param ghcrPat string

// get a reference to the container apps environment
resource managedEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: managedEnvName
}

// get a reference to the container apps environment
resource managedId 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdName
}

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'ca-${appName}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedId.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: managedEnv.id
    configuration: {
      activeRevisionsMode: 'single'
      dapr: {
        appId: appName
        appPort: 8080
        appProtocol: 'grpc'
        enabled: true
      }
      ingress: {
        external: true
        targetPort: targetPort
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          server: 'ghcr.io'
          username: ghcrUser
          passwordSecretRef: 'ghcr-pat'
        }
      ]
      secrets: [
        {
          name: 'ghcr-pat'
          value: ghcrPat
        }
      ]
    }
    template: {
      containers: [
        {
          name: appName
          image: imageName
          resources: {
            cpu: any('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 2
        rules: [
          {
            name: 'httpscalingrule'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
          {
            name: 'cpuscalingrule'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '75'
              }
            }
          }
          {
            name: 'memoryscalingrule'
            custom: {
              type: 'memory'
              metadata: {
                type: 'Utilization'
                value: '75'
              }
            }
          }
        ]
      }
    }
  }
}

// used to set app as 'backend' in API manager
output appId string = containerApp.id
output fdqn string = containerApp.properties.configuration.ingress.fqdn
