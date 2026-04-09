param apimName string
param openAiEndpoint string
param languageEndpoint string
@secure()
param languageKey string

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimName
}

resource langKey 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = {
  parent: apim
  name: 'language-key'
  properties: {
    displayName: 'language-key'
    value: languageKey
    secret: true
  }
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

// Vi bygger policyn helt utan farliga tecken i attributen
var policyXml = '''
<policies>
    <inbound>
        <base />
        <cors allow-credentials="false">
            <allowed-origins><origin>*</origin></allowed-origins>
            <allowed-methods><method>POST</method><method>OPTIONS</method></allowed-methods>
            <allowed-headers><header>*</header></allowed-headers>
        </cors>
        
        <set-variable name="originalBody" value="@(context.Request.Body.As<string>(true))" />

        <send-request mode="new" response-variable-name="piiResponse" timeout="20" ignore-error="true">
            <set-url>TOKEN_URLlanguage/:analyze-text?api-version=2023-04-01</set-url>
            <set-method>POST</set-method>
            <set-header name="Content-Type" exists-action="override"><value>application/json</value></set-header>
            <set-header name="Ocp-Apim-Subscription-Key" exists-action="override"><value>{{language-key}}</value></set-header>
            <set-body><![CDATA[@{
                var bodyStr = (string)context.Variables["originalBody"];
                var bodyJson = Newtonsoft.Json.Linq.JObject.Parse(bodyStr);
                
                var textToAnalyze = bodyStr;
                if (bodyJson["messages"] != null) {
                    textToAnalyze = bodyJson["messages"].Last["content"].ToString();
                }

                return Newtonsoft.Json.JsonConvert.SerializeObject(new {
                    kind = "PiiEntityRecognition",
                    parameters = new { modelVersion = "latest" },
                    analysisInput = new { documents = new [] { new { id = "1", language = "sv", text = textToAnalyze } } }
                });
            }]]></set-body>
        </send-request>

        <set-body><![CDATA[@{
            var response = (IResponse)context.Variables["piiResponse"];
            var originalBodyStr = (string)context.Variables["originalBody"];
            
            if (response != null && response.StatusCode == 200) {
                var piiResult = response.Body.As<Newtonsoft.Json.Linq.JObject>();
                var redactedText = piiResult.SelectToken("results.documents[0].redactedText")?.ToString();
                
                if (!string.IsNullOrEmpty(redactedText)) {
                    var finalBody = Newtonsoft.Json.Linq.JObject.Parse(originalBodyStr);
                    if (finalBody["messages"] != null) {
                        finalBody["messages"].Last()["content"] = redactedText;
                        return finalBody.ToString();
                    }
                }
            }
            return originalBodyStr;
        }]]></set-body>
        
        <authentication-managed-identity resource="https://cognitiveservices.azure.com" />
    </inbound>
    <backend><base /></backend>
    <outbound><base /></outbound>
</policies>
'''

resource apiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: aiApi
  name: 'policy'
  properties: {
    format: 'xml'
    // Vi ser till att TOKEN_URL/language blir en perfekt adress
    value: replace(replace(replace(policyXml, 'TOKEN_URL', '${languageEndpoint}/'), '<string>', '&lt;string&gt;'), '<Newtonsoft.Json.Linq.JObject>', '&lt;Newtonsoft.Json.Linq.JObject&gt;')
  }
  dependsOn: [ langKey, wildcardOperation ]
}
