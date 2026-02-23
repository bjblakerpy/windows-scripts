<#
.SYNOPSIS
    Automatically updates all installed applications managed by WinGet.

.DESCRIPTION
    WingetUpdate.ps1 runs a silent upgrade of all WinGet-managed applications on
    the local machine. It is designed to be executed unattended via Windows Task
    Scheduler. Each run produces a dated log file so you can audit what was updated
    and catch any errors without being present at the machine.

    Key behaviors:
      - Accepts all source and package agreements automatically (no prompts)
      - Runs silently to suppress installer UI where supported
      - Logs all output (including winget's own output) to a dated log file
      - Exits with a non-zero code on failure so Task Scheduler can detect problems

.PARAMETER (none)
    This script takes no parameters. Configuration is handled via the variables
    at the top of the script body.

.OUTPUTS
    Log file written to: C:\Scripts\Logs\WingetUpdate\YYYY-MM-DD.log

.NOTES
    Author:       B.J.
    Version:      1.0
    Requires:     Windows 10/11 with WinGet (App Installer) installed
    Run As:       Administrator (required for system-level app updates)
    Execution:    powershell.exe -ExecutionPolicy Bypass -NonInteractive -File "C:\Scripts\WingetUpdate.ps1"

.EXAMPLE
    Run manually from an elevated PowerShell prompt:
        .\WingetUpdate.ps1

    Run via Task Scheduler action:
        Program:   powershell.exe
        Arguments: -ExecutionPolicy Bypass -NonInteractive -File "C:\Scripts\WingetUpdate.ps1"
#>

# ============================================================
# CONFIGURATION
# Adjust these paths if you want logs stored elsewhere.
# ============================================================

# Root folder for log files
$LogPath = "C:\Scripts\Logs\WingetUpdate"

# Log file named after today's date (one file per day)
$LogFile = "$LogPath\$(Get-Date -Format 'yyyy-MM-dd').log"


# ============================================================
# FUNCTIONS
# ============================================================

function Write-Log {
    <#
    .SYNOPSIS
        Writes a timestamped message to both the console and the log file.
    .PARAMETER Message
        The message string to log.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $Entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Output $Entry
    Add-Content -Path $LogFile -Value $Entry
}


# ============================================================
# MAIN
# ============================================================

# Ensure the log directory exists before we try to write to it
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

Write-Log "=== WinGet Update Started ==="
Write-Log "Running as user: $env:USERNAME on host: $env:COMPUTERNAME"

# Verify winget is available on this machine before proceeding.
# WinGet ships with Windows 10 1709+ via the App Installer package.
# If it's missing, the script exits cleanly with an error code.
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Log "ERROR: winget executable not found. Ensure 'App Installer' is installed from the Microsoft Store."
    exit 1
}

# Log the installed winget version for troubleshooting purposes
$WingetVersion = (winget --version) 2>&1
Write-Log "WinGet version: $WingetVersion"

# Run the upgrade
# Flags explained:
#   --all                        : Upgrade every package that has an available update
#   --accept-source-agreements   : Auto-accept any source/repository license agreements
#   --accept-package-agreements  : Auto-accept any per-package license agreements
#   --silent                     : Request silent/minimal installer UI (not all apps honor this)
#   2>&1                         : Merge stderr into stdout so we capture everything in the log
try {
    Write-Log "Running: winget upgrade --all --accept-source-agreements --accept-package-agreements --silent"
    $Output = winget upgrade --all --accept-source-agreements --accept-package-agreements --silent 2>&1

    # Write each line of winget's output into the log file
    $Output | ForEach-Object { Write-Log $_ }

    Write-Log "winget upgrade command completed."
} catch {
    Write-Log "ERROR: An exception was thrown during upgrade: $($_.Exception.Message)"
    exit 1
}

Write-Log "=== WinGet Update Finished ==="

# Exit 0 signals success to Task Scheduler
exit 0
