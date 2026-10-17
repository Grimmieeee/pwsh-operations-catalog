<#PSScriptInfo
.VERSION 0.1.0
.GUID 35d43268-027c-0317-1c55-3a8a039257f1
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
<#
DEPLOY-TCPIP-PRINTER.ps1

Endpoint printer deployment helper.

Purpose:
- Adds a direct TCP/IP printer
- Checks printer reachability
- Verifies driver exists
- Creates TCP/IP port if needed
- Adds printer only after confirmation

Change-making on local endpoint.
#>

param(
    [string]$PrinterName,
    [string]$PrinterIP,
    [string]$DriverName,
    [switch]$SetDefault,
    [switch]$TestPage
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}


# Console presentation only. Does not request scopes, query services or write data.
$script:FKEndWritten = $false
$script:FKStatusWritten = $false
$script:FKHasIssue = $false
function Write-FKStatus {
    param([string]$Status)
    Write-Host ''
    if ($Status -eq 'REVIEW REQUIRED') { Write-Host ('STATUS: '+$Status) -ForegroundColor Yellow }
    else { Write-Host ('STATUS: '+$Status) }
    $script:FKStatusWritten = $true
}
function Write-FKStart {
    param([string]$Title,[string]$Objective,[string]$Mode)
    Write-Host $Title
    Write-Host $Objective
    if ($Mode) { Write-Host $Mode }
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-Host ''
}
function Write-FKHeading {
    param([string]$Title)
    Write-Host ''
    switch ($Title.Trim().ToUpperInvariant()) {
        'SUMMARY' { Write-Host 'TICKET SUMMARY'; break }
        'FOLLOW-UP' { Write-Host 'NEXT STEP'; break }
        'NEXT' { Write-Host 'NEXT STEP'; break }
        default { Write-Host $Title }
    }
}
function Close-FKConsole {
    param([bool]$SkipPause = $false)
    if (-not $script:FKEndWritten) {
        Write-Host ''
        if (-not $script:FKStatusWritten) {
            Write-FKStatus $(if ($script:FKHasIssue) { 'REVIEW REQUIRED' } else { 'RUN FINISHED' })
        }
        Write-Host ("COMPLETED: {0}" -f (Get-Date).ToString('MM/dd/yyyy HH:mm'))
        $script:FKEndWritten = $true
    }
    if ($SkipPause) { return }
    Write-Host ''
    Write-Host 'Press ESC to close'
    if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected -and
        (Get-Command Read-Host).CommandType -ne 'Function') {
        try {
            while ($true) {
                $key=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                if ($key.VirtualKeyCode -eq 27 -or $key.VirtualKeyCode -eq 13) { return }
            }
        }
        catch { Write-Host 'Key input unavailable here.' }
    }
    while ($true) {
        $answer=Read-Host 'Type ESC then press ENTER to close'
        if ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -ieq 'ESC' -or $answer -eq [string][char]27) { return }
    }
}

function OK {
    param([string]$m)
    Write-Host '[OK] ' -ForegroundColor Green -NoNewline
    Write-Host $m
}
function INFO {
    param([string]$m)
    Write-Host '[INFO] ' -NoNewline
    Write-Host $m
}
function WARN {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[WARN] ' -ForegroundColor Yellow -NoNewline
    Write-Host $m
}
function RISK {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[RISK] ' -ForegroundColor Red -NoNewline
    Write-Host $m
}
function FAIL {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $m
}

function Pause-End {
    Close-FKConsole
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)
    Write-FKHeading -Title $Title
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

