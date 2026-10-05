#Requires -Version 5.1

<#
IR AUDIT - THREAT INTEL

OBJECTIVE
Look up suspect public IP addresses in VirusTotal and/or AbuseIPDB.

READ-ONLY
No tenant changes.
The selected public IP indicators are sent to the enabled reputation providers.
API keys are not written to disk by this script.
#>

param(
    [string]$IP,
    [string]$InputFile,
    [switch]$ExportCsv
)

$ErrorActionPreference = "Stop"

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function RISK($m) { Write-Host "[RISK] $m" -ForegroundColor Red }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host (" {0} " -f $Title) `
        -ForegroundColor White `
        -BackgroundColor DarkGray
}

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to EXIT" | Out-Null
}

function Confirm-Yes {
    param([string]$Prompt)

    $answer = Read-Host "$Prompt [Y/N]"

    return (
        -not [string]::IsNullOrWhiteSpace($answer) -and
        $answer.Trim().ToUpperInvariant() -eq "Y"
    )
}

function Confirm-Type {
    param(
        [string]$Prompt,
        [string]$Required
    )

    Write-Host ""
    WARN $Prompt
    $answer = Read-Host "Type $Required to continue"

    return (
        -not [string]::IsNullOrWhiteSpace($answer) -and
        $answer.Trim().ToUpperInvariant() -eq $Required.ToUpperInvariant()
    )
}

function Get-ShortError {
    param($ErrorRecord)

    $message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$ErrorRecord
    }

    return (($message -replace "\s+", " ").Trim())
}

function Get-DesktopPath {
    $desktop = [Environment]::GetFolderPath("Desktop")

    if ([string]::IsNullOrWhiteSpace($desktop)) {
        $desktop = Join-Path $env:USERPROFILE "Desktop"
    }

    return $desktop
}

function Get-ExportPath {
    param([string]$DefaultName)

    $folder = Read-Host "Output folder [Enter for Desktop]"

    if ([string]::IsNullOrWhiteSpace($folder)) {
        $folder = Get-DesktopPath
    }
    else {
        $folder = $folder.Trim().Trim('"').Trim("'")
    }

    if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
        throw "Output folder not found: $folder"
    }

    return (Join-Path $folder $DefaultName)
}

function Read-SecretText {
    param([string]$Prompt)

    $secure = Read-Host $Prompt -AsSecureString

    if ($null -eq $secure -or $secure.Length -eq 0) {
        return ""
    }

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)

    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Convert-ToIPAddress {
    param([string]$Address)

    $parsed = $null

    if ([System.Net.IPAddress]::TryParse($Address, [ref]$parsed)) {
        return $parsed
    }

    return $null
}

function Test-PublicIPAddress {
    param([System.Net.IPAddress]$Address)

    if ($null -eq $Address) {
        return $false
    }

    if ([System.Net.IPAddress]::IsLoopback($Address)) {
        return $false
    }

    $bytes = $Address.GetAddressBytes()

    if ($Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
        if ($bytes[0] -eq 0) { return $false }
        if ($bytes[0] -eq 10) { return $false }
        if ($bytes[0] -eq 127) { return $false }
        if ($bytes[0] -ge 224) { return $false }

        if (
            $bytes[0] -eq 100 -and
            $bytes[1] -ge 64 -and
            $bytes[1] -le 127
        ) {
            return $false
        }

        if (
            $bytes[0] -eq 169 -and
            $bytes[1] -eq 254
        ) {
            return $false
        }

        if (
            $bytes[0] -eq 172 -and
            $bytes[1] -ge 16 -and
            $bytes[1] -le 31
        ) {
            return $false
        }

        if (
            $bytes[0] -eq 192 -and
            $bytes[1] -eq 168
        ) {
            return $false
        }

        return $true
    }

    if ($Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6) {
        if ($Address.IsIPv6LinkLocal) { return $false }
        if ($Address.IsIPv6Multicast) { return $false }
        if ($Address.IsIPv6SiteLocal) { return $false }

        if (($bytes[0] -band 0xFE) -eq 0xFC) {
            return $false
        }

        return $true
    }

    return $false
}

