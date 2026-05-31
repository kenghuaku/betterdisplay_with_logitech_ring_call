@echo off
call "%~dp0_config.bat"
"%~dp0WinDisplayTrigger.exe" %MAC_IP% 15
