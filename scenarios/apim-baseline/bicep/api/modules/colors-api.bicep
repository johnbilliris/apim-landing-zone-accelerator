@description('The name of the API Management resource to be created.')
param apimName string
param products array = []

resource apim 'Microsoft.ApiManagement/service@2024-10-01-preview' existing = {
  name: apimName
}

// Colors APIs
resource colorsApi 'Microsoft.ApiManagement/service/apis@2024-10-01-preview' = {
  parent: apim
  name: 'colors-api'
  properties: {
    displayName: 'Colors API'
    apiRevision: '1'
    description: 'Colors API'
    subscriptionRequired: true
    serviceUrl: 'https://colors-api.azurewebsites.net/'
    protocols: [
      'https'
    ]
    authenticationSettings: {
      oAuth2AuthenticationSettings: []
      openidAuthenticationSettings: []
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    termsOfServiceUrl: 'https://github.com/markharrison/ColorsAPI/blob/master/LICENSE'
    contact: {
      name: 'Mark Harrison'
      url: 'https://github.com/markharrison/ColorsAPI'
      email: 'mark.colorsapi@harrison.ws'
    }
    license: {
      name: 'Use under MIT License'
      url: 'https://github.com/markharrison/ColorsAPI/blob/master/LICENSE'
    }
    isCurrent: true
    path: ''
  }
}

resource Colors 'Microsoft.ApiManagement/service/tags@2024-06-01-preview' = {
  parent: apim
  name: 'Colors'
  properties: {
    displayName: 'Colors'
  }
}


resource colorsApi_DeleteColorById 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: colorsApi
  name: 'DeleteColorById'
  properties: {
    displayName: 'Delete color by id'
    method: 'DELETE'
    urlTemplate: '/colors/{colorId}'
    templateParameters: [
      {
        name: 'colorId'
        description: 'Id of Color to delete'
        type: 'integer'
        required: true
        values: []
        //schemaId: colorsApiSchema.name
        typeName: 'Colors-colorId-DeleteRequest'
      }
    ]
    description: 'Deletes color specified by {colorId} (must be between 1 and 1000).'
    responses: [
      {
        statusCode: 204
        description: 'Success - color deleted'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
        ]
        headers: []
      }
      {
        statusCode: 422
        description: 'Unprocessable Entity'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
        ]
        headers: []
      }
    ]
  }
}

resource colorsApi_DeletesColors 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: colorsApi
  name: 'DeletesColors'
  properties: {
    displayName: 'Delete colors'
    method: 'DELETE'
    urlTemplate: '/colors'
    templateParameters: []
    description: 'Deletes all colors.'
    responses: [
      {
        statusCode: 204
        description: 'Success - all colors deleted'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
        ]
        headers: []
      }
    ]
  }
}

resource colorsApi_GetColorById 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: colorsApi
  name: 'GetColorById'
  properties: {
    displayName: 'Get color by id'
    method: 'GET'
    urlTemplate: '/colors/{colorId}'
    templateParameters: [
      {
        name: 'colorId'
        description: 'Id of Color to return'
        type: 'integer'
        required: true
        values: []
        schemaId: colorsApiSchema.name
        typeName: 'Colors-colorId-GetRequest'
      }
    ]
    description: 'Returns color specified by {colorId} (must be between 1 and 1000).'
    responses: [
      {
        statusCode: 200
        description: 'Success - returns color'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
        ]
        headers: []
      }
      {
        statusCode: 404
        description: 'Not Found'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
        ]
        headers: []
      }
      {
        statusCode: 422
        description: 'Unprocessable Entity'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
        ]
        headers: []
      }
    ]
  }
}

