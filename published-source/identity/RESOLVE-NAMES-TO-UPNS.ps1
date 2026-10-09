<#
.SYNOPSIS
    Resolve display names, UPNs, or email-style entries to Entra ID user principal names.

.DESCRIPTION
    Read-only helper for preparing clean UPN lists before account review or license workflows.
    Accepts one or more direct values or .txt/.csv input. Searches Microsoft Graph users. Does not make changes.

.NOTES
    PowerShell 5.1 compatible.
    Full CSV is for human review.
    Clean TXT contains exact matches only and is safe for UPN-based follow-on tools.
    Tenant-targeted Graph connection avoids accidental cross-tenant lookups.
#>

param(
    [Alias("Input")]
    [string[]]$InputObject,
    [string]$InputPath,
    [string]$TenantDomain
)


$ErrorActionPreference = "Stop"

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to close" | Out-Null
}

function Write-Section($Title) {
    Write-Host ""
    Write-Host "--------------------------------------"
    Write-Host $Title
    Write-Host "--------------------------------------"
}

function Normalize-InputValue($Value) {
    if ($null -eq $Value) { return "" }

    $v = [string]$Value
    $v = $v.Trim()
    $v = $v -replace '^"|"$', ''
    $v = $v -replace "^'|'$", ''
    return $v.Trim()
}

function Escape-ODataString($Value) {
    if ($null -eq $Value) { return "" }
    return ([string]$Value -replace "'", "''")
}

function Get-GraphErrorText($ErrorRecord) {
    if ($null -eq $ErrorRecord) { return "Unknown Graph error" }

    $raw = $ErrorRecord.ErrorDetails.Message
    if ($raw) {
        try {
            $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
            if ($parsed.error.message) { return [string]$parsed.error.message }
        }
        catch {}
    }

    if ($ErrorRecord.Exception.Message) {
        return [string]$ErrorRecord.Exception.Message
    }

    return [string]$ErrorRecord
}

function Test-GraphReadContext($Context) {
    if ($null -eq $Context -or -not $Context.Account) { return $false }

    $acceptedScopes = @(
        "User.Read.All",
        "User.ReadWrite.All",
        "Directory.Read.All",
        "Directory.ReadWrite.All"
    )

    foreach ($scope in @($Context.Scopes)) {
        if ($acceptedScopes -contains $scope) { return $true }
    }

    return $false
}

function Ensure-GraphConnection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantDomain
    )

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    $connectCommand = Get-Command Connect-MgGraph -ErrorAction SilentlyContinue
    if (-not $connectCommand) {
        throw "Microsoft.Graph.Authentication is required. Install it with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    $ctx = Get-MgContext -ErrorAction SilentlyContinue
    if ($ctx) {
        WARN "Disconnecting the current Graph context before tenant-targeted lookup"
        if ($ctx.Account)  { INFO "Current account: $($ctx.Account)" }
        if ($ctx.TenantId) { INFO "Current tenant : $($ctx.TenantId)" }
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }

    $connectParams = @{
        TenantId     = $TenantDomain
        Scopes       = @("User.Read.All")
        ContextScope = "Process"
        ErrorAction  = "Stop"
    }

    if ($connectCommand.Parameters.ContainsKey("NoWelcome")) {
        $connectParams["NoWelcome"] = $true
    }

    Connect-MgGraph @connectParams | Out-Null

    $ctx = Get-MgContext -ErrorAction Stop
    if (-not (Test-GraphReadContext -Context $ctx)) {
        throw "Graph connected, but the access token does not contain a supported directory read scope."
    }

    if (-not $ctx.TenantId) {
        throw "Graph connected, but the tenant ID could not be verified from the current context."
    }

    OK "Graph connected: $($ctx.Account)"
    INFO "Tenant ID       : $($ctx.TenantId)"
    INFO "Requested tenant: $TenantDomain"
}

