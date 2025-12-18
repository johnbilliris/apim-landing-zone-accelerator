/*
 * Input parameters
*/
@description('The name of the Application Gateway to be created.')
param appGatewayName string

@description('Name of the Application Gateway WAF Policy.')
param appGatewayWAFPolicyName string

@description('The location of the Application Gateway to be created')
param location string = resourceGroup().location

@description('Tags to apply to all resources.')
param tags object = {}

@description('The subnet resource id to use for Application Gateway.')
param appGatewaySubnetId string

@description('The backend URL of the APIM.')
param primaryBackendEndFQDN string

@description('The Url for the APIM Health Probe.')
param probeUrl string = '/status-0123456789abcdef'

@description('Name of the Application Gateway public IP address.')
param appGatewayPublicIpName string
@description('Name of the Key Vault for certificates.')
param keyVaultName string

@description('Name of the managed identity for Application Gateway.')
var appGatewayIdentityName = 'AppGatewayManagedIdentity'


resource appGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: appGatewayIdentityName
  location: location
  tags: !empty(tags) ? tags : null
}

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

// Role definition IDs
@description('Role ID for Key Vault Certificates Officer.')
var keyVaultCertificatesOfficerRoleId = 'a4417e6f-fecd-4de8-b567-7b0420556985'
@description('Role ID for Key Vault Secrets User.')
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

// Key Vault Certificates Officer role - for certificate import, get, list, update, create
resource certificatesOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appGatewayIdentity.id, keyVaultCertificatesOfficerRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultCertificatesOfficerRoleId)
    principalId: appGatewayIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Key Vault Secrets User role - for secret get and list
resource secretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appGatewayIdentity.id, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: appGatewayIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appGatewayPublicIPAddress 'Microsoft.Network/publicIPAddresses@2024-10-01' existing = {
  name: appGatewayPublicIpName
}

