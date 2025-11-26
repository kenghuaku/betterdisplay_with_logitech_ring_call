using System.Diagnostics;
using System.Net;
using System.Net.Sockets;

var builder = WebApplication.CreateBuilder(args);

// 從 appsettings.json 讀取 Port 設定，預設值為 11112
var port = builder.Configuration.GetValue<int>("Server:Port", 11112);

// 設定 Kestrel 監聽指定 Port，綁定所有 IP
builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(port);
});

var app = builder.Build();

// 從設定檔讀取 BetterDisplay 設定
var betterDisplayCliPath = builder.Configuration.GetValue<string>("BetterDisplay:CliPath", "/opt/homebrew/bin/betterdisplaycli");
var displayName = builder.Configuration.GetValue<string>("BetterDisplay:DisplayName", "MPG322UX OLED");

// 切換螢幕輸入源的路由
app.MapGet("/switch/{inputCode:int}", async (int inputCode) =>
{
    var processStartInfo = new ProcessStartInfo
    {
        FileName = betterDisplayCliPath,
        Arguments = $"set -n=\"{displayName}\" -ddc={inputCode} -vcp=inputSelect",
        RedirectStandardOutput = true,
        RedirectStandardError = true,
        UseShellExecute = false,
        CreateNoWindow = true
    };

    try
    {
        using var process = new Process { StartInfo = processStartInfo };
        process.Start();

        var output = await process.StandardOutput.ReadToEndAsync();
        var error = await process.StandardError.ReadToEndAsync();
        await process.WaitForExitAsync();

        if (process.ExitCode != 0)
        {
            return Results.Problem(
                detail: $"betterdisplaycli 執行失敗 (ExitCode: {process.ExitCode})\n錯誤訊息: {error}\n輸出: {output}",
                statusCode: 500
            );
        }

        return Results.Ok(new
        {
            success = true,
            inputCode,
            message = "螢幕輸入源切換成功",
            output = output.Trim()
        });
    }
    catch (Exception ex)
    {
        return Results.Problem(
            detail: $"執行 betterdisplaycli 時發生例外: {ex.Message}",
            statusCode: 500
        );
    }
})
.WithName("SwitchDisplayInput")
.WithOpenApi();

try
{
    app.Run();
}
catch (SocketException ex) when (ex.SocketErrorCode == SocketError.AddressAlreadyInUse)
{
    Console.Error.WriteLine($"錯誤: Port {port} 已被使用，請檢查是否有其他程式正在使用此 Port。");
    Environment.Exit(1);
}
catch (IOException ex) when (ex.Message.Contains("address already in use", StringComparison.OrdinalIgnoreCase))
{
    Console.Error.WriteLine($"錯誤: Port {port} 已被使用，請檢查是否有其他程式正在使用此 Port。");
    Environment.Exit(1);
}
catch (Exception ex)
{
    Console.Error.WriteLine($"錯誤: 無法啟動服務 - {ex.Message}");
    Environment.Exit(1);
}
