using System.Net;
using Microsoft.Extensions.Configuration;

// 載入設定檔
var configuration = new ConfigurationBuilder()
    .SetBasePath(AppContext.BaseDirectory)
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
    .Build();

// 從設定檔讀取 Port 和 Timeout，預設值分別為 11112 和 5 秒
var port = configuration.GetValue<int>("Client:Port", 11112);
var timeoutSeconds = configuration.GetValue<int>("Client:TimeoutSeconds", 5);
var defaultTargetIp = configuration.GetValue<string>("Client:DefaultTargetIp", "");

// 參數處理：如果只提供一個參數（InputCode），則使用設定檔中的預設 IP
string targetIp;
string inputCodeStr;

if (args.Length == 1)
{
    if (string.IsNullOrWhiteSpace(defaultTargetIp))
    {
        Console.WriteLine("錯誤: 請提供 TargetIp 參數，或在 appsettings.json 中設定 DefaultTargetIp");
        Console.WriteLine("用法: WinDisplayTrigger <TargetIp> <InputCode>");
        Console.WriteLine("  或: WinDisplayTrigger <InputCode> (需在 appsettings.json 設定 DefaultTargetIp)");
        Console.WriteLine("範例: WinDisplayTrigger 192.168.1.100 15");
        Environment.Exit(1);
        return; // 永遠不會執行，但讓編譯器知道
    }
    targetIp = defaultTargetIp;
    inputCodeStr = args[0];
}
else if (args.Length == 2)
{
    targetIp = args[0];
    inputCodeStr = args[1];
}
else
{
    Console.WriteLine("錯誤: 請提供參數");
    Console.WriteLine("用法: WinDisplayTrigger <TargetIp> <InputCode>");
    Console.WriteLine("  或: WinDisplayTrigger <InputCode> (需在 appsettings.json 設定 DefaultTargetIp)");
    Console.WriteLine("範例: WinDisplayTrigger 192.168.1.100 15");
    Environment.Exit(1);
    return; // 永遠不會執行，但讓編譯器知道
}

if (!int.TryParse(inputCodeStr, out var inputCode))
{
    Console.WriteLine($"錯誤: InputCode 必須是整數，收到: {inputCodeStr}");
    Environment.Exit(1);
}

var url = $"http://{targetIp}:{port}/switch/{inputCode}";

using var httpClient = new HttpClient
{
    Timeout = TimeSpan.FromSeconds(timeoutSeconds)
};

try
{
    Console.WriteLine($"正在呼叫: {url}");
    var response = await httpClient.GetAsync(url);
    var content = await response.Content.ReadAsStringAsync();

    if (response.IsSuccessStatusCode)
    {
        Console.WriteLine("✓ 成功: 螢幕輸入源已切換");
        if (!string.IsNullOrWhiteSpace(content))
        {
            Console.WriteLine($"回應內容: {content}");
        }
    }
    else
    {
        Console.WriteLine($"✗ 錯誤: HTTP {response.StatusCode}");
        Console.WriteLine($"錯誤訊息: {content}");
        Environment.Exit(1);
    }
}
catch (TaskCanceledException)
{
    Console.WriteLine($"✗ 錯誤: 請求逾時 (超過 {timeoutSeconds} 秒)");
    Environment.Exit(1);
}
catch (HttpRequestException ex)
{
    Console.WriteLine($"✗ 錯誤: 無法連接到 Mac Mini ({targetIp}:{port})");
    Console.WriteLine($"詳細訊息: {ex.Message}");
    Environment.Exit(1);
}
catch (Exception ex)
{
    Console.WriteLine($"✗ 錯誤: {ex.Message}");
    Environment.Exit(1);
}
