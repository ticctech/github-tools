@description('The name of the container app to add a revision to')
param containerAppName string

@description('The environment where this container app is deployed')
param env string

@description('The revision suffix to append to the revision name')
param revisionSuffix string

@description('The container image URL')
param containerImage string

@description('The port the container listens on')
param containerPort int = 8080

@description('The CPU allocation for the container')
param cpu string = '0.25'

@description('The memory allocation for the container')
param memory string = '0.5Gi'

@description('The minimum number of replicas')
param minReplicas int = 0

@description('The maximum number of replicas')
param maxReplicas int = 10

@description('Environment variables for the container')
param environmentVariables array = []

resource existingContainerApp 'Microsoft.App/containerApps@2023-05-01' existing = {
  name: containerAppName
}

resource containerAppRevision 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: resourceGroup().location
  properties: {
    managedEnvironmentId: existingContainerApp.properties.managedEnvironmentId
    configuration: {
      activeRevisionsMode: 'Multiple'
      ingress: {
        external: existingContainerApp.properties.configuration.ingress.external
        targetPort: containerPort
        allowInsecure: existingContainerApp.properties.configuration.ingress.allowInsecure
        traffic: [
          // Keep existing stable revision with 100% traffic
          {
            latestRevision: false
            revisionName: last(split(existingContainerApp.properties.latestRevisionName, '--'))
            weight: 100
          }
          // Add test revision with 0% traffic - APIM will route to it directly
          {
            latestRevision: false
            revisionName: '${containerAppName}--${revisionSuffix}'
            weight: 0
          }
        ]
      }
      dapr: existingContainerApp.properties.configuration.dapr
      secrets: existingContainerApp.properties.configuration.secrets
    }
    template: {
      revisionSuffix: revisionSuffix
      containers: [
        {
          name: containerAppName
          image: containerImage
          resources: {
            cpu: cpu
            memory: memory
          }
          probes: [
            {
              type: 'Readiness'
              httpGet: {
                path: '/health'
                port: containerPort
              }
              initialDelaySeconds: 5
              periodSeconds: 10
            }
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: containerPort
              }
              initialDelaySeconds: 15
              periodSeconds: 20
            }
          ]
          env: environmentVariables
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scale-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

output revisionName string = '${containerAppName}--${revisionSuffix}'
output containerAppUrl string = 'https://${existingContainerApp.properties.configuration.ingress.fqdn}'