resource colorsApi_GetColorBy 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: colorsApi
  name: 'GetColorByName'
  properties: {
    displayName: 'Get color by name'
    method: 'GET'
    urlTemplate: '/colors/findbyname?colorName={colorName}'
    templateParameters: [
      {
        name: 'colorName'
        description: 'Name of Color to return'
        type: 'string'
        required: true
        values: []
        schemaId: colorsApiSchema.name
        typeName: 'ColorsFindbynameGetRequest'
      }
    ]
    description: 'Returns color specified by {colorName} '
    responses: [
      {
        statusCode: 200
        description: 'Success - returns color'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
        ]
        headers: []
      }
      {
        statusCode: 404
        description: 'Not Found'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
        ]
        headers: []
      }
    ]
  }
}

resource colorsApi_GetColors 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: colorsApi
  name: 'GetColors'
  properties: {
    displayName: 'Get colors'
    method: 'GET'
    urlTemplate: '/colors'
    templateParameters: []
    description: 'Returns all colors.'
    responses: [
      {
        statusCode: 200
        description: 'Success - returns list of colors'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsGet200TextPlainResponse'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: [
                  {
                    id: 0
                    name: 'string'
                    hexcode: 'string'
                    data: 'string'
                  }
                ]
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsGet200ApplicationJsonResponse'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: [
                  {
                    id: 0
                    name: 'string'
                    hexcode: 'string'
                    data: 'string'
                  }
                ]
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsGet200TextJsonResponse'
          }
        ]
        headers: []
      }
    ]
  }
}

resource colorsApi_GetRandomColor 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: colorsApi
  name: 'GetRandomColor'
  properties: {
    displayName: 'Get random color'
    method: 'GET'
    urlTemplate: '/colors/random'
    templateParameters: []
    description: 'Returns random color.'
    responses: [
      {
        statusCode: 200
        description: 'Success - returns random color'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
        ]
        headers: []
      }
      {
        statusCode: 404
        description: 'Not Found'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
        ]
        headers: []
      }
    ]
  }
}

resource colorsApi_ResetColors 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: colorsApi
  name: 'ResetColors'
  properties: {
    displayName: 'Reset colors'
    method: 'POST'
    urlTemplate: '/colors/reset'
    templateParameters: []
    description: 'Reset colors to default.'
    responses: [
      {
        statusCode: 201
        description: 'Success - colors reset'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
        ]
        headers: []
      }
    ]
  }
}

resource colorsApi_UpdateColorById 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: colorsApi
  name: 'UpdateColorById'
  properties: {
    displayName: 'Update / create color by id'
    method: 'POST'
    urlTemplate: '/colors/{colorId}'
    templateParameters: [
      {
        name: 'colorId'
        description: 'Id of Color to update'
        type: 'integer'
        required: true
        values: []
        schemaId: colorsApiSchema.name
        typeName: 'Colors-colorId-PostRequest'
      }
    ]
    description: 'Updates color specified by {colorId} (must be between 1 and 1000);  use {colorId} = 0 to insert new color'
    request: {
      description: 'Colors to update'
      queryParameters: []
      headers: []
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: {
                id: 0
                name: 'string'
                hexcode: 'string'
                data: 'string'
              }
            }
          }
          schemaId: colorsApiSchema.name
          typeName: 'ColorsItem'
        }
        {
          contentType: 'text/json'
          examples: {
            default: {
              value: {
                id: 0
                name: 'string'
                hexcode: 'string'
                data: 'string'
              }
            }
          }
          schemaId: colorsApiSchema.name
          typeName: 'ColorsItem'
        }
        {
          contentType: 'application/*+json'
          examples: {
            default: {
              value: {
                id: 0
                name: 'string'
                hexcode: 'string'
                data: 'string'
              }
            }
          }
          schemaId: colorsApiSchema.name
          typeName: 'ColorsItem'
        }
      ]
    }
    responses: [
      {
        statusCode: 201
        description: 'Success - color created/updated'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
        ]
        headers: []
      }
      {
        statusCode: 422
        description: 'Unprocessable Entity'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
        ]
        headers: []
      }
    ]
  }
}