try {
    try { $host.UI.RawUI.WindowTitle = "Endpoint Printer Deployment" } catch {}

    Clear-Host
    Write-FKStart -Title 'ENDPOINT PRINTER DEPLOYMENT' -Objective 'Adds a direct TCP/IP printer after checking reachability, driver availability, and existing printer state.' -Mode 'MAKES CHANGES'
    Write-Host "Local change-making"
    Write-Host ""

    if (-not $PrinterName) {
        $PrinterName = (Read-Host "Printer display name").Trim()
    }

    if (-not $PrinterIP) {
        $PrinterIP = (Read-Host "Printer IP or hostname").Trim()
    }

    if (-not $DriverName) {
        $DriverName = (Read-Host "Driver name [blank to list installed drivers]").Trim()
    }

    if (-not $PrinterName -or -not $PrinterIP) {
        FAIL "Printer name and IP/hostname are required"
        Pause-End
        exit 1
    }

    Section "CHECKS"

    $reachable = Test-Connection -ComputerName $PrinterIP -Count 2 -Quiet -ErrorAction SilentlyContinue

    if ($reachable) {
        OK "Printer responds to ping"
    } else {
        WARN "Printer did not respond to ping. Some printers block ICMP."
    }

    if (-not $DriverName) {
        Section "INSTALLED DRIVERS"
        $drivers = @(Get-PrinterDriver -ErrorAction SilentlyContinue | Sort-Object Name)
        foreach ($d in $drivers) {
            Write-Host $d.Name
        }
        Write-Host ""
        $DriverName = (Read-Host "Driver name").Trim()
    }

    if (-not $DriverName) {
        FAIL "Driver name required"
        Pause-End
        exit 1
    }

    $driver = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue

    if (-not $driver) {
        FAIL "Driver not found: $DriverName"
        WARN "Install the manufacturer driver or use an existing installed driver."
        Pause-End
        exit 1
    }

    OK "Driver found: $DriverName"

    $existingPrinter = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue

    if ($existingPrinter) {
        WARN "Printer already exists: $PrinterName"
        Pause-End
        exit 0
    }

    $portName = "IP_$PrinterIP"
    $existingPort = Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue

    Section "PLAN"
    Write-Host "Printer : $PrinterName"
    Write-Host "Address : $PrinterIP"
    Write-Host "Port    : $portName"
    Write-Host "Driver  : $DriverName"
    Write-Host "Default : $SetDefault"
    Write-Host "Test    : $TestPage"
    Write-Host ""

    if (-not (Confirm-Type "This will add a local printer." "ADD")) {
        WARN "Cancelled"
        Pause-End
        exit 0
    }

    Section "DEPLOY"

    if (-not $existingPort) {
        try {
            Add-PrinterPort -Name $portName -PrinterHostAddress $PrinterIP -ErrorAction Stop
            OK "Port created: $portName"
        }
        catch {
            FAIL "Failed to create printer port"
            Write-Host $_.Exception.Message
            Pause-End
            exit 1
        }
    } else {
        OK "Port already exists: $portName"
    }

    try {
        Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $portName -ErrorAction Stop
        OK "Printer added: $PrinterName"
    }
    catch {
        FAIL "Failed to add printer"
        Write-Host $_.Exception.Message
        Pause-End
        exit 1
    }

    if ($SetDefault -or (Confirm-Yes "Set as default printer")) {
        try {
            Set-Printer -Name $PrinterName -IsDefault $true -ErrorAction Stop
            OK "Default printer set"
        }
        catch {
            WARN "Could not set default printer"
        }
    }

    if ($TestPage -or (Confirm-Yes "Print test page")) {
        try {
            $p = Get-CimInstance Win32_Printer -Filter "Name='$PrinterName'" -ErrorAction SilentlyContinue
            if ($p) {
                Invoke-CimMethod -InputObject $p -MethodName PrintTestPage | Out-Null
                OK "Test page sent"
            } else {
                WARN "Could not locate printer for test page"
            }
        }
        catch {
            WARN "Test page failed"
        }
    }

    Section "SUMMARY"
    Write-Host "Printer  : $PrinterName"
    Write-Host "Address  : $PrinterIP"
    Write-Host "Driver   : $DriverName"
    Write-Host "Operator : $env:USERDOMAIN\$env:USERNAME"
    Write-Host "Time     : $(Now)"

    OK "Complete"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}
