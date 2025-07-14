// ----------------------------------------------------------------------------
// Updates a Container App with a new revision and configures traffic splitting
// ----------------------------------------------------------------------------

@description('Location of the Container Apps environment')
param location string = resourceGroup().location

@allowed([
  'dev'
  'stg'
  'prd'
])
@description('Environment short name')
param env string

@description('Base Container App name (without suffix)')
param baseAppName string

@description('Revision suffix (e.g., "test")')
param revisionSuffix string

@description('Container App image name')
param imageTag string

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
  name: 'cae-ticc-${env}'
}

// get a reference to the managed identity
resource managedId 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: 'id-ticc-${env}'
}

// -----------------------------
// Update Container App with new revision and traffic splitting
// -----------------------------
resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: 'ca-${baseAppName}'
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
      activeRevisionsMode: 'multiple'  // Enable multiple revisions
      dapr: {
        appId: baseAppName
        appPort: 8080
        appProtocol: 'http'
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
      revisionSuffix: revisionSuffix
      containers: [
        {
          name: baseAppName
          image: imageTag
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

output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output containerAppId string = containerApp.id
output revisionName string = '${baseAppName}--${revisionSuffix}'
