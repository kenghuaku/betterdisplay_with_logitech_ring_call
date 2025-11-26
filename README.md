# BetterDisplay KVM 切換方案

這是一個自製的 KVM 切換機制，透過區域網路控制 Mac 上的 BetterDisplay 軟體來切換螢幕輸入源。

## 專案結構

- **MacDisplayRelay** - Mac 端中繼服務（ASP.NET Core Web API）
- **WinDisplayTrigger** - Windows 端呼叫程式（Console Application）

## 功能說明

### MacDisplayRelay

- 監聽 Port 11112，綁定所有 IP 位址
- 提供 REST API：`GET /switch/{inputCode}`
- 執行 `betterdisplaycli` 指令切換螢幕輸入源
- 錯誤處理與回應

### WinDisplayTrigger

- CLI 工具，接收 Mac IP 和輸入源代碼
- 透過 HTTP 請求呼叫 Mac 端服務
- 5 秒超時設定
- 顯示執行結果

## 使用方式

### 在 Mac 上啟動服務

```bash
cd MacDisplayRelay
dotnet run
```

服務將在 `http://0.0.0.0:11112` 上啟動。

### 在 Windows 上呼叫

```bash
WinDisplayTrigger.exe <TargetIp> <InputCode>
```

或（如果已在 `appsettings.json` 設定 `DefaultTargetIp`）：

```bash
WinDisplayTrigger.exe <InputCode>
```

**範例：**

```bash
WinDisplayTrigger.exe 192.168.1.100 15
WinDisplayTrigger.exe 192.168.1.100 17
WinDisplayTrigger.exe 15  # 使用設定檔中的預設 IP
```

**設定檔說明：**

Windows 端的設定檔 `WinDisplayTrigger/appsettings.json` 包含以下設定：

- `Client:Port` - Mac 端服務的 Port（預設：11112）
- `Client:TimeoutSeconds` - HTTP 請求超時時間（預設：5 秒）
- `Client:DefaultTargetIp` - 預設的 Mac IP 位址（可選，設定後可省略命令列的第一個參數）

## 發行指令

### Mac 端發行（MacDisplayRelay）

#### Apple Silicon (M1/M2/M3) Mac

```bash
cd MacDisplayRelay
dotnet publish -c Release -r osx-arm64 -p:PublishSingleFile=true -p:SelfContained=true
```

#### Intel Mac

```bash
cd MacDisplayRelay
dotnet publish -c Release -r osx-x64 -p:PublishSingleFile=true -p:SelfContained=true
```

發行檔案位於：`MacDisplayRelay/bin/Release/net8.0/osx-{arch}/publish/MacDisplayRelay`

**執行發行版本：**

```bash
./bin/Release/net8.0/osx-{arch}/publish/MacDisplayRelay
```

### 設定開機自動執行（macOS 服務）

MacDisplayRelay 可以設定為 macOS 系統服務，在開機時自動啟動並在背景執行。

#### 安裝服務

1. **發行應用程式**（如果還沒發行）：

```bash
cd MacDisplayRelay
dotnet publish -c Release -r osx-$(uname -m) -p:PublishSingleFile=true -p:SelfContained=true
```

2. **執行安裝腳本**：

```bash
cd MacDisplayRelay
./install-service.sh
```

安裝腳本會：

- 將執行檔複製到 `/usr/local/bin/`
- 安裝 launchd plist 檔案到 `~/Library/LaunchAgents/`
- 自動啟動服務
- 設定日誌檔案位置

#### 管理服務

```bash
# 啟動服務
launchctl start net.kenghua.macdisplayrelay

# 停止服務
launchctl stop net.kenghua.macdisplayrelay

# 重新載入服務（修改設定後）
launchctl unload ~/Library/LaunchAgents/net.kenghua.macdisplayrelay.plist
launchctl load ~/Library/LaunchAgents/net.kenghua.macdisplayrelay.plist

# 查看服務狀態
launchctl list | grep net.kenghua.macdisplayrelay

# 查看日誌
tail -f ~/Library/Logs/MacDisplayRelay/stdout.log
tail -f ~/Library/Logs/MacDisplayRelay/stderr.log
```

