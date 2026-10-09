<#
JOIN-COMPUTER-TO-DOMAIN.ps1

Endpoint domain join helper.

Purpose:
- Runs pre-flight checks before domain join
- Checks admin rights, hostname, current domain state, DNS, and domain reachability
- Performs Add-Computer only after explicit typed confirmation

Change-making.
Requires local admin rights to join.
#>

param(
    [string]$Domain,
    [string]$OUPath,
    [string]$TicketNumber
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function RISK($m) { Write-Host "[RISK] $m" -ForegroundColor Red }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to close" | Out-Null
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host "--------------------------------------" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "Timestamp: $(Now)" -ForegroundColor Cyan
    Write-Host "--------------------------------------" -ForegroundColor Cyan
}

function Confirm-Yes {
    param([string]$Prompt)

    $a = Read-Host "$Prompt [Y/N]"
    return ($a.Trim().ToUpper() -eq "Y")
}

function Confirm-Type {
    param(
        [string]$Prompt,
        [string]$Required
    )

    Write-Host ""
    WARN $Prompt
    $a = Read-Host "Type $Required to continue"

    return ($a.Trim().ToUpper() -eq $Required.ToUpper())
}

function Encode-Value {
    param([string]$Value)
    return [System.Uri]::EscapeDataString($Value)
}

function Escape-OData {
    param([string]$Value)
    return ($Value -replace "'", "''")
}

function Clean-Name {
    param([object]$Value)

    if ($null -eq $Value) { return "" }

    $text = [string]$Value
    return ($text -replace '\s*\([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\)\s*$', '').Trim()
}

function Get-InputLines {
    param([string]$Path)

    if (-not $Path) {
        $Path = (Read-Host "Input TXT/CSV path").Trim().Trim('"')
    }

    if (-not $Path -or -not (Test-Path $Path)) {
        FAIL "Input file not found"
        return @()
    }

    $items = New-Object System.Collections.ArrayList

    try {
        if ($Path.ToLower().EndsWith(".csv")) {
            $rows = Import-Csv -Path $Path -ErrorAction Stop

            foreach ($row in $rows) {
                $value = $null

                foreach ($name in @("UPN","UserPrincipalName","Email","Address","Group","GroupName","DisplayName","Name","Input")) {
                    if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                        $value = "$($row.$name)"
                        break
                    }
                }

                if (-not $value) {
                    $first = $row.PSObject.Properties | Select-Object -First 1
                    if ($first) { $value = "$($first.Value)" }
                }

                if ($value -and $value.Trim()) {
                    [void]$items.Add($value.Trim().Trim('"'))
                }
            }
        }
        else {
            $lines = Get-Content -Path $Path -Encoding UTF8 -ErrorAction Stop

            foreach ($line in $lines) {
                $clean = $line.Trim().Trim('"')

                if ($clean -and $clean -notmatch '^#') {
                    [void]$items.Add($clean)
                }
            }
        }
    }
    catch {
        FAIL "Could not read input file"
        return @()
    }

    return @($items | Select-Object -Unique)
}

function Offer-ExportCsv {
    param(
        [array]$Rows,
        [string]$DefaultName
    )

    if (-not $Rows -or $Rows.Count -eq 0) { return }

    if (-not (Confirm-Yes "Export results to CSV")) { return }

    $path = Read-Host "CSV output path [blank for .\$DefaultName]"

    if (-not $path) {
        $path = Join-Path (Get-Location).Path $DefaultName
    }

    try {
        $Rows | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
        OK "Exported: $path"
    }
    catch {
        WARN "CSV export failed"
    }
}

function Test-IsAdmin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($id)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