function Get-IPList {
    $list = New-Object System.Collections.Generic.List[string]

    function Add-IPValue {
        param([string]$Value)

        if ([string]::IsNullOrWhiteSpace($Value)) {
            return
        }

        $clean = $Value.Trim()
        $parsed = Convert-ToIPAddress $clean

        if (-not $parsed) {
            WARN "Skipped invalid IP: $clean"
            return
        }

        $normalized = $parsed.ToString()

        if (-not $list.Contains($normalized)) {
            $list.Add($normalized)
        }
    }

    if ($IP) {
        foreach ($item in ($IP -split '[,\s]+')) {
            Add-IPValue -Value $item
        }
    }

    if ($InputFile) {
        if (-not (Test-Path -LiteralPath $InputFile -PathType Leaf)) {
            throw "Input file not found: $InputFile"
        }

        foreach ($line in Get-Content -LiteralPath $InputFile -ErrorAction Stop) {
            foreach ($item in ($line -split '[,\s]+')) {
                Add-IPValue -Value $item
            }
        }
    }

    if ($list.Count -eq 0) {
        Write-Host "Enter IPs one at a time. Blank to finish."

        while ($true) {
            $manual = Read-Host "IP"

            if ([string]::IsNullOrWhiteSpace($manual)) {
                break
            }

            foreach ($item in ($manual -split '[,\s]+')) {
                Add-IPValue -Value $item
            }
        }
    }

    return @($list)
}

function Get-VTReport {
    param(
        [string]$Address,
        [string]$Key
    )

    if ([string]::IsNullOrWhiteSpace($Key)) {
        return $null
    }

    try {
        $encoded = [System.Uri]::EscapeDataString($Address)

        $response = Invoke-RestMethod `
            -Uri "https://www.virustotal.com/api/v3/ip_addresses/$encoded" `
            -Headers @{ "x-apikey" = $Key } `
            -Method GET `
            -ErrorAction Stop

        $stats = $response.data.attributes.last_analysis_stats
        $malicious = [int]$stats.malicious
        $suspicious = [int]$stats.suspicious
        $harmless = [int]$stats.harmless
        $undetected = [int]$stats.undetected
        $total = $malicious + $suspicious + $harmless + $undetected

        $risk = "OK"

        if ($malicious -ge 3) {
            $risk = "HIGH"
        }
        elseif ($malicious -ge 1 -or $suspicious -ge 3) {
            $risk = "MEDIUM"
        }

        return [PSCustomObject]@{
            Source  = "VirusTotal"
            IP      = $Address
            Status  = "OK"
            Risk    = $risk
            Score   = "$malicious malicious / $suspicious suspicious / $total engines"
            Country = [string]$response.data.attributes.country
            ASN     = [string]$response.data.attributes.as_owner
            Error   = ""
        }
    }
    catch {
        return [PSCustomObject]@{
            Source  = "VirusTotal"
            IP      = $Address
            Status  = "ERROR"
            Risk    = "UNKNOWN"
            Score   = ""
            Country = ""
            ASN     = ""
            Error   = Get-ShortError $_
        }
    }
}

function Get-AbuseIPDBReport {
    param(
        [string]$Address,
        [string]$Key
    )

    if ([string]::IsNullOrWhiteSpace($Key)) {
        return $null
    }

    try {
        $encoded = [System.Uri]::EscapeDataString($Address)
        $uri = "https://api.abuseipdb.com/api/v2/check?ipAddress=$encoded&maxAgeInDays=90"

        $response = Invoke-RestMethod `
            -Uri $uri `
            -Headers @{
                Key    = $Key
                Accept = "application/json"
            } `
            -Method GET `
            -ErrorAction Stop

        $data = $response.data
        $score = [int]$data.abuseConfidenceScore
        $risk = "OK"

        if ($score -ge 75) {
            $risk = "HIGH"
        }
        elseif ($score -ge 25) {
            $risk = "MEDIUM"
        }
        elseif ($score -gt 0) {
            $risk = "LOW"
        }

        return [PSCustomObject]@{
            Source  = "AbuseIPDB"
            IP      = $Address
            Status  = "OK"
            Risk    = $risk
            Score   = "$score abuse confidence / $($data.totalReports) reports"
            Country = [string]$data.countryCode
            ASN     = [string]$data.isp
            Error   = ""
        }
    }
    catch {
        return [PSCustomObject]@{
            Source  = "AbuseIPDB"
            IP      = $Address
            Status  = "ERROR"
            Risk    = "UNKNOWN"
            Score   = ""
            Country = ""
            ASN     = ""
            Error   = Get-ShortError $_
        }
    }
}