#### 卸載服務

```bash
cd MacDisplayRelay
./uninstall-service.sh
```

#### 手動安裝（不使用腳本）

如果您想手動安裝，可以：

1. 複製執行檔到 `/usr/local/bin/`：

```bash
sudo cp bin/Release/net8.0/osx-$(uname -m)/publish/MacDisplayRelay /usr/local/bin/
sudo cp bin/Release/net8.0/osx-$(uname -m)/publish/appsettings.json /usr/local/bin/
```

2. 複製 plist 檔案到 LaunchAgents：

```bash
cp net.kenghua.macdisplayrelay.plist ~/Library/LaunchAgents/
```

3. 修改 plist 檔案中的路徑（如果需要）：
   編輯 `~/Library/LaunchAgents/net.kenghua.macdisplayrelay.plist`，確認 `ProgramArguments` 中的路徑正確。

4. 載入服務：

```bash
launchctl load ~/Library/LaunchAgents/net.kenghua.macdisplayrelay.plist
```

### Windows 端發行（WinDisplayTrigger）

#### 發行為 x64 單一執行檔（需要系統安裝 .NET Runtime）

```bash
cd WinDisplayTrigger
dotnet publish -c Release -r win-x64 -p:PublishSingleFile=true -p:SelfContained=false
```

#### 發行為 x64 自包含執行檔（不需要 .NET Runtime）

```bash
cd WinDisplayTrigger
dotnet publish -c Release -r win-x64 -p:PublishSingleFile=true -p:SelfContained=true
```

發行檔案位於：`WinDisplayTrigger/bin/Release/net8.0/win-x64/publish/WinDisplayTrigger.exe`

**建議使用自包含版本**（`SelfContained=true`），因為 Windows 端可能沒有安裝 .NET Runtime。

**注意：** 發行時請確保 `appsettings.json` 檔案會一併複製到發行目錄（已在 `.csproj` 中設定）。

## 系統需求

### Mac 端

- macOS
- .NET 8.0 Runtime（開發時）或自包含發行版本
- BetterDisplay 軟體
- `betterdisplaycli` 位於 `/opt/homebrew/bin/betterdisplaycli`

### Windows 端

- Windows（x86 架構）
- .NET 8.0 Runtime（如果使用 `SelfContained=false`）或自包含發行版本

## API 端點

### GET /switch/{inputCode}

切換螢幕輸入源。

**參數：**

- `inputCode` (int) - 輸入源代碼（例如：15, 17）

**成功回應（200）：**

```json
{
  "success": true,
  "inputCode": 15,
  "message": "螢幕輸入源切換成功",
  "output": "..."
}
```

**錯誤回應（500）：**

```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.6.1",
  "title": "An error occurred while processing your request.",
  "status": 500,
  "detail": "betterdisplaycli 執行失敗 (ExitCode: 1)\n錯誤訊息: ..."
}
```

## 注意事項

1. 確保 Mac 和 Windows PC 在同一區域網路內
2. Mac 防火牆需允許 Port 11112 的連入連線（可在 `appsettings.json` 中修改 Port）
3. 伺服器 Port 可在 `MacDisplayRelay/appsettings.json` 的 `Server:Port` 設定中調整，預設值為 11112
4. Windows 端的 Port、Timeout 和預設 IP 可在 `WinDisplayTrigger/appsettings.json` 的 `Client` 區段中調整
5. `betterdisplaycli` 的路徑和顯示器名稱（"MPG322UX OLED"）可在 `MacDisplayRelay/Program.cs` 中修改
6. 輸入源代碼需根據您的顯示器規格設定（常見值：15=HDMI1, 17=HDMI2, 18=DP, 27=Type-C）
7. 若修改了 Mac 端的 Port，請同步更新 Windows 端的 `appsettings.json` 中的 `Client:Port` 設定

## 開發

### 建置解決方案

```bash
dotnet build BetterDisplayKVM.sln
```

### 執行測試

```bash
# Mac 端
cd MacDisplayRelay
dotnet run

# Windows 端（在另一個終端）
cd WinDisplayTrigger
dotnet run 192.168.1.100 15
```