resource colorsApi_UpdateColors 'Microsoft.ApiManagement/service/apis/operations@2024-06-01-preview' = {
  parent: colorsApi
  name: 'UpdateColors'
  properties: {
    displayName: 'Update / create colors'
    method: 'POST'
    urlTemplate: '/colors'
    templateParameters: []
    description: 'Updates colors - creates color if it doesn\'t exist'
    request: {
      description: 'Colors to update'
      queryParameters: []
      headers: []
      representations: [
        {
          contentType: 'application/json'
          examples: {
            default: {
              value: [
                {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              ]
            }
          }
          schemaId: colorsApiSchema.name
          typeName: 'ColorsPostRequest'
        }
        {
          contentType: 'text/json'
          examples: {
            default: {
              value: [
                {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              ]
            }
          }
          schemaId: colorsApiSchema.name
          typeName: 'ColorsPostRequest-1'
        }
        {
          contentType: 'application/*+json'
          examples: {
            default: {
              value: [
                {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              ]
            }
          }
          schemaId: colorsApiSchema.name
          typeName: 'ColorsPostRequest-2'
        }
      ]
    }
    responses: [
      {
        statusCode: 201
        description: 'Success - colors updated/created'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  id: 0
                  name: 'string'
                  hexcode: 'string'
                  data: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ColorsItem'
          }
        ]
        headers: []
      }
      {
        statusCode: 422
        description: 'Unprocessable Entity'
        representations: [
          {
            contentType: 'text/plain'
            examples: {
              default: {}
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
          {
            contentType: 'text/json'
            examples: {
              default: {
                value: {
                  type: 'string'
                  title: 'string'
                  status: 0
                  detail: 'string'
                  instance: 'string'
                }
              }
            }
            schemaId: colorsApiSchema.name
            typeName: 'ProblemDetails'
          }
        ]
        headers: []
      }
    ]
  }
}

resource colorsSchema 'Microsoft.ApiManagement/service/schemas@2024-06-01-preview' = {
  parent: apim
  name: 'colorsSchema'
  properties: {
    schemaType: 'json'
    document: {
      openapi: '3.0.4'
      info: {
        title: 'Mark Harrison Colors API'
        description: 'Colors API'
        termsOfService: 'https://github.com/markharrison/ColorsAPI/blob/master/LICENSE'
        contact: {
          name: 'Mark Harrison'
          url: 'https://github.com/markharrison/ColorsAPI'
          email: 'mark.colorsapi@harrison.ws'
        }
        license: {
          name: 'Use under MIT License'
          url: 'https://github.com/markharrison/ColorsAPI/blob/master/LICENSE'
        }
        version: '3.0.1'
      }
      servers: [
        {
          url: 'https://colors-api.azurewebsites.net/'
        }
      ]
      paths: {
        '/colors': {
          get: {
            tags: [
              'Colors'
            ]
            summary: 'Get colors'
            description: 'Returns all colors.'
            operationId: 'GetColors'
            responses: {
              '200': {
                description: 'Success - returns list of colors'
                content: {
                  'text/plain': {
                    schema: {
                      type: 'array'
                      items: {
                        '$ref': '#/components/schemas/ColorsItem'
                      }
                    }
                  }
                  'application/json': {
                    schema: {
                      type: 'array'
                      items: {
                        '$ref': '#/components/schemas/ColorsItem'
                      }
                    }
                  }
                  'text/json': {
                    schema: {
                      type: 'array'
                      items: {
                        '$ref': '#/components/schemas/ColorsItem'
                      }
                    }
                  }
                }
              }
            }
          }
          post: {
            tags: [
              'Colors'
            ]
            summary: 'Update / create colors'
            description: 'Updates colors - creates color if it doesn\'t exist'
            operationId: 'UpdateColors'
            requestBody: {
              description: 'Colors to update'
              content: {
                'application/json': {
                  schema: {
                    type: 'array'
                    items: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
                'text/json': {
                  schema: {
                    type: 'array'
                    items: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
                'application/*+json': {
                  schema: {
                    type: 'array'
                    items: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
              }
              required: true
            }
            responses: {
              '201': {
                description: 'Success - colors updated/created'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
              }
              '422': {
                description: 'Unprocessable Entity'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                }
              }
            }
          }
          delete: {
            tags: [
              'Colors'
            ]
            summary: 'Delete colors'
            description: 'Deletes all colors.'
            operationId: 'DeletesColors'
            responses: {
              '204': {
                description: 'Success - all colors deleted'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
              }
            }
          }
        }
        '/colors/{colorId}': {
          get: {
            tags: [
              'Colors'
            ]
            summary: 'Get color by id'
            description: 'Returns color specified by {colorId} (must be between 1 and 1000).'
            operationId: 'GetColorById'
            parameters: [
              {
                name: 'colorId'
                in: 'path'
                description: 'Id of Color to return'
                required: true
                schema: {
                  type: 'integer'
                  format: 'int32'
                }
              }
            ]
            responses: {
              '200': {
                description: 'Success - returns color'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
              }
              '404': {
                description: 'Not Found'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                }
              }
              '422': {
                description: 'Unprocessable Entity'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                }
              }
            }
          }
          post: {
            tags: [
              'Colors'
            ]
            summary: 'Update / create color by id'
            description: 'Updates color specified by {colorId} (must be between 1 and 1000);  use {colorId} = 0 to insert new color'
            operationId: 'UpdateColorById'
            parameters: [
              {
                name: 'colorId'
                in: 'path'
                description: 'Id of Color to update'
                required: true
                schema: {
                  type: 'integer'
                  format: 'int32'
                }
              }
            ]
            requestBody: {
              description: 'Colors to update'
              content: {
                'application/json': {
                  schema: {
                    '$ref': '#/components/schemas/ColorsItem'
                  }
                }
                'text/json': {
                  schema: {
                    '$ref': '#/components/schemas/ColorsItem'
                  }
                }
                'application/*+json': {
                  schema: {
                    '$ref': '#/components/schemas/ColorsItem'
                  }
                }
              }
              required: true
            }
            responses: {
              '201': {
                description: 'Success - color created/updated'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
              }
              '422': {
                description: 'Unprocessable Entity'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                }
              }
            }
          }
          delete: {
            tags: [
              'Colors'
            ]
            summary: 'Delete color by id'
            description: 'Deletes color specified by {colorId} (must be between 1 and 1000).'
            operationId: 'DeleteColorById'
            parameters: [
              {
                name: 'colorId'
                in: 'path'
                description: 'Id of Color to delete'
                required: true
                schema: {
                  type: 'integer'
                  format: 'int32'
                }
              }
            ]
            responses: {
              '204': {
                description: 'Success - color deleted'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
              }
              '422': {
                description: 'Unprocessable Entity'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                }
              }
            }
          }
        }
        '/colors/findbyname': {
          get: {
            tags: [
              'Colors'
            ]
            summary: 'Get color by name'
            description: 'Returns color specified by {colorName} '
            operationId: 'GetColorByName'
            parameters: [
              {
                name: 'colorName'
                in: 'query'
                description: 'Name of Color to return'
                required: true
                schema: {
                  type: 'string'
                }
              }
            ]
            responses: {
              '200': {
                description: 'Success - returns color'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
              }
              '404': {
                description: 'Not Found'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                }
              }
            }
          }
        }
        '/colors/random': {
          get: {
            tags: [
              'Colors'
            ]
            summary: 'Get random color'
            description: 'Returns random color.'
            operationId: 'GetRandomColor'
            responses: {
              '200': {
                description: 'Success - returns random color'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
              }
              '404': {
                description: 'Not Found'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ProblemDetails'
                    }
                  }
                }
              }
            }
          }
        }
        '/colors/reset': {
          post: {
            tags: [
              'Colors'
            ]
            summary: 'Reset colors'
            description: 'Reset colors to default.'
            operationId: 'ResetColors'
            responses: {
              '201': {
                description: 'Success - colors reset'
                content: {
                  'text/plain': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'application/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                  'text/json': {
                    schema: {
                      '$ref': '#/components/schemas/ColorsItem'
                    }
                  }
                }
              }
            }
          }
        }
      }
      components: {
        schemas: {
          ColorsItem: {
            required: [
              'id'
              'name'
            ]
            type: 'object'
            properties: {
              id: {
                type: 'integer'
                description: 'Represents a numeric identifier for the color. It is required and must be an integer.'
                format: 'int32'
              }
              name: {
                minLength: 1
                type: 'string'
                description: 'Represents the name of the color. It is required and must be a string.'
              }
              hexcode: {
                type: 'string'
                description: 'Represents the hexadecimal code for the color. It is optional and can be an empty string.'
              }
              data: {
                type: 'string'
                description: 'Represents additional data or metadata related to the color. It is optional and can be an empty string.'
              }
            }
            additionalProperties: false
            description: 'An object representing a color with its identifier, name, hexadecimal code, and additional data.'
          }
          ProblemDetails: {
            type: 'object'
            properties: {
              type: {
                type: 'string'
                nullable: true
              }
              title: {
                type: 'string'
                nullable: true
              }
              status: {
                type: 'integer'
                format: 'int32'
                nullable: true
              }
              detail: {
                type: 'string'
                nullable: true
              }
              instance: {
                type: 'string'
                nullable: true
              }
            }
            additionalProperties: {}
          }
        }
      }
    }
  }
}

