using Azure;
using Azure.AI.Inference;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly ChatCompletionsClient _client;
        private readonly string _deployment;

        public ChatService(IConfiguration config)
        {
            var endpoint = new Uri(config["AZURE_AI_ENDPOINT"]!);
            _deployment = config["AZURE_PHI_DEPLOYMENT_NAME"]!;
            _client = new ChatCompletionsClient(endpoint, new AzureKeyCredential("placeholder"),
                new AzureAIInferenceClientOptions());
        }

        public async Task<string> SendAsync(string userMessage)
        {
            var options = new ChatCompletionsOptions
            {
                Model = _deployment,
                Messages = { new ChatRequestUserMessage(userMessage) }
            };
            var response = await _client.CompleteAsync(options);
            return response.Value.Content;
        }
    }
}
