param apimName string
param loggerName string
param apiNames array = []

resource apim 'Microsoft.ApiManagement/service@2024-06-01-preview' existing = {
  name: apimName
}

resource logger 'Microsoft.ApiManagement/service/loggers@2024-10-01-preview' existing = {
  parent: apim
  name: loggerName
}

resource apimName_applicationinsights 'Microsoft.ApiManagement/service/diagnostics@2022-08-01' = {
  parent: apim
  name: 'applicationinsights'
  properties: {
    loggerId: logger.id
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'Legacy'
    verbosity: 'information'
    logClientIp: true
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
    metrics: true
    frontend: {
      request: {
        body: {
          bytes: 0
        }
      }
      response: {
        body: {
          bytes: 0
        }
      }
    }
    backend: {
      request: {
        body: {
          bytes: 0
        }
      }
      response: {
        body: {
          bytes: 0
        }
      }
    }
  }
}

// Loop through each API and assign the logger
resource apiDiagnostics 'Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01' = [for apiName in apiNames: {
  name: '${apimName}/${apiName}/applicationinsights'
  properties: {
    loggerId: logger.id
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'Legacy'
    verbosity: 'information'
    logClientIp: true
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
    metrics: true
    frontend: {
      request: {
        body: {
          bytes: 0
        }
      }
      response: {
        body: {
          bytes: 0
        }
      }
    }
    backend: {
      request: {
        body: {
          bytes: 0
        }
      }
      response: {
        body: {
          bytes: 0
        }
      }
    }
  }
}]
