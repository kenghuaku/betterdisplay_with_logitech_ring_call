#!/bin/bash
# BetterDisplay 螢幕輸入源切換 — 通用範例腳本（Mac 本機執行）
#
# 用法:
#   ./switch_pc.sh <DDC代碼>
#
# 顯示器名稱與 CLI 路徑可用環境變數覆寫，免改腳本即可換環境：
#   BD_DISPLAY="你的顯示器名稱"   （預設 "MPG322UX OLED"）
#   BD_CLI="/opt/homebrew/bin/betterdisplaycli"   （Intel Mac 多為 /usr/local/bin/...）
#
# 範例（對送記錄）:
#   ./switch_pc.sh 15                      # 切到 DisplayPort
#   ./switch_pc.sh 16                      # 切到 USB-C / Type-C
#   ./switch_pc.sh 17                      # 切到 HDMI1
#   BD_DISPLAY="DELL U2723QE" ./switch_pc.sh 17   # 換一台顯示器

set -euo pipefail

DISPLAY_NAME="${BD_DISPLAY:-MPG322UX OLED}"
CLI="${BD_CLI:-/opt/homebrew/bin/betterdisplaycli}"
CODE="${1:?用法: $0 <DDC代碼>，例如 $0 15}"

"$CLI" set -n="$DISPLAY_NAME" -ddc="$CODE" -vcp=inputSelect
