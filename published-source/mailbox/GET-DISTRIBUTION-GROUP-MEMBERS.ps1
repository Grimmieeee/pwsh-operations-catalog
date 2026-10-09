<#
DISTRIBUTION GROUP MEMBERS

OBJECTIVE
Look up members of one or more Exchange Online distribution groups.

CHANGES
Read-only. No changes are made.

RUN
Right-click > Run with PowerShell
or
Right-click > Run with PowerShell 7
#>

[CmdletBinding()]
param(
    [Alias('DistributionGroup')]
    [string[]]$InputObject
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

    $module=Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$Name is required but is not installed. Install with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop
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

function Get-InputGroups {
    param([string[]]$Values)

    $items=New-Object System.Collections.ArrayList
    $rawValues=@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($rawValues.Count -eq 0) {
        $entered=(Read-Host "Distribution group name/email or TXT/CSV path").Trim().Trim('"')
        if ($entered) { $rawValues=@($entered) }
    }

    foreach ($value in $rawValues) {
        $clean=([string]$value).Trim().Trim('"')
        if (-not $clean) { continue }

        if (Test-Path -LiteralPath $clean -PathType Leaf) {
            if ([System.IO.Path]::GetExtension($clean) -ieq '.csv') {
                foreach ($row in @(Import-Csv -LiteralPath $clean -ErrorAction Stop)) {
                    $candidate=$null
                    foreach ($name in @('Group','GroupName','Name','Email','Address','Mail','Input')) {
                        if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                            $candidate=[string]$row.$name
                            break
                        }
                    }
                    if (-not $candidate) {
                        $first=$row.PSObject.Properties | Select-Object -First 1
                        if ($first) { $candidate=[string]$first.Value }
                    }
                    if ($candidate -and $candidate.Trim()) { [void]$items.Add($candidate.Trim().Trim('"')) }
                }
            }
            else {
                foreach ($line in @(Get-Content -LiteralPath $clean -Encoding UTF8 -ErrorAction Stop)) {
                    $candidate=([string]$line).Trim().Trim('"')
                    if ($candidate -and $candidate -notmatch '^#') { [void]$items.Add($candidate) }
                }
            }
            continue
        }

        foreach ($candidate in @($clean -split '\s*,\s*')) {
            if ($candidate) { [void]$items.Add($candidate.Trim()) }
        }
    }

    return @($items | Where-Object { $_ } | Select-Object -Unique)
}

function Offer-VerifiedCsv {
    param([object[]]$Rows,[string]$DefaultName='distribution-group-members.csv')

    if (-not $Rows -or $Rows.Count -eq 0) { return }
    if ((Read-Host "Export member detail to CSV [Y/N]").Trim() -notmatch '^(?i)y$') { return }

    $path=(Read-Host "CSV output path [blank for .\$DefaultName]").Trim().Trim('"')
    if (-not $path) { $path=Join-Path (Get-Location).Path $DefaultName }

    $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    $check=@(Import-Csv -LiteralPath $path -ErrorAction Stop)
    if ($check.Count -ne $Rows.Count) {
        throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)."
    }

    Write-OK "Exported and verified: $path"
}

try {
    Write-Host "DISTRIBUTION GROUP MEMBERS"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

    $groupsToCheck=@(Get-InputGroups -Values $InputObject)
    if ($groupsToCheck.Count -eq 0) { throw "At least one distribution group is required." }

    Ensure-Module -Name "ExchangeOnlineManagement"

    $connected=$false
    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        $connection=Get-ConnectionInformation -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($connection) { $connected=$true }
    }

    if (-not $connected) {
        $command=Get-Command Connect-ExchangeOnline -ErrorAction Stop
        $parameters=@{ ErrorAction='Stop' }
        if ($command.Parameters.ContainsKey('ShowBanner')) { $parameters['ShowBanner']=$false }
        Connect-ExchangeOnline @parameters | Out-Null
    }

    Write-OK "Exchange connected"

    $rows=New-Object System.Collections.ArrayList
    $found=0
    $failed=0

    foreach ($DistributionGroup in $groupsToCheck) {
        Write-Host ""
        Write-Host "GROUP"
        Write-Host ("Input  : {0}" -f $DistributionGroup)

        try {
            $Group=Get-DistributionGroup -Identity $DistributionGroup -ErrorAction Stop
            $Members=@(Get-DistributionGroupMember -Identity $Group.Identity -ResultSize Unlimited -ErrorAction Stop | Sort-Object DisplayName)

            $found++
            Write-Host ("Name   : {0}" -f $Group.DisplayName)
            Write-Host ("Email  : {0}" -f $Group.PrimarySmtpAddress)
            Write-Host ("Type   : {0}" -f $Group.RecipientTypeDetails)
            Write-Host ("Count  : {0}" -f $Members.Count)
            Write-Host ""
            Write-Host "MEMBERS"

            if ($Members.Count -eq 0) { Write-Host "  none" }

            foreach ($Member in $Members) {
                $Email=[string]$Member.PrimarySmtpAddress
                if (-not $Email) { $Email=[string]$Member.WindowsEmailAddress }

                if ($Email) { Write-Host ("  - {0} <{1}>" -f $Member.DisplayName,$Email) }
                else { Write-Host ("  - {0}" -f $Member.DisplayName) }

                [void]$rows.Add([pscustomobject]@{
                    GroupInput=$DistributionGroup
                    GroupName=[string]$Group.DisplayName
                    GroupMail=[string]$Group.PrimarySmtpAddress
                    GroupType=[string]$Group.RecipientTypeDetails
                    MemberName=[string]$Member.DisplayName
                    MemberMail=$Email
                    MemberType=[string]$Member.RecipientType
                })
            }
        }
        catch {
            $failed++
            Write-Warn ("Lookup failed: {0}" -f (Get-ShortError $_))
        }
    }

    Write-Host ""
    Write-Host "TICKET SUMMARY"
    Write-Host ("Groups checked : {0}" -f $groupsToCheck.Count)
    Write-Host ("Found          : {0}" -f $found)
    Write-Host ("Failed         : {0}" -f $failed)
    Write-Host ("Member rows    : {0}" -f $rows.Count)

    Offer-VerifiedCsv -Rows @($rows)

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
