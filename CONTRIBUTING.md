# 參與貢獻指南

感謝你願意一起改善這個 **BetterDisplay × Logitech Action Ring 進階 KVM** 專案！不論是回報問題、補充文件，或送出程式碼，都非常歡迎。

## 專案結構

| 路徑 | 說明 |
| --- | --- |
| `MacDisplayRelay/` | Mac 端常駐服務（ASP.NET Core Minimal API） |
| `WinDisplayTrigger/` | Windows 端呼叫程式（.NET Console）與 `.bat` 觸發檔 |
| `SwitchDisplay_*.app/` | Mac 本機 Automator 觸發 App |
| `Logi_ring.lp5` | Logitech Options+ Action Ring 設定檔範本 |

## 開發環境

- [.NET 8.0 SDK](https://dotnet.microsoft.com/download)（本專案 Target Framework 為 `net8.0`，較新版 SDK 亦可建置）
- macOS 端需安裝 [BetterDisplay](https://github.com/waydabber/BetterDisplay) 與 `betterdisplaycli`

建置與本機驗證：

```bash
# 建置整個方案
dotnet build BetterDisplayKVM.sln

# 啟動 Mac 端服務
cd MacDisplayRelay && dotnet run

# 另開終端，從 Windows 端（或本機 curl）測試
curl http://<MacIP>:11112/switch/15
```

## 回報問題（Issue）

開 Issue 時，請盡量附上：

- **顯示器型號**與你使用的 **DDC 代碼**
- 作業系統與版本（macOS / Windows）
- `betterdisplaycli get -identifiers` 的輸出（顯示器名稱）
- 錯誤訊息或 `~/Library/Logs/MacDisplayRelay/stderr.log` 的相關日誌

## 送出 Pull Request

1. Fork 本專案並建立分支：`git checkout -b feat/your-feature`
2. 提交變更，commit message 請遵循 [Conventional Commits](https://www.conventionalcommits.org/)：
   - `feat:` 新功能、`fix:` 修正、`docs:` 文件、`refactor:` 重構、`chore:` 雜項
3. 推送分支並開 PR，說明動機與測試方式。

## 程式風格

- C# 採 .NET 8 慣例，優先使用 Early Return、明確型別。
- 只做必要改動，避免順手重構無關程式碼。
- 註解說明「為什麼」與非顯而易見的取捨，而非重述程式碼。

## 特別歡迎的貢獻

- 📺 **其他顯示器的 DDC 輸入源代碼對照**（補進 README 對照表）。
- 🎛️ **其他周邊**（Stream Deck、其他巨集鍵盤）的觸發設定範例。
- 🌐 **文件翻譯與校對**（特別是英文），讓更多人能參與。
- 🧰 安裝／發行流程的改善與跨平台相容性。

再次感謝你的參與！
