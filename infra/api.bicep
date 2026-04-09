param apimName string
param openAiEndpoint string

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimName
}

resource aiApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apim
  name: 'openai-api'
  properties: {
    displayName: 'Enterprise OpenAI Gateway'
    path: 'openai'
    protocols: [ 'https' ]
    serviceUrl: openAiEndpoint
  }
}

resource wildcardOperation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: aiApi
  name: 'wildcard'
  properties: {
    displayName: 'All Requests'
    method: 'POST'
    urlTemplate: '/*' 
  }
}

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: aiApi
  name: 'policy'
  properties: {
    format: 'xml'
    value: '''
<policies>
    <inbound>
        <base />
        <cors allow-credentials="false">
            <allowed-origins>
                <origin>*</origin> </allowed-origins>
            <allowed-methods>
                <method>POST</method>
                <method>OPTIONS</method>
            </allowed-methods>
            <allowed-headers>
                <header>*</header>
            </allowed-headers>
        </cors>

        <find-and-replace from="\\b\\d{6,8}-\\d{4}\\b" to="[MASKED-PII]" />
        <authentication-managed-identity resource="https://cognitiveservices.azure.com" />
        
        <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" downstream-caching-type="none">
            <vary-by-header>Content-Type</vary-by-header>
        </cache-lookup>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <cache-store duration="3600" />
    </outbound>
</policies>
'''
  }
}
