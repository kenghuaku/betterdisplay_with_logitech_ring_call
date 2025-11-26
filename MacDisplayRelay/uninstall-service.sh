#!/bin/bash

# MacDisplayRelay 服務卸載腳本

set -e

SERVICE_NAME="net.kenghua.macdisplayrelay"
PLIST_FILE="$SERVICE_NAME.plist"
LAUNCHD_DIR="$HOME/Library/LaunchAgents"
INSTALL_DIR="/usr/local/bin"
LOG_DIR="/usr/local/var/log/MacDisplayRelay"

# 檢查是否以 root 執行
if [ "$EUID" -eq 0 ]; then
    LAUNCHD_DIR="/Library/LaunchAgents"
    INSTALL_DIR="/usr/local/bin"
    LOG_DIR="/usr/local/var/log/MacDisplayRelay"
fi

PLIST_TARGET="$LAUNCHD_DIR/$PLIST_FILE"

echo "=== MacDisplayRelay 服務卸載 ==="
echo ""

# 1. 停止並卸載服務
if [ -f "$PLIST_TARGET" ]; then
    echo "卸載服務..."
    if launchctl list | grep -q "$SERVICE_NAME"; then
        launchctl unload "$PLIST_TARGET" 2>/dev/null || true
    fi
    rm -f "$PLIST_TARGET"
    echo "已移除 plist 檔案"
else
    echo "找不到 plist 檔案，可能已經卸載"
fi

# 2. 詢問是否刪除執行檔
read -p "是否要刪除執行檔和設定檔？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "刪除執行檔..."
    sudo rm -f "$INSTALL_DIR/MacDisplayRelay"
    sudo rm -f "$INSTALL_DIR/appsettings.json"
fi

# 3. 詢問是否刪除日誌
read -p "是否要刪除日誌檔案？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "刪除日誌檔案..."
    sudo rm -rf "$LOG_DIR"
fi

echo ""
echo "=== 卸載完成 ==="