function Import-InputEntries($Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Input file not found: $Path"
    }

    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    $entries = @()

    if ($ext -eq ".csv") {
        $rows = @(Import-Csv -LiteralPath $Path -ErrorAction Stop)
        if ($rows.Count -eq 0) {
            throw "CSV appears empty."
        }

        $columns = @($rows[0].PSObject.Properties.Name)
        $preferred = @(
            "UserPrincipalName",
            "UserPrincipleName",
            "UPN",
            "Email",
            "Mail",
            "PrimarySmtpAddress",
            "Address",
            "DisplayName",
            "Name",
            "User",
            "Account"
        )

        $selectedColumn = $null
        foreach ($p in $preferred) {
            if ($columns -contains $p) {
                $selectedColumn = $p
                break
            }
        }

        if (-not $selectedColumn) {
            WARN "No standard column found. Available columns: $($columns -join ', ')"
            $selectedColumn = Read-Host "Enter column name to use"
            if (-not ($columns -contains $selectedColumn)) {
                throw "Column not found: $selectedColumn"
            }
        }

        INFO "Using CSV column: $selectedColumn"

        foreach ($row in $rows) {
            $value = Normalize-InputValue $row.$selectedColumn
            if ($value) { $entries += $value }
        }
    }
    else {
        foreach ($line in Get-Content -LiteralPath $Path -ErrorAction Stop) {
            $value = Normalize-InputValue $line
            if (-not $value) { continue }
            if ($value -match '^(UserPrincipalName|UserPrincipleName|UPN|Email|Mail|Name|DisplayName)$') { continue }
            $entries += $value
        }
    }

    return @($entries | Where-Object { $_ } | Select-Object -Unique)
}

function Get-InputEntries {
    param(
        [string[]]$Values,
        [string]$Path
    )

    $entries = New-Object System.Collections.ArrayList
    $rawValues = @($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($Path) {
        $rawValues += $Path
    }

    if ($rawValues.Count -eq 0) {
        $entered = Normalize-InputValue (Read-Host "Name, email, UPN, or TXT/CSV path")
        if ($entered) {
            $rawValues = @($entered)
        }
    }

    foreach ($value in $rawValues) {
        $clean = Normalize-InputValue $value
        if (-not $clean) { continue }

        if (Test-Path -LiteralPath $clean -PathType Leaf) {
            foreach ($entry in @(Import-InputEntries -Path $clean)) {
                [void]$entries.Add($entry)
            }
            continue
        }

        foreach ($entry in @($clean -split '\s*,\s*')) {
            $normalized = Normalize-InputValue $entry
            if ($normalized) {
                [void]$entries.Add($normalized)
            }
        }
    }

    return @($entries | Where-Object { $_ } | Select-Object -Unique)
}

function Invoke-GraphRequestSafe {
    param(
        [string]$Stage,
        [string]$Uri,
        [hashtable]$Headers
    )

    try {
        if ($Headers) {
            $response = Invoke-MgGraphRequest -Method GET -Uri $Uri -Headers $Headers -ErrorAction Stop
        }
        else {
            $response = Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop
        }

        return [PSCustomObject]@{
            Success = $true
            Stage   = $Stage
            Value   = @($response.value)
            Error   = ""
        }
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Stage   = $Stage
            Value   = @()
            Error   = Get-GraphErrorText $_
        }
    }
}

function Get-NormalizedNameTokens($Value) {
    if (-not $Value) { return @() }

    $normalized = ([string]$Value).ToLowerInvariant()
    $normalized = $normalized -replace '[^\p{L}\p{Nd}]+', ' '
    return @($normalized -split '\s+' | Where-Object { $_ })
}

