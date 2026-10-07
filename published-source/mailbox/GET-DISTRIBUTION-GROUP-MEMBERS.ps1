<#
MULTI DISTRO MEMBERS LOOKUP

OBJECTIVE
Look up members of one Exchange Online distribution group.

CHANGES
Read-only. No changes are made.

RUN
Right-click > Run with PowerShell
or
Right-click > Run with PowerShell 7
#>

param(
    [string]$DistributionGroup
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function Write-OK   { param($m) Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "[INFO] $m" }
function Write-Warn { param($m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Write-Host "Press Enter to EXIT" -NoNewline

    try {
        do {
            $key = $Host.UI.RawUI.ReadKey(
                "NoEcho,IncludeKeyDown"
            )
        }
        until ($key.VirtualKeyCode -eq 13)

        Write-Host ""
    }
    catch {
        Write-Host ""
        Read-Host "Press Enter to EXIT" | Out-Null
    }
}

function Get-ShortError {
    param($ErrorRecord)

    $Message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = [string]$ErrorRecord
    }

    return (($Message -replace "\s+", " ").Trim())
}

function Ensure-Module {
    param([string]$Name)

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Write-Info "Installing $Name..."

        Install-Module `
            -Name $Name `
            -Scope CurrentUser `
            -Force `
            -AllowClobber `
            -ErrorAction Stop
    }

    Import-Module $Name -ErrorAction Stop
}

function Connect-ExchangeAuto {
    param([string]$GroupIdentity)

    Ensure-Module -Name "ExchangeOnlineManagement"

    $Connected = $false

    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        $Connection = Get-ConnectionInformation -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($Connection) {
            try {
                Get-DistributionGroup `
                    -Identity $GroupIdentity `
                    -ErrorAction Stop |
                    Out-Null

                $Connected = $true
            }
            catch {
            }
        }
    }

    if ($Connected) {
        Write-OK "Exchange session reused"
        return
    }

    Write-Host "Exchange Online: Connecting..."

    $Command = Get-Command Connect-ExchangeOnline -ErrorAction Stop
    $Parameters = @{
        ErrorAction = "Stop"
    }

    if ($Command.Parameters.ContainsKey("ShowBanner")) {
        $Parameters["ShowBanner"] = $false
    }

    Connect-ExchangeOnline @Parameters | Out-Null

    Get-DistributionGroup `
        -Identity $GroupIdentity `
        -ErrorAction Stop |
        Out-Null

    Write-OK "Exchange connected"
}

try {
    Write-Host "DISTRIBUTION GROUP MEMBERS"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($DistributionGroup)) {
        $DistributionGroup = (Read-Host "Distribution group email or name").Trim()
    }

    if ([string]::IsNullOrWhiteSpace($DistributionGroup)) {
        throw "Distribution group email or name is required."
    }

    Connect-ExchangeAuto -GroupIdentity $DistributionGroup

    $Group = Get-DistributionGroup `
        -Identity $DistributionGroup `
        -ErrorAction Stop

    $MembersAvailable = $true
    $Members = @()
    $MemberError = ""

    try {
        $Members = @(
            Get-DistributionGroupMember `
                -Identity $Group.Identity `
                -ResultSize Unlimited `
                -ErrorAction Stop |
            Sort-Object DisplayName
        )
    }
    catch {
        $MembersAvailable = $false
        $MemberError = Get-ShortError $_
    }

    Write-Host ""
    Write-Host "GROUP"
    Write-Host ("Name   : {0}" -f $Group.DisplayName)
    Write-Host ("Email  : {0}" -f $Group.PrimarySmtpAddress)
    Write-Host ("Type   : {0}" -f $Group.RecipientTypeDetails)

    Write-Host ""
    Write-Host "MEMBERS"

    if (-not $MembersAvailable) {
        Write-Host "Status : Not available"
        Write-Warn "Member lookup failed: $MemberError"
    }
    elseif ($Members.Count -eq 0) {
        Write-Host "Count  : 0"
        Write-Host "  none"
    }
    else {
        Write-Host ("Count  : {0}" -f $Members.Count)

        foreach ($Member in $Members) {
            $Email = $Member.PrimarySmtpAddress

            if (-not $Email) {
                $Email = $Member.WindowsEmailAddress
            }

            if ($Email) {
                Write-Host ("  - {0} <{1}>" -f $Member.DisplayName, $Email)
            }
            else {
                Write-Host ("  - {0}" -f $Member.DisplayName)
            }
        }
    }

    Write-Host ""
    Write-Host "STANDARD NOTE"
    Write-Host "Read-only distribution group membership lookup. No changes were made."
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}
