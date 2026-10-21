<#
.VERSION 1.0.2
#>
# OBJECTIVE: Show a plain PowerShell output style without color.

#Requires -Version 5.1

# theme-plain.ps1
# MSSP Field Kit -- Plain terminal theme.
# No ANSI color, no host appearance settings.
# Compatible with any PowerShell 5.1+ environment including jumpboxes,
# remote sessions, and terminals without ANSI support.
# Copy the function block into any script that needs plain output.

# ============================================================
# WRITE HELPERS
# ============================================================


Write-Host 'Preview Plain Output'
Write-Host 'Show a plain PowerShell output style without color.'
function Write-Dots  { Write-Host "........................................" }
function Write-Ok    { param($Msg) Write-Host "[OK]  $Msg" }
function Write-Info  { param($Msg) Write-Host "[--]  $Msg" }
function Write-Warn  { param($Msg) Write-Host "[!!]  $Msg" }
function Write-Fail  { param($Msg) Write-Host "[XX]  $Msg" }
function Write-Step  { param($Msg) Write-Host "[$(Get-Date -Format 'HH:mm:ss')]  $Msg" }
function Write-Field {
    param($Label, $Value, $Color='')
    Write-Host ("{0,-22} :  {1}" -f $Label, $Value)
}

# ============================================================
# USAGE EXAMPLE
# ============================================================

$Operator = "$env:USERDOMAIN\$env:USERNAME"

Write-Dots
Write-Host "SCRIPT TITLE  --  $Operator"
Write-Dots
Write-Host ""
Write-Ok    "Connected successfully"
Write-Info  "Processing 42 items..."
Write-Warn  "3 items need review"
Write-Fail  "1 item failed"
Write-Step  "Connecting to Exchange Online..."
Write-Field "Operator"    $Operator
Write-Field "Status"      "Complete"
Write-Field "Output"      "C:\Example\output.csv"
Write-Host ""
Write-Dots
Write-Host ""
Write-Host "MISSION ACCOMPLISHED. Goodbye."
Write-Host ""
Read-Host 'Press Enter to close session.'