resource appgw_waf_Pol 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-10-01' = {
  name: appGatewayWAFPolicyName
  location: location
  tags: !empty(tags) ? tags : null
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 2000
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'
      jsChallengeCookieExpirationInMins: 30
      requestBodyInspectLimitInKB: 2000
      fileUploadEnforcement: true
      requestBodyEnforcement: true
    }
    customRules: [
      {
        name: 'AllowedPeopleSoftAppServers'
        priority: 1
        ruleType: 'MatchRule'
        action: 'Allow'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: false
            matchValues: [
              '10.134.248.0/24'
              '10.134.246.0/24'
              '10.134.245.0/24'
            ]
            transforms: []
          }
        ]
        state: 'Enabled'
      }
      {
        name: 'WhitelistJumphostForUpgrade'
        priority: 5
        ruleType: 'MatchRule'
        action: 'Allow'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: false
            matchValues: [
              '10.134.248.209/32'
            ]
            transforms: []
          }
        ]
        state: 'Disabled'
      }
      {
        name: 'CampusUATAllowInternalAnd3rdPartySaaS'
        priority: 10
        ruleType: 'MatchRule'
        action: 'Log'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RequestHeaders'
                selector: 'host'
              }
            ]
            operator: 'Contains'
            negationConditon: false
            matchValues: [
              'mycampusuat.nd.edu.au'
              ' testmycampusuat.nd.edu.au'
            ]
            transforms: []
          }
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'GeoMatch'
            negationConditon: true
            matchValues: [
              'AU'
              'US'
            ]
            transforms: []
          }
        ]
        state: 'Disabled'
      }
      {
        name: 'CampusProdAllowInternalAnd3rdPartySaaS'
        priority: 11
        ruleType: 'MatchRule'
        action: 'Log'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: false
            matchValues: [
              '3.105.223.156'
              '13.238.146.85'
              '52.62.133.229'
              '52.62.64.239'
              '52.102.12.197'
              '13.54.85.172'
              '13.54.118.128'
              '13.54.159.48'
              '10.0.0.0/8'
            ]
            transforms: []
          }
          {
            matchVariables: [
              {
                variableName: 'RequestHeaders'
                selector: 'host'
              }
            ]
            operator: 'Contains'
            negationConditon: false
            matchValues: [
              'mycampus.nd.edu.au'
              'mycampusprd2.nd.edu.au'
            ]
            transforms: []
          }
        ]
        state: 'Disabled'
      }
      {
        name: 'FinHRAllowAustraliaOnly'
        priority: 12
        ruleType: 'MatchRule'
        action: 'Log'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'GeoMatch'
            negationConditon: true
            matchValues: [
              'AU'
            ]
            transforms: []
          }
          {
            matchVariables: [
              {
                variableName: 'RequestHeaders'
                selector: 'host'
              }
            ]
            operator: 'Contains'
            negationConditon: false
            matchValues: [
              'myfinance.nd.edu.au'
              'myfinanceprd2.nd.edu.au'
              'mystaffing.nd.edu.au'
              'mystaffingprd2.nd.edu.au'
            ]
            transforms: []
          }
        ]
        state: 'Disabled'
      }
      {
        name: 'RateLimit'
        priority: 20
        ruleType: 'RateLimitRule'
        rateLimitDuration: 'OneMin'
        action: 'Block'
        rateLimitThreshold: 250
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: true
            matchValues: [
              '255.255.255.255/32'
            ]
            transforms: []
          }
        ]
        groupByUserSession: [
          {
            groupByVariables: [
              {
                variableName: 'ClientAddr'
              }
            ]
          }
        ]
        state: 'Enabled'
      }
      {
        name: 'ConsoleAccessInternalOnly'
        priority: 25
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RequestUri'
              }
            ]
            operator: 'Contains'
            negationConditon: false
            matchValues: [
              '/console/login'
            ]
            transforms: [
              'Lowercase'
            ]
          }
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: true
            matchValues: [
              '10.0.0.0/8'
            ]
            transforms: []
          }
        ]
        state: 'Enabled'
      }
      {
        name: 'MyEqualIPs'
        priority: 48
        ruleType: 'MatchRule'
        action: 'Allow'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            negationConditon: false
            matchValues: [
              '3.105.223.156'
              '13.238.146.85'
              '52.62.133.229'
              '52.62.64.239'
              '52.102.12.197'
              '13.54.85.172'
              '13.54.118.128'
              '13.54.159.48'
            ]
            transforms: []
          }
        ]
        state: 'Enabled'
      }
    ]
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
          ruleGroupOverrides: [
            {
              ruleGroupName: 'General'
              rules: [
                {
                  ruleId: '200002'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '200003'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
            {
              ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
              rules: [
                {
                  ruleId: '942120'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942110'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942130'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942370'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942410'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942210'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942260'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942200'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942430'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942440'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942450'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942330'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942340'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942150'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942190'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942400'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942480'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942100'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942230'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942310'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942180'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942470'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942300'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '942380'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
            {
              ruleGroupName: 'REQUEST-920-PROTOCOL-ENFORCEMENT'
              rules: [
                {
                  ruleId: '920230'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '920440'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '920271'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '920121'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '920120'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
            {
              ruleGroupName: 'REQUEST-944-APPLICATION-ATTACK-JAVA'
              rules: [
                {
                  ruleId: '944240'
                  state: 'Enabled'
                  action: 'AnomalyScoring'
                }
              ]
            }
            {
              ruleGroupName: 'REQUEST-913-SCANNER-DETECTION'
              rules: [
                {
                  ruleId: '913101'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
            {
              ruleGroupName: 'REQUEST-931-APPLICATION-ATTACK-RFI'
              rules: [
                {
                  ruleId: '931130'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '931120'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
            {
              ruleGroupName: 'REQUEST-941-APPLICATION-ATTACK-XSS'
              rules: [
                {
                  ruleId: '941100'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '941130'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '941340'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '941330'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '941150'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '941120'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '941320'
                  state: 'Enabled'
                  action: 'Log'
                }
                {
                  ruleId: '941101'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
            {
              ruleGroupName: 'REQUEST-932-APPLICATION-ATTACK-RCE'
              rules: [
                {
                  ruleId: '932110'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
            {
              ruleGroupName: 'REQUEST-933-APPLICATION-ATTACK-PHP'
              rules: [
                {
                  ruleId: '933210'
                  state: 'Enabled'
                  action: 'Log'
                }
              ]
            }
          ]
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.1'
          ruleGroupOverrides: []
        }
      ]
      exclusions: [
        {
          matchVariable: 'RequestCookieNames'
          selectorMatchOperator: 'Equals'
          selector: 'psback'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942260'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestHeaderNames'
          selectorMatchOperator: 'Equals'
          selector: 'user-agent'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-913-SCANNER-DETECTION'
                  rules: [
                    {
                      ruleId: '913100'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestCookieNames'
          selectorMatchOperator: 'Equals'
          selector: 'psback'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-941-APPLICATION-ATTACK-XSS'
                  rules: [
                    {
                      ruleId: '941130'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestCookieNames'
          selectorMatchOperator: 'Equals'
          selector: 'psback'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-941-APPLICATION-ATTACK-XSS'
                  rules: [
                    {
                      ruleId: '941340'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'xmlversion1'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-941-APPLICATION-ATTACK-XSS'
                  rules: [
                    {
                      ruleId: '941340'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'xmlversion1'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942110'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'xmlversion1'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942130'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestCookieNames'
          selectorMatchOperator: 'Equals'
          selector: 'psback'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942340'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'xmlversion1'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942370'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'xmlversion1'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942430'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'BI_HDR_EXPR_VW_BILL_TO_CUST_ID'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-920-PROTOCOL-ENFORCEMENT'
                  rules: [
                    {
                      ruleId: '920270'
                    }
                    {
                      ruleId: '920271'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestCookieNames'
          selectorMatchOperator: 'Equals'
          selector: 'PS_TOKEN'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-932-APPLICATION-ATTACK-RCE'
                  rules: [
                    {
                      ruleId: '932140'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestCookieNames'
          selectorMatchOperator: 'Equals'
          selector: 'psback'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-941-APPLICATION-ATTACK-XSS'
                  rules: [
                    {
                      ruleId: '941330'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestCookieNames'
          selectorMatchOperator: 'Equals'
          selector: 'psback'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942190'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'ICChart'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942430'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'GP_PI_MNL_DATA'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942430'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'PortalActual'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942430'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'BI_HDR_EXPR_VW_BILL_TO_CUST_ID'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942440'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'EMPLOYEE'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942400'
                    }
                    {
                      ruleId: '942450'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Contains'
          selector: 'PeopleSoftListeningConnector'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'General'
                  rules: [
                    {
                      ruleId: '200002'
                    }
                    {
                      ruleId: '200003'
                    }
                  ]
                }
                {
                  ruleGroupName: 'REQUEST-920-PROTOCOL-ENFORCEMENT'
                  rules: [
                    {
                      ruleId: '920440'
                    }
                  ]
                }
                {
                  ruleGroupName: 'REQUEST-941-APPLICATION-ATTACK-XSS'
                  rules: [
                    {
                      ruleId: '941160'
                    }
                    {
                      ruleId: '941180'
                    }
                    {
                      ruleId: '941330'
                    }
                  ]
                }
              ]
            }
          ]
        }
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Equals'
          selector: 'postDataBin'
          exclusionManagedRuleSets: [
            {
              ruleSetType: 'OWASP'
              ruleSetVersion: '3.2'
              ruleGroups: [
                {
                  ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
                  rules: [
                    {
                      ruleId: '942380'
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  }
}

resource appGatewayName_resource 'Microsoft.Network/applicationGateways@2024-10-01' = {
  name: appGatewayName
  location: location
  tags: !empty(tags) ? tags : null
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGatewayIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnetId
          }
        }
      }
    ]
    sslCertificates: [

    ]
    sslPolicy: {
      minProtocolVersion: 'TLSv1_2'
      policyType: 'Custom'
      cipherSuites: [
        'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256'
        'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384'
        'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
        'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
        'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256'
        'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384'
        'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256'
        'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384'
      ]
    }
    trustedRootCertificates: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGatewayPublicIPAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
       {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apim'
        properties: {
          backendAddresses: [
            {
              fqdn: primaryBackendEndFQDN
            }
          ]
        }
      }
      {
        name: 'sink-hole'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'apim-demo-apis-http'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          hostName: primaryBackendEndFQDN
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'apim-demo-apis-http')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'apim-demo-apis-http'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              appGatewayName,
              'appGwPublicFrontendIp'
            )
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'urlPathMapApim'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              appGatewayName,
              'apim'
            )
          }
          defaultBackendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              appGatewayName,
              'apim-demo-apis-http'
            )
          }
          pathRules: [
            {
              name: 'echo-api'
              properties: {
                paths: [
                  '/api/echo/*'
                ]
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    appGatewayName,
                    'apim'
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    appGatewayName,
                    'apim-demo-apis-http'
                  )
                }
              }
            }
            {
              name: 'color-api'
              properties: {
                paths: [
                  '/api/color*'
                ]
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    appGatewayName,
                    'apim'
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    appGatewayName,
                    'apim-demo-apis-http'
                  )
                }
              }
            }        
            {
              name: 'default'
              properties: {
                paths: [
                  '/*'
                ]
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    appGatewayName,
                    'sink-hole'
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    appGatewayName,
                    'apim-demo-apis-http'
                  )
                }
              }
            }            
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'apim-demo-apis'
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 100
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGatewayName, 'urlPathMapApim')
          }
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              appGatewayName,
              'apim-demo-apis-http'
            )
          }
        }
      }
    ]
    probes: [
      {
        name: 'apim-demo-apis-http'
        properties: {
          protocol: 'Http'
          host: primaryBackendEndFQDN
          path: probeUrl
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: []
    firewallPolicy: {
      id: appgw_waf_Pol.id
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 3
    }
  }
}



output name string = appGatewayName_resource.name
output id string = appGatewayName_resource.id
output location string = appGatewayName_resource.location
output resourceGroupName string = resourceGroup().name
output appGatewayPublicIpAddress string = appGatewayPublicIPAddress.properties.ipAddress

