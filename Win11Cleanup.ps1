#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 Annoyance & Productivity Sink Cleanup Script

.DESCRIPTION
    Applies registry and system tweaks to eliminate the most common Windows 11
    distractions and UI annoyances out of the box. Designed to be run once on a
    fresh Windows 11 install.

    Fixes covered:
      1. Disables the Taskbar Widgets panel (weather/news feed)
      2. Disables Lock Screen ads and Windows Spotlight overlays
      3. Disables Search Highlights (MSN/trending content in search box)
      4. Disables Bing web results from appearing in Windows Search
      5. Disables SCOOBE ("Second Chance Out of Box Experience") nag prompts
      6. Shows file extensions in File Explorer (no more hidden .exe/.docx)
      7. Disables the Narrator keyboard shortcut (Win+Ctrl+Enter)
      8. Bonus: Disables Start menu suggested/sponsored apps and tips notifications
      9. Bonus: Shows hidden files in File Explorer

    Inspired by: https://www.theregister.com/2025/07/21/windows_11_productivity_sink/

.NOTES
    Author:     B.J. Blaker
    GitHub:     https://github.com/bjblakerpy
    Version:    1.0
    Tested On:  Windows 11 23H2 / 24H2

    REQUIREMENTS:
      - Must be run as Administrator
      - PowerShell 5.1 or later

    USAGE:
      Right-click PowerShell -> Run as Administrator, then:
        powershell -ExecutionPolicy Bypass -File Win11Cleanup.ps1

    NOTES:
      - Changes take effect immediately after Explorer restarts (script handles this)
      - The Bing search disable (#4) requires a full reboot to fully apply
      - All changes are per-user (HKCU) unless noted; safe for managed environments
      - No third-party tools or downloads required — registry only

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Win11Cleanup.ps1
#>

# ============================================================
# Helper Functions
# ============================================================

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
}

# ============================================================
# Main Script
# ============================================================

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Windows 11 Annoyance Cleanup Script v1.0" -ForegroundColor Cyan
Write-Host "  github.com/bjblakerpy" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Shared registry paths used across multiple tweaks
$cdmPath    = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$explorerAd = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# ============================================================
# 1. Disable Taskbar Widgets
# ============================================================
# The Widgets button shows weather and a feed of distracting news/promotions.
# Hovering over it opens a full panel of clickbait headlines.
# Registry: TaskbarDa = 0 removes the widget from the taskbar entirely.
Write-Host "[1/9] Disabling Taskbar Widgets..." -ForegroundColor Yellow
Set-RegistryValue -Path $explorerAd -Name "TaskbarDa" -Value 0
Write-Host "      Done." -ForegroundColor Green

# ============================================================
# 2. Disable Lock Screen Ads (Windows Spotlight)
# ============================================================
# By default, the lock screen cycles through Microsoft promotional images
# advertising Copilot, free-to-play games (e.g. Candy Crush), and other services.
# These keys disable Spotlight and its overlay tips.
Write-Host "[2/9] Disabling Lock Screen Ads and Windows Spotlight..." -ForegroundColor Yellow
Set-RegistryValue -Path $cdmPath -Name "RotatingLockScreenEnabled"              -Value 0
Set-RegistryValue -Path $cdmPath -Name "RotatingLockScreenOverlayEnabled"       -Value 0
Set-RegistryValue -Path $cdmPath -Name "SubscribedContent-338387Enabled"        -Value 0
Write-Host "      Done." -ForegroundColor Green

# ============================================================
# 3. Disable Search Highlights
# ============================================================
# When you open the search box, Windows shows trending MSN content, promoted
# apps, and sometimes casual game ads before you've even typed a character.
# IsDynamicSearchBoxEnabled = 0 turns this off.
Write-Host "[3/9] Disabling Search Highlights (MSN content in search box)..." -ForegroundColor Yellow
$searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
Set-RegistryValue -Path $searchPath -Name "IsDynamicSearchBoxEnabled" -Value 0
Write-Host "      Done." -ForegroundColor Green

# ============================================================
# 4. Disable Bing Web Results in Windows Search
# ============================================================
# Windows Search sends your keystrokes to Bing and shows web results alongside
# local file/app results, adding latency and irrelevant hits (e.g., searching
# "word" may return Wordle instead of Microsoft Word).
# This creates the Explorer policy key and disables search box suggestions.
# NOTE: Requires a reboot or Explorer restart to fully take effect.
Write-Host "[4/9] Disabling Bing Results in Windows Search..." -ForegroundColor Yellow
$explorerPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
Set-RegistryValue -Path $explorerPolicyPath -Name "DisableSearchBoxSuggestions" -Value 1
Write-Host "      Done. (Reboot required for full effect)" -ForegroundColor Green

