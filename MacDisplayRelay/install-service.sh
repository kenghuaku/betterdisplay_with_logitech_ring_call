#!/bin/bash

# MacDisplayRelay 服務安裝腳本
# 此腳本會將 MacDisplayRelay 安裝為 macOS 開機自動啟動的服務

set -e

SERVICE_NAME="net.kenghua.macdisplayrelay"
PLIST_FILE="$SERVICE_NAME.plist"
LAUNCHD_DIR="$HOME/Library/LaunchAgents"
INSTALL_DIR="/usr/local/bin"
LOG_DIR="/usr/local/var/log/MacDisplayRelay"

# 檢查是否以 root 執行（安裝到系統目錄時需要）
if [ "$EUID" -eq 0 ]; then
    LAUNCHD_DIR="/Library/LaunchAgents"
    INSTALL_DIR="/usr/local/bin"
    LOG_DIR="/usr/local/var/log/MacDisplayRelay"
fi

echo "=== MacDisplayRelay 服務安裝 ==="
echo ""

# 1. 檢查發行版本是否存在
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBLISH_DIR="$SCRIPT_DIR/bin/Release/net8.0/osx-$(uname -m)/publish"

if [ ! -f "$PUBLISH_DIR/MacDisplayRelay" ]; then
    echo "錯誤: 找不到發行版本"
    echo "請先執行發行指令："
    echo "  cd MacDisplayRelay"
    echo "  dotnet publish -c Release -r osx-$(uname -m) -p:PublishSingleFile=true -p:SelfContained=true"
    exit 1
fi

# 2. 建立必要的目錄
echo "建立目錄..."
sudo mkdir -p "$INSTALL_DIR"
sudo mkdir -p "$LOG_DIR"

# 3. 複製執行檔
echo "複製執行檔到 $INSTALL_DIR..."
sudo cp "$PUBLISH_DIR/MacDisplayRelay" "$INSTALL_DIR/"
sudo chmod +x "$INSTALL_DIR/MacDisplayRelay"

# 4. 複製設定檔（如果存在）
if [ -f "$PUBLISH_DIR/appsettings.json" ]; then
    echo "複製設定檔..."
    sudo cp "$PUBLISH_DIR/appsettings.json" "$INSTALL_DIR/"
fi

# 5. 修改 plist 檔案中的路徑（如果需要）
PLIST_SOURCE="$SCRIPT_DIR/$PLIST_FILE"
PLIST_TARGET="$LAUNCHD_DIR/$PLIST_FILE"

# 如果 plist 中的路徑與實際安裝路徑不同，需要更新
if [ "$INSTALL_DIR" != "/usr/local/bin" ]; then
    echo "更新 plist 檔案中的路徑..."
    sed "s|/usr/local/bin/MacDisplayRelay|$INSTALL_DIR/MacDisplayRelay|g" "$PLIST_SOURCE" > "/tmp/$PLIST_FILE"
    PLIST_SOURCE="/tmp/$PLIST_FILE"
fi

# 6. 複製 plist 檔案
echo "安裝 launchd plist 檔案..."
mkdir -p "$LAUNCHD_DIR"
cp "$PLIST_SOURCE" "$PLIST_TARGET"

# 7. 載入服務
echo "載入服務..."
if launchctl list | grep -q "$SERVICE_NAME"; then
    echo "服務已存在，先卸載..."
    launchctl unload "$PLIST_TARGET" 2>/dev/null || true
fi

launchctl load "$PLIST_TARGET"

echo ""
echo "=== 安裝完成 ==="
echo ""
echo "服務已安裝並啟動。"
echo ""
echo "管理指令："
echo "  啟動服務: launchctl start $SERVICE_NAME"
echo "  停止服務: launchctl stop $SERVICE_NAME"
echo "  重新載入: launchctl unload $PLIST_TARGET && launchctl load $PLIST_TARGET"
echo "  查看狀態: launchctl list | grep $SERVICE_NAME"
echo "  查看日誌: tail -f $LOG_DIR/stdout.log"
echo "  查看錯誤: tail -f $LOG_DIR/stderr.log"
echo ""
echo "服務會在開機時自動啟動。"