function Invoke-GraphUserSearch($SearchText) {
    $safe = Escape-ODataString $SearchText
    $select = "id,displayName,givenName,surname,userPrincipalName,mail,accountEnabled,createdDateTime,onPremisesSyncEnabled"
    $results = New-Object System.Collections.ArrayList
    $errors = New-Object System.Collections.ArrayList

    if ($SearchText -match '@') {
        $filter = "userPrincipalName eq '$safe' or mail eq '$safe'"
        $uri = "https://graph.microsoft.com/v1.0/users?`$select=$select&`$filter=$([System.Uri]::EscapeDataString($filter))"
        $attempt = Invoke-GraphRequestSafe -Stage "Exact UPN/mail" -Uri $uri

        if ($attempt.Success) {
            foreach ($item in @($attempt.Value)) { [void]$results.Add($item) }
        }
        else {
            [void]$errors.Add("$($attempt.Stage): $($attempt.Error)")
        }
    }

    if ($results.Count -eq 0) {
        $filter = "displayName eq '$safe'"
        $uri = "https://graph.microsoft.com/v1.0/users?`$select=$select&`$filter=$([System.Uri]::EscapeDataString($filter))"
        $attempt = Invoke-GraphRequestSafe -Stage "Exact display name" -Uri $uri

        if ($attempt.Success) {
            foreach ($item in @($attempt.Value)) { [void]$results.Add($item) }
        }
        else {
            [void]$errors.Add("$($attempt.Stage): $($attempt.Error)")
        }
    }

    $parts = @($SearchText -split '\s+' | Where-Object { $_.Length -ge 2 })

    if ($results.Count -eq 0 -and $parts.Count -ge 2) {
        $first = Escape-ODataString $parts[0]
        $last = Escape-ODataString $parts[$parts.Count - 1]
        $filter = "givenName eq '$first' and surname eq '$last'"
        $uri = "https://graph.microsoft.com/v1.0/users?`$select=$select&`$filter=$([System.Uri]::EscapeDataString($filter))&`$top=10"
        $attempt = Invoke-GraphRequestSafe -Stage "Exact given name and surname" -Uri $uri

        if ($attempt.Success) {
            foreach ($item in @($attempt.Value)) { [void]$results.Add($item) }
        }
        else {
            [void]$errors.Add("$($attempt.Stage): $($attempt.Error)")
        }
    }

    if ($results.Count -eq 0) {
        $searchTextClean = $SearchText -replace '"', ''
        $searchExpression = '"displayName:' + $searchTextClean + '"'
        $uri = "https://graph.microsoft.com/v1.0/users?`$select=$select&`$search=$([System.Uri]::EscapeDataString($searchExpression))&`$count=true&`$top=10"
        $attempt = Invoke-GraphRequestSafe -Stage "Display-name search" -Uri $uri -Headers @{ ConsistencyLevel = "eventual" }

        if ($attempt.Success) {
            foreach ($item in @($attempt.Value)) { [void]$results.Add($item) }
        }
        else {
            [void]$errors.Add("$($attempt.Stage): $($attempt.Error)")
        }
    }

    if ($results.Count -eq 0 -and $parts.Count -ge 2) {
        $first = Escape-ODataString $parts[0]
        $filter = "startswith(displayName,'$first')"
        $uri = "https://graph.microsoft.com/v1.0/users?`$select=$select&`$filter=$([System.Uri]::EscapeDataString($filter))&`$top=25"
        $attempt = Invoke-GraphRequestSafe -Stage "Starts-with fallback" -Uri $uri

        if ($attempt.Success) {
            $wantedTokens = @(Get-NormalizedNameTokens $SearchText)
            $firstToken = $wantedTokens[0]
            $lastToken = $wantedTokens[$wantedTokens.Count - 1]

            foreach ($item in @($attempt.Value)) {
                $candidateTokens = @(Get-NormalizedNameTokens $item.displayName)
                if (($candidateTokens -contains $firstToken) -and ($candidateTokens -contains $lastToken)) {
                    [void]$results.Add($item)
                }
            }
        }
        else {
            [void]$errors.Add("$($attempt.Stage): $($attempt.Error)")
        }
    }

    $unique = New-Object System.Collections.ArrayList
    $seen = @{}

    foreach ($r in @($results)) {
        if (-not $r.id) { continue }
        $id = [string]$r.id

        if (-not $seen.ContainsKey($id)) {
            $seen[$id] = $true
            [void]$unique.Add($r)
        }
    }

    return [PSCustomObject]@{
        Results = @($unique)
        Error   = ($errors -join " | ")
    }
}

