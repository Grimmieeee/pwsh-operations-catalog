<#PSScriptInfo
.VERSION 0.1.0
.GUID b49a4b54-424e-4475-e182-c690ad475a3e
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
#Requires -Version 5.1

<#
.SYNOPSIS
Read-only check for information you may not want to publish.

.DESCRIPTION
Scans a file or folder for obvious secrets, private-key material, tenant/app IDs,
email addresses, internal paths, URLs, UNC paths, Authenticode blocks, and other
environment-specific values that deserve human review before public sharing.

This tool reports only. It never edits or sanitizes source files.
#>

[CmdletBinding()]
param(
    [string]$Path,
    [string[]]$Terms,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'


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

function Write-Ok {
    param([string]$Message)
    Write-Host '[OK] ' -ForegroundColor Green -NoNewline
    Write-Host $Message
}
function Write-Info {
    param([string]$Message)
    Write-Host '[INFO] ' -NoNewline
    Write-Host $Message
}
function Write-Warn {
    param([string]$Message)
    $script:FKHasIssue = $true
    Write-Host '[WARN] ' -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}
function Write-Fail {
    param([string]$Message)
    $script:FKHasIssue = $true
    Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $Message
}
function Show-Section {
    param([string]$Title)
    Write-FKHeading -Title $Title
}
function Pause-End {
    Close-FKConsole -SkipPause ([bool]$NoPause)
}

function Get-RelativePath {
    param([string]$FullName,[string]$Root)
    if ($FullName.StartsWith($Root,[System.StringComparison]::OrdinalIgnoreCase)) {
        return $FullName.Substring($Root.Length).TrimStart('\')
    }
    return $FullName
}

function Get-SafeExcerpt {
    param([string]$Line,[string]$Category)
    $text = ($Line -replace '\s+',' ').Trim()
    if ($Category -eq 'SECRET LITERAL' -or $Category -eq 'TOKEN / KEY MATERIAL') {
        return '[REDACTED - sensitive value matched on this line]'
    }
    if ($text.Length -gt 180) { $text = $text.Substring(0,180) + '...' }
    return $text
}

function Add-Finding {
    param(
        [System.Collections.ArrayList]$List,
        [string]$Severity,
        [string]$Category,
        [string]$File,
        [int]$Line,
        [string]$Excerpt
    )
    [void]$List.Add([pscustomobject]@{
        Severity=$Severity; Category=$Category; File=$File; Line=$Line; Excerpt=$Excerpt
    })
}

try {
    Write-FKStart -Title 'SENSITIVE DATA CHECK' -Objective 'Finds obvious secrets or internal details before you publish or share files.' -Mode ''
    Write-Host 'READ ONLY. Finds information you may not want to publish.'

    if (-not $Path) {
        $default = (Get-Location).Path
        $typed = Read-Host "File or folder [$default]"
        $Path = if ([string]::IsNullOrWhiteSpace($typed)) { $default } else { $typed.Trim().Trim('"') }
    }

    if (-not (Test-Path -LiteralPath $Path)) { throw "Path not found: $Path" }

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    $root = if ($item.PSIsContainer) { $item.FullName.TrimEnd('\') } else { $item.Directory.FullName.TrimEnd('\') }

    $allowedExtensions = @('.ps1','.psm1','.psd1','.md','.txt','.json','.yml','.yaml','.xml','.html','.htm','.js','.css','.config','.ini','.csv')
    if ($item.PSIsContainer) {
        $files = @(Get-ChildItem -LiteralPath $item.FullName -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\.git(\\|$)' })
    } else {
        $files = @($item)
    }

    $findings = New-Object System.Collections.ArrayList

    Show-Section 'FILE TYPES'
    foreach ($file in $files) {
        $rel = Get-RelativePath -FullName $file.FullName -Root $root
        if ($file.Extension -in @('.pfx','.p12','.key','.pem','.env')) {
            Add-Finding -List $findings -Severity 'HIGH' -Category 'SENSITIVE FILE TYPE' -File $rel -Line 0 -Excerpt $file.Extension
        }
    }

    $textFiles = @($files | Where-Object { $_.Extension -in $allowedExtensions })
    Write-Info "Text/source files scanned: $($textFiles.Count)"

    $patterns = @(
        [pscustomobject]@{Severity='HIGH';Category='TOKEN / KEY MATERIAL';Regex='(?i)-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|\bBearer\s+[A-Za-z0-9\-\._~\+\/]+=*|\beyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}'},
        [pscustomobject]@{Severity='HIGH';Category='SECRET LITERAL';Regex='(?i)\b(password|passwd|pwd|clientsecret|client_secret|api[_-]?key|access[_-]?token|refresh[_-]?token|secret)\b\s*[:=]\s*["''][^"''$]{4,}["'']'},
        [pscustomobject]@{Severity='WARN';Category='AUTHENTICODE BLOCK';Regex='(?i)^\s*#\s*SIG\s*#\s*Begin signature block'},
        [pscustomobject]@{Severity='WARN';Category='TENANT / APP GUID';Regex='(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b'},
        [pscustomobject]@{Severity='WARN';Category='EMAIL / UPN';Regex='(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'},
        [pscustomobject]@{Severity='WARN';Category='URL';Regex='(?i)https?://[^\s"'')>]+'},
        [pscustomobject]@{Severity='WARN';Category='UNC PATH';Regex='\\\\[A-Za-z0-9._$-]+\\[^\s"'']+'},
        [pscustomobject]@{Severity='INFO';Category='LOCAL PATH';Regex='(?i)\b[A-Z]:\\[^\r\n"'']+'},
        [pscustomobject]@{Severity='INFO';Category='ONMICROSOFT DOMAIN';Regex='(?i)\b[A-Z0-9.-]+\.onmicrosoft\.com\b'}
    )

    $placeholderDomains = @('example.com','domain.com','contoso.com','microsoft.com','localhost')
    $placeholderGuids = @('00000000-0000-0000-0000-000000000000')

    foreach ($file in $textFiles) {
        $rel = Get-RelativePath -FullName $file.FullName -Root $root
        $lines = @(Get-Content -LiteralPath $file.FullName -ErrorAction SilentlyContinue)
        $insideSignature = $false

        for ($index = 0; $index -lt $lines.Count; $index++) {
            $line = [string]$lines[$index]
            $lineNumber = $index + 1

            if ($line -match '(?i)^\s*#\s*SIG\s*#\s*Begin signature block') { $insideSignature = $true }
            if ($insideSignature -and $line -notmatch '(?i)^\s*#\s*SIG\s*#\s*Begin signature block') {
                if ($line -match '(?i)^\s*#\s*SIG\s*#\s*End signature block') { $insideSignature = $false }
                continue
            }

            foreach ($pattern in $patterns) {
                if ($line -match $pattern.Regex) {
                    if ($pattern.Category -eq 'EMAIL / UPN') {
                        $match = [regex]::Match($line,$pattern.Regex).Value.ToLowerInvariant()
                        $domain = ($match -split '@')[-1]
                        if ($domain -in $placeholderDomains) { continue }
                    }
                    if ($pattern.Category -eq 'URL') {
                        $match = [regex]::Match($line,$pattern.Regex).Value.ToLowerInvariant()
                        if ($match -match 'https?://(www\.)?(example\.com|contoso\.com|microsoft\.com|learn\.microsoft\.com|github\.com)(/|$)') { continue }
                    }
                    if ($pattern.Category -eq 'TENANT / APP GUID') {
                        $match = [regex]::Match($line,$pattern.Regex).Value.ToLowerInvariant()
                        if ($match -in $placeholderGuids) { continue }
                    }

                    Add-Finding -List $findings -Severity $pattern.Severity -Category $pattern.Category -File $rel -Line $lineNumber -Excerpt (Get-SafeExcerpt -Line $line -Category $pattern.Category)
                }
            }

            foreach ($term in @($Terms)) {
                if (-not [string]::IsNullOrWhiteSpace($term) -and $line.IndexOf($term,[System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    Add-Finding -List $findings -Severity 'WARN' -Category 'CUSTOM TERM' -File $rel -Line $lineNumber -Excerpt (Get-SafeExcerpt -Line $line -Category 'CUSTOM TERM')
                }
            }
        }
    }

    Show-Section 'FINDINGS'
    if ($findings.Count -eq 0) {
        Write-Ok 'No obvious publication-sensitive values found by these rules.'
    } else {
        foreach ($finding in $findings) {
            $color = if ($finding.Severity -eq 'HIGH') { 'Red' } elseif ($finding.Severity -eq 'WARN') { 'Yellow' } else { 'Gray' }
            $where = if ($finding.Line -gt 0) { "$($finding.File):$($finding.Line)" } else { $finding.File }
            Write-Host ("[{0}] {1} | {2}" -f $finding.Severity,$finding.Category,$where) -ForegroundColor $color
            Write-Host ("       {0}" -f $finding.Excerpt) -ForegroundColor Gray
        }
    }

    Show-Section 'SUMMARY'
    $high = @($findings | Where-Object Severity -eq 'HIGH').Count
    $warn = @($findings | Where-Object Severity -eq 'WARN').Count
    $info = @($findings | Where-Object Severity -eq 'INFO').Count
    Write-Info "Files reviewed: $($files.Count)"
    Write-Info "High: $high | Warn: $warn | Info: $info"
    if ($high -gt 0) { Write-Fail 'High-risk publication findings require review.' }
    elseif ($warn -gt 0) { Write-Warn 'Review flagged values before publishing.' }
    else { Write-Ok 'No blocking findings detected.' }

    Write-Host ''
    Write-Info 'This is a heuristic check, not proof that a file is safe to publish.'
} catch {
    Write-Host ''
    Write-Fail $_.Exception.Message
} finally {
    Pause-End
}