try {
    try { $host.UI.RawUI.WindowTitle = "Endpoint Domain Join" } catch {}

    Clear-Host
    Write-Host "ENDPOINT DOMAIN JOIN"
    Write-Host "Change-making"
    Write-Host ""

    if (-not $Domain) {
        $Domain = (Read-Host "Target domain, e.g. contoso.com").Trim()
    }

    if (-not $Domain) {
        FAIL "Domain required"
        Pause-End
        exit 1
    }

    if (-not $OUPath) {
        $OUPath = (Read-Host "OU path [blank for default]").Trim()
    }

    if (-not $TicketNumber) {
        $TicketNumber = (Read-Host "Ticket number").Trim()
    }

    Section "PRE-FLIGHT"

    $checks = New-Object System.Collections.ArrayList
    $canJoin = $true

    if (Test-IsAdmin) {
        OK "Running as administrator"
        [void]$checks.Add([pscustomobject]@{ Check="Admin"; Status="OK"; Detail="Running elevated" })
    } else {
        FAIL "Not running as administrator"
        [void]$checks.Add([pscustomobject]@{ Check="Admin"; Status="Fail"; Detail="Run elevated" })
        $canJoin = $false
    }

    $hostname = $env:COMPUTERNAME
    if ($hostname -like "DESKTOP-*" -or $hostname -like "LAPTOP-*" -or $hostname -like "WIN-*" -or $hostname -like "MININT-*") {
        WARN "Generic hostname detected: $hostname"
        [void]$checks.Add([pscustomobject]@{ Check="Hostname"; Status="Warning"; Detail=$hostname })
    } else {
        OK "Hostname: $hostname"
        [void]$checks.Add([pscustomobject]@{ Check="Hostname"; Status="OK"; Detail=$hostname })
    }

    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop

        if ($cs.PartOfDomain) {
            WARN "Already domain-joined: $($cs.Domain)"
            [void]$checks.Add([pscustomobject]@{ Check="DomainState"; Status="Warning"; Detail="Already joined to $($cs.Domain)" })
            $canJoin = $false
        } else {
            OK "Current state: workgroup $($cs.Domain)"
            [void]$checks.Add([pscustomobject]@{ Check="DomainState"; Status="OK"; Detail="Workgroup $($cs.Domain)" })
        }
    }
    catch {
        WARN "Could not read current domain state"
        [void]$checks.Add([pscustomobject]@{ Check="DomainState"; Status="Warning"; Detail="Unable to read" })
    }

    try {
        $dns = @(Resolve-DnsName -Name $Domain -ErrorAction Stop)
        OK "DNS resolves: $Domain"
        [void]$checks.Add([pscustomobject]@{ Check="DNS"; Status="OK"; Detail="$($dns.Count) record(s)" })
    }
    catch {
        FAIL "DNS failed for $Domain"
        [void]$checks.Add([pscustomobject]@{ Check="DNS"; Status="Fail"; Detail="Could not resolve" })
        $canJoin = $false
    }

    try {
        $ping = Test-Connection -ComputerName $Domain -Count 2 -Quiet -ErrorAction SilentlyContinue

        if ($ping) {
            OK "Domain reachable by ping"
            [void]$checks.Add([pscustomobject]@{ Check="Reachability"; Status="OK"; Detail="Ping succeeded" })
        } else {
            WARN "Ping did not respond. This may be normal if ICMP is blocked."
            [void]$checks.Add([pscustomobject]@{ Check="Reachability"; Status="Warning"; Detail="Ping failed or blocked" })
        }
    }
    catch {
        WARN "Reachability test failed"
        [void]$checks.Add([pscustomobject]@{ Check="Reachability"; Status="Warning"; Detail="Test failed" })
    }

    Section "PLAN"
    Write-Host "Machine : $hostname"
    Write-Host "Domain  : $Domain"
    Write-Host "OU      : $(if ($OUPath) { $OUPath } else { 'Default' })"
    Write-Host "Ticket  : $(if ($TicketNumber) { $TicketNumber } else { 'N/A' })"
    Write-Host ""

    if (-not $canJoin) {
        FAIL "Pre-flight failed. Join will not continue."
        Offer-ExportCsv -Rows @($checks) -DefaultName "domain-join-preflight-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        Pause-End
        exit 1
    }

    WARN "Joining a domain will change local endpoint state and may require reboot."

    if (-not (Confirm-Type "Join $hostname to $Domain now." "JOIN")) {
        WARN "Join cancelled"
        Pause-End
        exit 0
    }

    $cred = Get-Credential -Message "Enter domain join credentials"

    Section "JOIN"

    try {
        if ($OUPath) {
            Add-Computer -DomainName $Domain -OUPath $OUPath -Credential $cred -ErrorAction Stop
        } else {
            Add-Computer -DomainName $Domain -Credential $cred -ErrorAction Stop
        }

        OK "Domain join command completed"
        WARN "Restart is required to complete join"

        if (Confirm-Yes "Restart now") {
            Restart-Computer -Force
        }
    }
    catch {
        FAIL "Domain join failed"
        Write-Host $_.Exception.Message
    }

    Section "SUMMARY"
    Write-Host "Machine  : $hostname"
    Write-Host "Domain   : $Domain"
    Write-Host "Ticket   : $(if ($TicketNumber) { $TicketNumber } else { 'N/A' })"
    Write-Host "Operator : $env:USERDOMAIN\$env:USERNAME"
    Write-Host "Time     : $(Now)"

    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}