# ============================================================
# 5. Disable SCOOBE (Second Chance Out of Box Experience)
# ============================================================
# After updates, Windows sometimes shows a "Let's finish setting up your PC"
# screen that looks like the original setup wizard. It's designed to upsell
# Xbox Game Pass, Office 365, and other Microsoft services you already declined.
# ScoobeSystemSettingEnabled = 0 prevents this from appearing.
Write-Host "[5/9] Disabling SCOOBE 'Finish setting up your PC' nag prompts..." -ForegroundColor Yellow
$scoobeProfilePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
Set-RegistryValue -Path $scoobeProfilePath -Name "ScoobeSystemSettingEnabled"   -Value 0
Set-RegistryValue -Path $cdmPath           -Name "SoftLandingEnabled"           -Value 0
Set-RegistryValue -Path $cdmPath           -Name "SubscribedContent-310093Enabled" -Value 0
Set-RegistryValue -Path $cdmPath           -Name "SubscribedContent-338388Enabled" -Value 0
Set-RegistryValue -Path $cdmPath           -Name "SubscribedContent-338389Enabled" -Value 0
Set-RegistryValue -Path $cdmPath           -Name "SubscribedContent-353694Enabled" -Value 0
Set-RegistryValue -Path $cdmPath           -Name "SubscribedContent-353696Enabled" -Value 0
Write-Host "      Done." -ForegroundColor Green

# ============================================================
# 6. Show File Extensions in File Explorer
# ============================================================
# By default, Windows hides known file extensions (e.g., you see "Report"
# instead of "Report.docx"). This makes it impossible to distinguish a .doc
# from a .docx, or spot a .exe disguised as a PDF.
# HideFileExt = 0 makes extensions always visible.
Write-Host "[6/9] Enabling File Extensions in File Explorer..." -ForegroundColor Yellow
Set-RegistryValue -Path $explorerAd -Name "HideFileExt" -Value 0
Write-Host "      Done." -ForegroundColor Green

# ============================================================
# 7. Disable Narrator Keyboard Shortcut
# ============================================================
# Win+Ctrl+Enter launches the Narrator screen reader. It's easy to hit
# accidentally, and the sudden audio output breaks concentration instantly.
# WinEnterLaunchEnabled = 0 disables this hotkey. Narrator itself is unchanged
# and can still be launched manually via Settings > Accessibility > Narrator.
Write-Host "[7/9] Disabling Narrator Keyboard Shortcut (Win+Ctrl+Enter)..." -ForegroundColor Yellow
$narratorPath = "HKCU:\Software\Microsoft\Narrator\NoRoam"
Set-RegistryValue -Path $narratorPath -Name "WinEnterLaunchEnabled" -Value 0
Write-Host "      Done." -ForegroundColor Green

# ============================================================
# 8. Disable Start Menu Suggested / Sponsored Apps
# ============================================================
# Windows silently installs "suggested" apps and shows promoted tiles in the
# Start menu. These keys disable pre-installed, OEM, and silently installed
# apps, as well as the "tips" content in the Start menu pane.
Write-Host "[8/9] Disabling Start Menu Suggested Apps and Tips Notifications..." -ForegroundColor Yellow
Set-RegistryValue -Path $cdmPath -Name "SubscribedContent-338393Enabled" -Value 0  # Tips notifications
Set-RegistryValue -Path $cdmPath -Name "SystemPaneSuggestionsEnabled"    -Value 0  # Start menu suggestions
Set-RegistryValue -Path $cdmPath -Name "OemPreInstalledAppsEnabled"       -Value 0  # OEM bloatware
Set-RegistryValue -Path $cdmPath -Name "PreInstalledAppsEnabled"          -Value 0  # Pre-installed app promos
Set-RegistryValue -Path $cdmPath -Name "SilentInstalledAppsEnabled"       -Value 0  # Silent background installs
Write-Host "      Done." -ForegroundColor Green

# ============================================================
# 9. Show Hidden Files and Folders in File Explorer
# ============================================================
# Hidden files are invisible by default, which makes troubleshooting and
# navigating app data folders unnecessarily difficult for power users.
# Hidden = 1 makes all hidden files and folders visible.
Write-Host "[9/9] Showing Hidden Files and Folders in File Explorer..." -ForegroundColor Yellow
Set-RegistryValue -Path $explorerAd -Name "Hidden" -Value 1
Write-Host "      Done." -ForegroundColor Green

# ============================================================
# Restart Explorer to Apply Changes
# ============================================================
Write-Host ""
Write-Host "Restarting Windows Explorer to apply changes..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer

# ============================================================
# Summary
# ============================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  All done! Summary of changes applied:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  [x] Taskbar Widgets disabled" -ForegroundColor Green
Write-Host "  [x] Lock screen ads / Windows Spotlight disabled" -ForegroundColor Green
Write-Host "  [x] Search Highlights (MSN content) disabled" -ForegroundColor Green
Write-Host "  [x] Bing results in Windows Search disabled *" -ForegroundColor Green
Write-Host "  [x] SCOOBE setup nag prompts disabled" -ForegroundColor Green
Write-Host "  [x] File extensions now visible in Explorer" -ForegroundColor Green
Write-Host "  [x] Narrator keyboard shortcut disabled" -ForegroundColor Green
Write-Host "  [x] Start menu suggested/sponsored apps disabled" -ForegroundColor Green
Write-Host "  [x] Hidden files now visible in Explorer" -ForegroundColor Green
Write-Host ""
Write-Host "  * Reboot recommended for Bing search change to fully apply." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Source: https://github.com/bjblakerpy" -ForegroundColor DarkGray
Write-Host "  Inspired by: theregister.com/2025/07/21/windows_11_productivity_sink/" -ForegroundColor DarkGray
Write-Host ""