try {
    Write-Host "IR AUDIT - THREAT INTEL"
    Write-Host "READ-ONLY / EXTERNAL REPUTATION LOOKUP"
    Write-Host ""

    if (-not $InputFile) {
        $candidate = Read-Host "Input TXT file [blank for manual/IP parameter]"

        if ($candidate) {
            $InputFile = $candidate.Trim().Trim('"').Trim("'")
        }
    }

    $ips = @(Get-IPList)

    if ($ips.Count -eq 0) {
        throw "No valid IP addresses were provided."
    }

    $vtKey = [string]$env:VT_API_KEY
    $abuseKey = [string]$env:ABUSEIPDB_API_KEY

    if ($vtKey) {
        OK "VirusTotal API key found in environment"
    }
    else {
        $vtKey = Read-SecretText "VirusTotal API key [blank to skip]"
    }

    if ($abuseKey) {
        OK "AbuseIPDB API key found in environment"
    }
    else {
        $abuseKey = Read-SecretText "AbuseIPDB API key [blank to skip]"
    }

    if (-not $vtKey -and -not $abuseKey) {
        throw "No reputation provider API key was supplied."
    }

    $publicIPs = New-Object System.Collections.Generic.List[string]
    $nonPublicIPs = New-Object System.Collections.Generic.List[string]

    foreach ($address in $ips) {
        $parsed = Convert-ToIPAddress $address

        if (Test-PublicIPAddress $parsed) {
            $publicIPs.Add($parsed.ToString())
        }
        else {
            $nonPublicIPs.Add($parsed.ToString())
        }
    }

    if ($nonPublicIPs.Count -gt 0) {
        INFO "Non-public addresses will not be sent externally: $($nonPublicIPs -join ', ')"
    }

    if ($publicIPs.Count -eq 0) {
        throw "No public IP addresses remain for external reputation lookup."
    }

    Section "PRIVACY GATE"

    WARN "Public IP indicators will be sent to the enabled third-party reputation providers."

    if (-not (Confirm-Yes "Continue with external threat-intel lookup")) {
        WARN "Cancelled"
        return
    }

    Section "LOOKUP"

    $results = New-Object System.Collections.Generic.List[object]

    foreach ($address in $publicIPs) {
        INFO "Checking $address..."

        $vt = Get-VTReport -Address $address -Key $vtKey

        if ($vt) {
            $results.Add($vt)
        }

        $abuse = Get-AbuseIPDBReport -Address $address -Key $abuseKey

        if ($abuse) {
            $results.Add($abuse)
        }
    }

    Section "RESULTS"

    foreach ($row in $results) {
        if ($row.Status -eq "ERROR") {
            WARN "$($row.IP) | $($row.Source) | LOOKUP ERROR | $($row.Error)"
        }
        else {
            $line = "$($row.IP) | $($row.Source) | $($row.Risk) | $($row.Score) | $($row.Country) | $($row.ASN)"

            if ($row.Risk -eq "HIGH") {
                RISK $line
            }
            elseif ($row.Risk -in @("MEDIUM","LOW")) {
                WARN $line
            }
            else {
                OK $line
            }
        }
    }

    $high = @(
        $results |
        Where-Object { $_.Risk -eq "HIGH" } |
        Select-Object -ExpandProperty IP -Unique
    )

    $medium = @(
        $results |
        Where-Object { $_.Risk -eq "MEDIUM" } |
        Select-Object -ExpandProperty IP -Unique
    )

    $errors = @($results | Where-Object { $_.Status -eq "ERROR" })

    Section "SUMMARY"

    Write-Host "THREAT INTEL SUMMARY"
    Write-Host "--------------------------------------"
    Write-Host "Timestamp       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "Public IPs      : $($publicIPs.Count)"
    Write-Host "High risk IPs   : $(if ($high.Count) { $high -join ', ' } else { 'None' })"
    Write-Host "Medium risk IPs : $(if ($medium.Count) { $medium -join ', ' } else { 'None' })"
    Write-Host "Lookup errors   : $($errors.Count)"
    Write-Host ""
    Write-Host "Note:"
    Write-Host "- Reputation is supporting evidence, not proof of compromise."
    Write-Host "- Correlate with sign-ins, UAL, message trace, endpoint telemetry, and client context."

    if ($ExportCsv -or (Confirm-Yes "Export results to CSV")) {
        $path = Get-ExportPath -DefaultName "threat-intel-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

        $results |
            Export-Csv `
                -LiteralPath $path `
                -NoTypeInformation `
                -Encoding UTF8 `
                -ErrorAction Stop

        OK "Exported: $path"
    }
}
catch {
    Write-Host ""
    FAIL (Get-ShortError $_)
}
finally {
    $vtKey = $null
    $abuseKey = $null
    Pause-End
}