function Get-MatchStatus($InputValue, $Matches) {
    if (-not $Matches -or $Matches.Count -eq 0) { return "NO MATCH" }

    if ($Matches.Count -eq 1) {
        $m = $Matches[0]
        if (
            $InputValue -ieq $m.userPrincipalName -or
            $InputValue -ieq $m.mail -or
            $InputValue -ieq $m.displayName
        ) {
            return "EXACT MATCH"
        }

        return "SINGLE LIKELY MATCH"
    }

    return "MULTIPLE MATCHES"
}

function Get-DefaultOutputDirectory($InputPath) {
    if ($InputPath -and (Test-Path -LiteralPath $InputPath -PathType Leaf)) {
        $resolved = (Resolve-Path -LiteralPath $InputPath -ErrorAction Stop).Path
        $parent = Split-Path -Path $resolved -Parent
        if ($parent) { return $parent }
    }

    return (Get-Location).Path
}

function Export-VerifiedCsv {
    param(
        [array]$Rows,
        [string]$Path
    )

    $Rows | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    $check = @(Import-Csv -LiteralPath $Path -ErrorAction Stop)

    if ($check.Count -ne $Rows.Count) {
        throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)."
    }

    $expected = @($Rows | ForEach-Object {
        "{0}|{1}|{2}|{3}|{4}" -f $_.Input, $_.MatchStatus, $_.UserPrincipalName, $_.MatchId, $_.Error
    })

    $actual = @($check | ForEach-Object {
        "{0}|{1}|{2}|{3}|{4}" -f $_.Input, $_.MatchStatus, $_.UserPrincipalName, $_.MatchId, $_.Error
    })

    $difference = @(Compare-Object -ReferenceObject $expected -DifferenceObject $actual -SyncWindow 0)
    if ($difference.Count -gt 0) {
        throw "CSV verification failed. Exported content did not match the in-memory results."
    }
}

function Export-VerifiedUpnTxt {
    param(
        [string[]]$Upns,
        [string]$Path
    )

    $expected = @($Upns | Where-Object { $_ } | Sort-Object -Unique)
    $expected | Set-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop

    $actual = @(
        Get-Content -LiteralPath $Path -Encoding UTF8 -ErrorAction Stop |
            ForEach-Object { Normalize-InputValue $_ } |
            Where-Object { $_ } |
            Sort-Object -Unique
    )

    $difference = @(Compare-Object -ReferenceObject $expected -DifferenceObject $actual)
    if ($difference.Count -gt 0 -or $actual.Count -ne $expected.Count) {
        throw "UPN TXT verification failed. Exported content did not match the exact-match list."
    }
}

