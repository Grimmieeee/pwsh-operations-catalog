#Requires -Version 5.1

<#
IR AUDIT - TOKEN DECODE

OBJECTIVE
Decode the header and payload of a three-part JWT locally for IR review.

LOCAL ONLY
No Graph.
No network.
No export.

IMPORTANT
This tool does NOT validate the JWT signature, issuer trust, audience trust,
or whether the token was actually accepted by a service.
A decoded token is not proof that the token is authentic or usable.
#>

param(
    [string]$Token
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

function ConvertFrom-Base64Url {
    param([string]$InputText)

    if ([string]::IsNullOrWhiteSpace($InputText)) {
        return $null
    }

    $padded = $InputText.Replace('-', '+').Replace('_', '/')

    switch ($padded.Length % 4) {
        0 { }
        2 { $padded += '==' }
        3 { $padded += '=' }
        default { return $null }
    }

    try {
        return [Text.Encoding]::UTF8.GetString(
            [Convert]::FromBase64String($padded)
        )
    }
    catch {
        return $null
    }
}

function Format-UnixTime {
    param([object]$Value)

    if ($null -eq $Value) {
        return "Not present"
    }

    try {
        return (
            [DateTimeOffset]::FromUnixTimeSeconds([long]$Value)
        ).LocalDateTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
    catch {
        return "Unparseable"
    }
}

function Redact-Guids {
    param([object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    if ($Value -is [array]) {
        return (
            @($Value | ForEach-Object { Redact-Guids $_ }) -join ", "
        )
    }

    return (
        ([string]$Value) -replace
        '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
        '<guid>'
    )
}

function Show-Claim {
    param(
        [string]$Label,
        [object]$Value
    )

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return
    }

    Write-Host (
        "{0,-24}: {1}" -f
        $Label,
        (Redact-Guids $Value)
    )
}

try {
    Write-Host "IR AUDIT - TOKEN DECODE"
    Write-Host "LOCAL ONLY / NO NETWORK"
    Write-Host ""

    if ($Token) {
        WARN "A token supplied with -Token can be exposed in command history. Interactive hidden input is safer."
    }

    do {
        if (-not $Token) {
            $Token = Read-SecretText "Paste JWT token [blank to exit]"
        }

        if ([string]::IsNullOrWhiteSpace($Token)) {
            break
        }

        $raw = ($Token.Trim() -replace '^(?i:Bearer)\s+', '')
        $parts = $raw.Split('.')

        if ($parts.Count -ne 3) {
            FAIL "Expected a three-part JWT (header.payload.signature). JWE/encrypted tokens are not decoded by this tool."
            $Token = $null
            $raw = $null
            continue
        }

        $headerJson = ConvertFrom-Base64Url $parts[0]
        $payloadJson = ConvertFrom-Base64Url $parts[1]

        if (-not $headerJson -or -not $payloadJson) {
            FAIL "JWT header or payload could not be base64url-decoded."
            $Token = $null
            $raw = $null
            continue
        }

        try {
            $header = $headerJson | ConvertFrom-Json -ErrorAction Stop
            $payload = $payloadJson | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            FAIL "JWT decoded, but header/payload JSON could not be parsed."
            $Token = $null
            $raw = $null
            continue
        }

        Section "HEADER"

        Show-Claim "Algorithm" $header.alg
        Show-Claim "Type" $header.typ

        if ($header.kid) {
            Write-Host "Key ID                  : Present"
        }

        Section "PAYLOAD - IDENTITY"

        Show-Claim "UPN" $payload.upn
        Show-Claim "Preferred username" $payload.preferred_username
        Show-Claim "Name" $payload.name
        Show-Claim "App display name" $payload.app_displayname
        Show-Claim "Audience" $payload.aud
        Show-Claim "Issuer" $payload.iss

        if ($payload.tid) { Write-Host "Tenant ID               : Present" }
        if ($payload.oid) { Write-Host "Object ID               : Present" }
        if ($payload.appid) { Write-Host "App ID                  : Present" }

        Section "PAYLOAD - AUTH"

        Show-Claim "Auth methods" $payload.amr
        Show-Claim "Scopes" $payload.scp
        Show-Claim "Roles" $payload.roles
        Show-Claim "IP address" $payload.ipaddr
        Show-Claim "Auth time" (Format-UnixTime $payload.auth_time)
        Show-Claim "Issued" (Format-UnixTime $payload.iat)
        Show-Claim "Not before" (Format-UnixTime $payload.nbf)
        Show-Claim "Expires" (Format-UnixTime $payload.exp)

        Section "ASSESSMENT"

        WARN "Signature validation: NOT PERFORMED"

        if ([string]$header.alg -eq "none") {
            RISK "Token header declares alg=none."
        }

        if ($payload.exp) {
            try {
                $expires = [DateTimeOffset]::FromUnixTimeSeconds(
                    [long]$payload.exp
                ).LocalDateTime

                if ($expires -lt (Get-Date)) {
                    WARN "Token is expired based on the unverified exp claim."
                }
                else {
                    INFO "Token exp claim is in the future. This does not prove the token is valid or accepted."
                }
            }
            catch {
                WARN "Token expiration claim could not be interpreted."
            }
        }
        else {
            INFO "Expiration claim not present."
        }

        $highValueText = "$($payload.scp) $($payload.roles)"

        if ($highValueText -match '(?i)(Mail\.|Files\.|Sites\.|Directory\.|offline_access|RoleManagement\.|Application\.)') {
            RISK "High-value scope or role text appears present."
        }

        Write-Host ""
        WARN "Treat bearer tokens as secrets. Do not paste them into tickets, chat, or third-party tools."

        $header = $null
        $payload = $null
        $headerJson = $null
        $payloadJson = $null
        $raw = $null
        $Token = $null
    }
    while (Confirm-Yes "Decode another token")

    OK "Closed"
}
catch {
    Write-Host ""
    FAIL (Get-ShortError $_)
}
finally {
    $Token = $null
    Pause-End
}
