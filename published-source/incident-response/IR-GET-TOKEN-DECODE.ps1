<#PSScriptInfo
.VERSION 0.1.0
.GUID 5dce9214-73a2-c394-c4e3-06fc4d666735
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
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

function Section {
    param([string]$Title)
    Write-FKHeading -Title $Title
}

function Pause-End {
    Close-FKConsole
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
    Write-FKStart -Title 'IR AUDIT - TOKEN DECODE' -Objective 'Decodes a JWT locally so you can inspect its claims.' -Mode ''
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