try {
    Clear-Host
    Write-Host "RESOLVE NAMES TO UPNs"
    Write-Host "Read-only"
    Write-Host ""
    Write-Host "Purpose: Convert display names, UPNs, or emails into a clean review list."
    Write-Host "Input  : Tenant domain plus one name/email/UPN or TXT/CSV"
    Write-Host "Output : Screen summary, optional review CSV, optional exact-match UPN TXT"
    Write-Host "Changes: None"
    Write-Host ""

    if (-not $TenantDomain) {
        $TenantDomain = Normalize-InputValue (Read-Host "Tenant domain (example: contoso.com)")
    }
    else {
        $TenantDomain = Normalize-InputValue $TenantDomain
    }

    if (-not $TenantDomain) {
        throw "Tenant domain is required."
    }

    $inputPath = ""
    if ($InputPath) {
        $inputPath = Normalize-InputValue $InputPath
    }

    Write-Section "INPUT"
    $entries = @(Get-InputEntries -Values $InputObject -Path $inputPath)
    INFO "Tenant target : $TenantDomain"
    INFO "Entries loaded: $($entries.Count)"

    if ($entries.Count -eq 0) {
        throw "No usable entries were provided."
    }

    Ensure-GraphConnection -TenantDomain $TenantDomain

    Write-Section "SEARCH"
    $allRows = @()
    $i = 0

    foreach ($entry in $entries) {
        $i++
        INFO "[$i/$($entries.Count)] Resolving: $entry"

        $search = Invoke-GraphUserSearch -SearchText $entry
        $matches = @($search.Results)
        $status = Get-MatchStatus -InputValue $entry -Matches $matches

        if ($matches.Count -eq 0) {
            $allRows += [PSCustomObject]@{
                Input             = $entry
                MatchStatus       = $status
                MatchCount        = 0
                DisplayName       = ""
                UserPrincipalName = ""
                Mail              = ""
                AccountEnabled    = ""
                Hybrid            = ""
                MatchId           = ""
                Error             = $search.Error
            }
            continue
        }

        foreach ($m in $matches) {
            $hybrid = "Unknown"
            if ($null -ne $m.onPremisesSyncEnabled) {
                if ($m.onPremisesSyncEnabled -eq $true) { $hybrid = "Yes" } else { $hybrid = "No" }
            }

            $allRows += [PSCustomObject]@{
                Input             = $entry
                MatchStatus       = $status
                MatchCount        = $matches.Count
                DisplayName       = $m.displayName
                UserPrincipalName = $m.userPrincipalName
                Mail              = $m.mail
                AccountEnabled    = $m.accountEnabled
                Hybrid            = $hybrid
                MatchId           = $m.id
                Error             = $search.Error
            }
        }
    }

    $inputStatus = @(
        $allRows |
            Group-Object Input |
            ForEach-Object { $_.Group | Select-Object -First 1 }
    )

    $exactCount = @($inputStatus | Where-Object { $_.MatchStatus -eq "EXACT MATCH" }).Count
    $singleCount = @($inputStatus | Where-Object { $_.MatchStatus -eq "SINGLE LIKELY MATCH" }).Count
    $multiInputs = @($inputStatus | Where-Object { $_.MatchStatus -eq "MULTIPLE MATCHES" }).Count
    $noMatchCount = @($inputStatus | Where-Object { $_.MatchStatus -eq "NO MATCH" }).Count
    $searchErrorCount = @($inputStatus | Where-Object { $_.Error }).Count

    $exactUpns = @(
        $allRows |
            Where-Object { $_.MatchStatus -eq "EXACT MATCH" -and $_.UserPrincipalName } |
            Select-Object -ExpandProperty UserPrincipalName -Unique |
            Sort-Object
    )

    $verdict = "REVIEW REQUIRED"
    $recommendation = "Review likely, multiple, no-match, or search-error entries before using output"

    if ($singleCount -eq 0 -and $multiInputs -eq 0 -and $noMatchCount -eq 0 -and $searchErrorCount -eq 0) {
        $verdict = "EXACT MATCH LIST READY"
        $recommendation = "Use the verified exact-match UPN TXT for the next account workflow"
    }

    Write-Section "SUMMARY"
    Write-Host ""
    Write-Host "****************************************"
    Write-Host "UPN RESOLUTION DECISION"
    Write-Host "****************************************"
    Write-Host ("VERDICT        : {0}" -f $verdict)
    Write-Host ("RECOMMENDATION : {0}" -f $recommendation)
    Write-Host ("INPUTS         : {0}" -f $entries.Count)
    Write-Host ("EXACT MATCHES  : {0}" -f $exactCount)
    Write-Host ("LIKELY MATCHES : {0}" -f $singleCount)
    Write-Host ("MULTIPLE MATCH : {0}" -f $multiInputs)
    Write-Host ("NO MATCH       : {0}" -f $noMatchCount)
    Write-Host ("SEARCH ERRORS  : {0}" -f $searchErrorCount)
    Write-Host "****************************************"

    Write-Host ""
    Write-Host "RESULTS"
    Write-Host "--------------------------------------"
    $allRows |
        Select-Object Input, MatchStatus, DisplayName, UserPrincipalName, AccountEnabled, Hybrid |
        Format-Table -AutoSize

    $errorRows = @($inputStatus | Where-Object { $_.Error })
    if ($errorRows.Count -gt 0) {
        Write-Host ""
        Write-Host "SEARCH WARNINGS"
        Write-Host "--------------------------------------"
        foreach ($row in $errorRows) {
            WARN "$($row.Input): $($row.Error)"
        }
    }

    Write-Host ""
    Write-Host ". . . . COPY THIS SUMMARY TO TICKET . . . ."
    Write-Host ""
    Write-Host "UPN RESOLUTION SUMMARY"
    Write-Host "--------------------------------------"
    Write-Host ("Timestamp      : {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    Write-Host ("Tenant target  : {0}" -f $TenantDomain)
    Write-Host ("Input file     : {0}" -f $inputPath)
    Write-Host ("Inputs         : {0}" -f $entries.Count)
    Write-Host ("Exact matches  : {0}" -f $exactCount)
    Write-Host ("Likely matches : {0}" -f $singleCount)
    Write-Host ("Multiple match : {0}" -f $multiInputs)
    Write-Host ("No match       : {0}" -f $noMatchCount)
    Write-Host ("Search errors  : {0}" -f $searchErrorCount)
    Write-Host ""
    Write-Host ("Verdict        : {0}" -f $verdict)
    Write-Host ("Recommendation : {0}" -f $recommendation)
    Write-Host ""
    Write-Host "Notes:"
    Write-Host "- This tool is read-only"
    Write-Host "- Graph reconnects to the requested tenant before searching"
    Write-Host "- Full CSV is for human review only"
    Write-Host "- Clean UPN TXT contains exact matches only"
    Write-Host "- Likely, multiple, no-match, and search-error entries require manual review"
    Write-Host ""
    Write-Host ". . . . END SUMMARY . . . ."
    Write-Host ""

    $outputDirectory = Get-DefaultOutputDirectory -InputPath $inputPath

    $export = Read-Host "Export full review results to CSV [Y/N]"
    if ($export -match '^(Y|y)$') {
        $defaultExport = Join-Path $outputDirectory ("resolved-upns-full-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
        $exportPath = Normalize-InputValue (Read-Host "CSV export path [$defaultExport]")
        if (-not $exportPath) { $exportPath = $defaultExport }

        Export-VerifiedCsv -Rows @($allRows) -Path $exportPath
        OK "Exported and verified full review CSV: $exportPath"
        WARN "Do not use the full review CSV directly in license or deletion scripts"
    }

    $exportClean = Read-Host "Export verified exact-match UPN TXT [Y/N]"
    if ($exportClean -match '^(Y|y)$') {
        if ($exactUpns.Count -eq 0) {
            WARN "No exact-match UPNs are available to export"
        }
        else {
            $defaultClean = Join-Path $outputDirectory ("clean-upns-exact-{0}.txt" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
            $cleanPath = Normalize-InputValue (Read-Host "TXT export path [$defaultClean]")
            if (-not $cleanPath) { $cleanPath = $defaultClean }

            Export-VerifiedUpnTxt -Upns $exactUpns -Path $cleanPath
            OK "Exported and verified exact-match UPN TXT: $cleanPath"
            INFO "UPNs exported: $($exactUpns.Count)"
        }
    }
}
catch {
    FAIL $_.Exception.Message
}
finally {
    Pause-End
}