resource colorsApiSchema 'Microsoft.ApiManagement/service/apis/schemas@2024-06-01-preview' = {
  parent: colorsApi
  name: 'colorsApiSchema'
  properties: {
    contentType: 'application/vnd.oai.openapi.components+json'
    document: {}
  }
}

resource colorsApi_DeleteColorById_Colors 'Microsoft.ApiManagement/service/apis/operations/tags@2024-06-01-preview' = {
  parent: colorsApi_DeleteColorById
  name: 'Colors'
}

resource colorsApi_DeletesColors_Colors 'Microsoft.ApiManagement/service/apis/operations/tags@2024-06-01-preview' = {
  parent: colorsApi_DeletesColors
  name: 'Colors'
}

resource colorsApi_GetColorById_Colors 'Microsoft.ApiManagement/service/apis/operations/tags@2024-06-01-preview' = {
  parent: colorsApi_GetColorById
  name: 'Colors'
}

resource colorsApi_GetColorByName_Colors 'Microsoft.ApiManagement/service/apis/operations/tags@2024-06-01-preview' = {
  parent: colorsApi_GetColorBy
  name: 'Colors'
}

resource colorsApi_GetColors_Colors 'Microsoft.ApiManagement/service/apis/operations/tags@2024-06-01-preview' = {
  parent: colorsApi_GetColors
  name: 'Colors'
}

resource colorsApi_GetRandomColor_Colors 'Microsoft.ApiManagement/service/apis/operations/tags@2024-06-01-preview' = {
  parent: colorsApi_GetRandomColor
  name: 'Colors'
}

resource colorsApi_ResetColors_Colors 'Microsoft.ApiManagement/service/apis/operations/tags@2024-06-01-preview' = {
  parent: colorsApi_ResetColors
  name: 'Colors'
}

resource colorsApi_UpdateColorById_Colors 'Microsoft.ApiManagement/service/apis/operations/tags@2024-06-01-preview' = {
  parent: colorsApi_UpdateColorById
  name: 'Colors'
}

resource colorsApi_UpdateColors_Colors 'Microsoft.ApiManagement/service/apis/operations/tags@2024-06-01-preview' = {
  parent: colorsApi_UpdateColors
  name: 'Colors'
}


module productApisModule './colors-api-products.bicep' = [
  for (product, index) in (products ?? []): {
    name: 'ApimProductApis-${index}'
    params: {
      apimName: apimName
      productName: product.name
      apiName: 'colors-api'
    }
  }
]

