using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using System.Net.Http;
using System.Text.Json;

namespace functions
{
    public class GetGithubActionIps
    {
        [FunctionName("GetGithubActionIps")]
        public void Run([TimerTrigger("0 */5 * * * *")]TimerInfo myTimer, ILogger log)
        {
            log.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
            var ips = GetIps();
            
        }

        // Http client to retrieve GitHub Actions IP from https://api.github.com/meta
        static async Task<Object> GetIps()
        {
            try
            {
                HttpResponseMessage response = await new HttpClient().GetAsync("https://api.github.com/meta");
                response.EnsureSuccessStatusCode();
                string responseBody = await response.Content.ReadAsStringAsync();
                return responseBody;
            }
            catch (HttpRequestException e)
            {
                // Return e.Message as JSON
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true
                };
                return e;
                throw;
            }
        }
    }
}
