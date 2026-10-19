# .VERSION 1.0.0
#requires -Version 5.1

<#
.SYNOPSIS
Read-only pre-delete dependency check for a single hybrid AD / Microsoft 365 user.

.DESCRIPTION
Checks common identity, Exchange Online, and Entra dependencies that may need
review before deleting an on-premises AD user object.

Checks:
- AD status, direct group membership, managed groups, direct reports, SPNs
- Exchange mailbox state, forwarding, hidden/visible forwarding rules
- Mailbox delegation: Full Access, Send As, Send on Behalf
- Distribution/mail-enabled group ownership
- Transport rules that directly reference the user's known addresses
- Entra/M365/Teams ownership
- Direct enterprise app role assignments
- Licenses
- Mailbox retention/hold status and mailbox statistics

Notes:
- Read-only. No user/group/mailbox changes are made.
- OneDrive/SharePoint ownership is NOT queried by this script.
- Local Windows services, scheduled tasks, application configs, and third-party
  systems using the account cannot be proven safe from this check alone.

Requires as applicable:
- ActiveDirectory module
- ExchangeOnlineManagement module
- Microsoft.Graph.Authentication module
#>

$ErrorActionPreference = 'Stop'

$script:Findings = New-Object System.Collections.Generic.List[string]
$script:Gaps     = New-Object System.Collections.Generic.List[string]

$GraphConnectedHere = $false
$ExoConnectedHere   = $false

# Embedded into standalone report scripts by tools/reporting/build.ps1.
$script:FKReportLines = New-Object 'Collections.Generic.List[string]'
$script:FKReportWarnings = @()
$script:FKReportStartedUtc = [DateTime]::UtcNow.ToString('o')

function Write-FKReportLine {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Object,
        [object]$Separator=' ',[switch]$NoNewline,
        [ConsoleColor]$ForegroundColor,[ConsoleColor]$BackgroundColor
    )
    $line=($Object | ForEach-Object {[string]$_}) -join [string]$Separator
    $script:FKReportLines.Add($line)
    Write-Host @PSBoundParameters
}

function ConvertTo-FKDesktopReport {
    param([string]$Title,[string[]]$Lines,[string]$StartedUtc,[string]$ScopeNote)
    $encode={param($Text) [Net.WebUtility]::HtmlEncode([string]$Text)}
    $blocks=New-Object 'Collections.Generic.List[string]'
    $section=New-Object 'Collections.Generic.List[string]'
    foreach($line in @($Lines)) {
        if($line -match '^\s*[A-Z][A-Z /+&:()-]{2,}\s*$' -and $line.Trim().Length -lt 90) {
            if($section.Count) {$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>');$section.Clear()}
            $blocks.Add('<h2>'+(& $encode $line.Trim())+'</h2>')
        } else {$section.Add([string]$line)}
    }
    if($section.Count){$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>')}
    $safeTitle=& $encode $Title
    return @"
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"><title>$safeTitle</title>
<style>body{font:16px/1.55 system-ui,sans-serif;background:#f5f7f7;color:#172524;margin:0}main{max-width:1000px;margin:32px auto;padding:32px;background:white;border-top:4px solid #168779}header{border-bottom:1px solid #d1ddda;padding-bottom:20px}small{letter-spacing:.12em;color:#52716b}h1{font-size:28px;margin:12px 0}h2{font-size:15px;letter-spacing:.1em;color:#166b60;margin:28px 0 10px;border-bottom:1px solid #d1ddda;padding-bottom:8px}pre{font:14px/1.6 ui-monospace,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere;margin:0}aside{background:#eef5f2;padding:12px 16px;margin:20px 0}footer{font-size:12px;color:#52716b;margin-top:32px}@media print{body{background:white}main{margin:0;padding:0;max-width:none}h2{break-after:avoid}pre{font-size:11px}}</style></head>
<body><main><header><small>F I E L D // K I T</small><h1>$safeTitle</h1><p>Collection started (UTC): $(& $encode $StartedUtc)</p></header><aside>$(& $encode $ScopeNote) Findings, unavailable checks, and displayed limits below are preserved from this run. Absence of a finding does not establish complete coverage.</aside>$($blocks.ToArray() -join "`n")<footer>Read-only report. No remote content or executable scripts. Review findings in context before taking action.</footer></main></body></html>
"@
}

function Save-FKDesktopReport {
    param([string]$Folder,[string]$Title,[string]$Content)
    if([string]::IsNullOrWhiteSpace($Folder) -or -not [IO.Directory]::Exists($Folder)){throw 'Report folder does not exist.'}
    $stem=($Title -replace '[^a-zA-Z0-9._-]','-').Trim('-')
    if(-not $stem){$stem='field-kit-report'}
    $stem=$stem.Substring(0,[Math]::Min(80,$stem.Length))
    $name=$stem+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)+'.html'
    $path=Join-Path $Folder $name
    $bytes=(New-Object Text.UTF8Encoding($false)).GetBytes($Content)
    $stream=New-Object IO.FileStream($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
    $actual=[IO.File]::ReadAllBytes($path)
    $sha=[Security.Cryptography.SHA256]::Create()
    try {
        if([Convert]::ToBase64String($sha.ComputeHash($bytes)) -cne [Convert]::ToBase64String($sha.ComputeHash($actual))){throw 'Report readback did not match the collected content.'}
    }finally{$sha.Dispose()}
    return $path
}

function Offer-FKDesktopReport {
    param([string]$Title,[string]$ScopeNote='Scope matches the console output; only displayed rows are included.',[string]$DesktopFolder=[Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory))
    if(-not $script:FKReportLines.Count){return}
    try {
        if((Read-Host 'Save report to Desktop? [Y/N]').Trim() -notmatch '^(?i)y$'){return}
        $folder=$DesktopFolder
        $reportLines=@($script:FKReportLines.ToArray())
        if(@($script:FKReportWarnings).Count){$reportLines+=@('','SERVICE WARNINGS');$reportLines+=@($script:FKReportWarnings|ForEach-Object {[string]$_})}
        $content=ConvertTo-FKDesktopReport -Title $Title -Lines $reportLines -StartedUtc $script:FKReportStartedUtc -ScopeNote $ScopeNote
        try {$saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content}
        catch {
            Write-Host '[WARN] Desktop report could not be saved. Choose another existing folder or cancel.' -ForegroundColor Yellow
            $folder=(Read-Host 'Report folder (ENTER cancels)').Trim().Trim('"')
            if(-not $folder){return}
            $saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content
        }
        Write-Host ('[OK] Report saved and readback checked: '+$saved)
    }catch{Write-Host ('[WARN] Report export failed: '+$_.Exception.Message) -ForegroundColor Yellow}
}

function Add-Finding {
    param([string]$Text)
    if (-not [string]::IsNullOrWhiteSpace($Text)) {
        $script:Findings.Add($Text)
    }
}

function Add-Gap {
    param([string]$Text)
    if (-not [string]::IsNullOrWhiteSpace($Text)) {
        $script:Gaps.Add($Text)
    }
}

function Write-Section {
    param([string]$Title)

    Write-FKReportLine ""
    Write-FKReportLine $Title
    Write-FKReportLine ('-' * $Title.Length)
}

function Write-List {
    param(
        [AllowNull()]
        [object[]]$Items,
        [string]$NoneText = 'None'
    )

    $clean = @($Items | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($clean.Count -eq 0) {
        Write-FKReportLine "- $NoneText"
        return
    }

    foreach ($item in $clean) {
        Write-FKReportLine "- $item"
    }
}

function Get-GraphPaged {
    param([Parameter(Mandatory=$true)][string]$Uri)

    $results = @()
    $next = $Uri

    while ($next) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop

        if ($response.value) {
            $results += @($response.value)
        }
        elseif ($response.Value) {
            $results += @($response.Value)
        }

        $next = $response.'@odata.nextLink'
    }

    return @($results)
}

function Get-ObjectPropertyText {
    param(
        [object]$Object,
        [string]$Property
    )

    if ($null -eq $Object) { return $null }

    $p = $Object.PSObject.Properties[$Property]
    if ($p) {
        return $p.Value
    }

    return $null
}

function Test-ExoIdentityMatch {
    param(
        [object]$Value,
        [string[]]$Tokens
    )

    if ($null -eq $Value) { return $false }

    $candidates = New-Object System.Collections.Generic.List[string]

    foreach ($v in @($Value)) {
        if ($null -eq $v) { continue }

        $candidates.Add([string]$v)

        foreach ($property in @(
            'Name',
            'DisplayName',
            'Alias',
            'PrimarySmtpAddress',
            'UserPrincipalName',
            'DistinguishedName',
            'Guid',
            'ObjectGuid',
            'ExternalDirectoryObjectId'
        )) {
            $propValue = Get-ObjectPropertyText -Object $v -Property $property
            if ($propValue) {
                $candidates.Add([string]$propValue)
            }
        }
    }

    $normalizedTokens = @(
        $Tokens |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim().ToLowerInvariant() } |
        Select-Object -Unique
    )

    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }

        if ($normalizedTokens -contains $candidate.Trim().ToLowerInvariant()) {
            return $true
        }
    }

    return $false
}

function Pause-End {
    Write-FKReportLine ""

    try {
        Read-Host "Press ENTER to EXIT" | Out-Null
        return
    }
    catch {}

    try {
        Write-FKReportLine "Press ENTER to EXIT..."
        [Console]::ReadLine() | Out-Null
        return
    }
    catch {}

    Start-Sleep -Seconds 15
}

try {
    $UPN = Read-Host "Enter UPN"

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        throw "UPN is required."
    }

    $UPN = $UPN.Trim()

    Write-FKReportLine ""
    Write-FKReportLine "USER PRE-DELETE CHECK"
    Write-FKReportLine "---------------------"
    Write-FKReportLine "Target: $UPN"
    Write-FKReportLine "Mode:   READ-ONLY"

    # -------------------------------------------------------------------------
    # ACTIVE DIRECTORY
    # -------------------------------------------------------------------------

    $adUser = $null
    $adGroups = @()
    $adManagedGroups = @()
    $directReports = @()
    $spns = @()
    $proxyAddresses = @()

    Write-Section "ACTIVE DIRECTORY"

    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        try {
            Import-Module ActiveDirectory -ErrorAction Stop

            $escapedUPN = $UPN.Replace("'", "''")
            $adUser = Get-ADUser -Filter "UserPrincipalName -eq '$escapedUPN'" -Properties `
                DisplayName, Enabled, MemberOf, ManagedObjects, Manager, DirectReports, `
                mail, proxyAddresses, servicePrincipalName, DistinguishedName, ObjectGUID, `
                SamAccountName -ErrorAction Stop -WarningVariable +script:FKReportWarnings

            if ($adUser) {
                Write-FKReportLine "Found:   $($adUser.DisplayName)"
                Write-FKReportLine "Enabled: $($adUser.Enabled)"
                Write-FKReportLine "SAM:     $($adUser.SamAccountName)"

                $proxyAddresses = @($adUser.proxyAddresses)

                $adGroups = @(
                    $adUser.MemberOf |
                    ForEach-Object {
                        try {
                            (Get-ADGroup -Identity $_ -ErrorAction Stop -WarningVariable +script:FKReportWarnings).Name
                        }
                        catch {
                            [string]$_
                        }
                    } |
                    Sort-Object -Unique
                )

                $directReports = @(
                    $adUser.DirectReports |
                    ForEach-Object {
                        try {
                            $r = Get-ADUser -Identity $_ -Properties UserPrincipalName,DisplayName -ErrorAction Stop -WarningVariable +script:FKReportWarnings
                            if ($r.UserPrincipalName) {
                                "$($r.DisplayName) <$($r.UserPrincipalName)>"
                            }
                            else {
                                $r.DisplayName
                            }
                        }
                        catch {
                            [string]$_
                        }
                    } |
                    Sort-Object -Unique
                )

                $spns = @($adUser.servicePrincipalName | Sort-Object -Unique)

                try {
                    $adManagedGroups = @(
                        Get-ADGroup -Filter * -Properties ManagedBy -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
                        Where-Object { $_.ManagedBy -eq $adUser.DistinguishedName } |
                        Select-Object -ExpandProperty Name |
                        Sort-Object -Unique
                    )
                }
                catch {
                    Add-Gap "AD managed-group lookup failed: $($_.Exception.Message)"
                }

                Write-FKReportLine ""
                Write-FKReportLine "Direct group memberships: $($adGroups.Count)"
                Write-List -Items $adGroups -NoneText "No direct AD group memberships"

                Write-FKReportLine ""
                Write-FKReportLine "Groups managed by user: $($adManagedGroups.Count)"
                Write-List -Items $adManagedGroups -NoneText "No AD groups managed by user"

                Write-FKReportLine ""
                Write-FKReportLine "Direct reports: $($directReports.Count)"
                Write-List -Items $directReports -NoneText "No direct reports"

                Write-FKReportLine ""
                Write-FKReportLine "Service Principal Names: $($spns.Count)"
                Write-List -Items $spns -NoneText "No SPNs assigned"

                if ($adManagedGroups.Count -gt 0) {
                    Add-Finding "$($adManagedGroups.Count) AD group(s) are managed by this user."
                }

                if ($directReports.Count -gt 0) {
                    Add-Finding "$($directReports.Count) AD user(s) reference this account as manager."
                }

                if ($spns.Count -gt 0) {
                    Add-Finding "$($spns.Count) SPN(s) are assigned to this account."
                }
            }
            else {
                Write-FKReportLine "- User not found in Active Directory"
                Add-Gap "User was not found in Active Directory."
            }
        }
        catch {
            Write-FKReportLine "- AD lookup failed: $($_.Exception.Message)"
            Add-Gap "Active Directory lookup failed: $($_.Exception.Message)"
        }
    }
    else {
        Write-FKReportLine "- ActiveDirectory module not installed"
        Add-Gap "ActiveDirectory module is unavailable."
    }

    # -------------------------------------------------------------------------
    # EXCHANGE ONLINE
    # -------------------------------------------------------------------------

    $mailbox = $null
    $exoRecipient = $null
    $exoIdentityTokens = @($UPN)

    Write-Section "EXCHANGE ONLINE"

    if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
        try {
            Import-Module ExchangeOnlineManagement -ErrorAction Stop

            $existingExo = @()
            try {
                $existingExo = @(
                    Get-ConnectionInformation -ErrorAction SilentlyContinue |
                    Where-Object { $_.State -eq 'Connected' }
                )
            }
            catch {}

            if ($existingExo.Count -eq 0) {
                Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
                $ExoConnectedHere = $true
            }

            try {
                $exoRecipient = Get-Recipient -Identity $UPN -ErrorAction Stop -WarningVariable +script:FKReportWarnings
            }
            catch {}

            if ($exoRecipient) {
                $exoIdentityTokens += @(
                    [string]$exoRecipient.Name,
                    [string]$exoRecipient.DisplayName,
                    [string]$exoRecipient.Alias,
                    [string]$exoRecipient.PrimarySmtpAddress,
                    [string]$exoRecipient.DistinguishedName,
                    [string]$exoRecipient.Guid,
                    [string]$exoRecipient.ExternalDirectoryObjectId
                )
            }

            if ($adUser) {
                $exoIdentityTokens += @(
                    [string]$adUser.DisplayName,
                    [string]$adUser.SamAccountName,
                    [string]$adUser.DistinguishedName,
                    [string]$adUser.ObjectGUID
                )
            }

            $smtpAliases = @(
                $proxyAddresses |
                Where-Object { $_ -match '^(?i)smtp:' } |
                ForEach-Object { ($_ -replace '^(?i)smtp:', '').Trim() }
            )

            $exoIdentityTokens += $smtpAliases
            $exoIdentityTokens = @(
                $exoIdentityTokens |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
            )

            try {
                $mailbox = Get-Mailbox -Identity $UPN -ErrorAction Stop -WarningVariable +script:FKReportWarnings
                Write-FKReportLine "Mailbox: $($mailbox.DisplayName) <$($mailbox.PrimarySmtpAddress)>"
                Write-FKReportLine "Type:    $($mailbox.RecipientTypeDetails)"
            }
            catch {
                Write-FKReportLine "- No Exchange Online mailbox found"
            }

            if ($mailbox) {
                # Mailbox-level forwarding
                Write-FKReportLine ""
                Write-FKReportLine "MAILBOX FORWARDING"

                $mailboxForwarding = @()

                if ($mailbox.ForwardingAddress) {
                    $resolved = [string]$mailbox.ForwardingAddress
                    try {
                        $forwardRecipient = Get-Recipient -Identity $mailbox.ForwardingAddress -ErrorAction Stop -WarningVariable +script:FKReportWarnings
                        if ($forwardRecipient.PrimarySmtpAddress) {
                            $resolved = [string]$forwardRecipient.PrimarySmtpAddress
                        }
                    }
                    catch {}

                    $mailboxForwarding += "ForwardingAddress: $resolved"
                }

                if ($mailbox.ForwardingSmtpAddress) {
                    $mailboxForwarding += "ForwardingSmtpAddress: $($mailbox.ForwardingSmtpAddress)"
                }

                if ($mailboxForwarding.Count -gt 0) {
                    Write-List -Items $mailboxForwarding
                    Write-FKReportLine "- DeliverToMailboxAndForward: $($mailbox.DeliverToMailboxAndForward)"
                    Add-Finding "Mailbox-level forwarding is configured."
                }
                else {
                    Write-FKReportLine "- No mailbox-level forwarding"
                }

                # Inbox forwarding/redirect rules
                Write-FKReportLine ""
                Write-FKReportLine "FORWARDING / REDIRECT INBOX RULES"

                try {
                    $forwardRules = @(
                        Get-InboxRule -Mailbox $UPN -IncludeHidden -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
                        Where-Object {
                            $_.ForwardTo -or
                            $_.ForwardAsAttachmentTo -or
                            $_.RedirectTo
                        }
                    )

                    if ($forwardRules.Count -eq 0) {
                        Write-FKReportLine "- None"
                    }
                    else {
                        foreach ($rule in $forwardRules) {
                            $targets = @()

                            foreach ($target in @($rule.ForwardTo)) {
                                if ($target) { $targets += "ForwardTo=$target" }
                            }
                            foreach ($target in @($rule.ForwardAsAttachmentTo)) {
                                if ($target) { $targets += "ForwardAsAttachmentTo=$target" }
                            }
                            foreach ($target in @($rule.RedirectTo)) {
                                if ($target) { $targets += "RedirectTo=$target" }
                            }

                            Write-FKReportLine "- $($rule.Name) | Enabled=$($rule.Enabled)"
                            foreach ($target in $targets) {
                                Write-FKReportLine "  $target"
                            }
                        }

                        Add-Finding "$($forwardRules.Count) forwarding/redirect inbox rule(s) exist."
                    }
                }
                catch {
                    Write-FKReportLine "- Lookup failed: $($_.Exception.Message)"
                    Add-Gap "Inbox rule lookup failed: $($_.Exception.Message)"
                }

                # Delegates ON the target mailbox
                Write-FKReportLine ""
                Write-FKReportLine "DELEGATES ON THIS MAILBOX"

                try {
                    $fullAccessOnTarget = @(
                        Get-MailboxPermission -Identity $UPN -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
                        Where-Object {
                            -not $_.IsInherited -and
                            -not $_.Deny -and
                            ($_.AccessRights -contains 'FullAccess') -and
                            ([string]$_.User -notmatch 'NT AUTHORITY\\SELF')
                        } |
                        ForEach-Object {
                            "Full Access: $($_.User)"
                        }
                    )

                    $sendAsOnTarget = @(
                        Get-RecipientPermission -Identity $UPN -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
                        Where-Object {
                            ($_.AccessRights -contains 'SendAs') -and
                            ([string]$_.Trustee -notmatch 'NT AUTHORITY\\SELF')
                        } |
                        ForEach-Object {
                            "Send As: $($_.Trustee)"
                        }
                    )

                    $sendOnBehalfOnTarget = @(
                        $mailbox.GrantSendOnBehalfTo |
                        ForEach-Object {
                            if ($_){ "Send on Behalf: $_" }
                        }
                    )

                    $delegatesOnTarget = @(
                        $fullAccessOnTarget +
                        $sendAsOnTarget +
                        $sendOnBehalfOnTarget
                    ) | Sort-Object -Unique

                    Write-List -Items $delegatesOnTarget -NoneText "No direct delegates found"

                    if ($delegatesOnTarget.Count -gt 0) {
                        Add-Finding "$($delegatesOnTarget.Count) direct mailbox delegate permission(s) depend on this mailbox."
                    }
                }
                catch {
                    Write-FKReportLine "- Delegate lookup failed: $($_.Exception.Message)"
                    Add-Gap "Delegate lookup on target mailbox failed: $($_.Exception.Message)"
                }

                # Distribution / mail-enabled group ownership
                Write-FKReportLine ""
                Write-FKReportLine "EXCHANGE GROUP OWNERSHIP"

                try {
                    $ownedDgs = @(
                        Get-DistributionGroup -ResultSize Unlimited -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
                        Where-Object {
                            Test-ExoIdentityMatch -Value $_.ManagedBy -Tokens $exoIdentityTokens
                        } |
                        Select-Object -ExpandProperty DisplayName |
                        Sort-Object -Unique
                    )

                    Write-List -Items $ownedDgs -NoneText "No Exchange distribution/mail-enabled groups owned"

                    if ($ownedDgs.Count -gt 0) {
                        Add-Finding "$($ownedDgs.Count) Exchange distribution/mail-enabled group(s) are owned by this user."
                    }
                }
                catch {
                    Write-FKReportLine "- Lookup failed: $($_.Exception.Message)"
                    Add-Gap "Exchange group ownership lookup failed: $($_.Exception.Message)"
                }

                # Permissions the user holds on other recipients/mailboxes
                Write-FKReportLine ""
                Write-FKReportLine "ACCESS HELD BY THIS USER"

                $heldAccess = @()

                try {
                    $sendAsHeld = @(
                        Get-RecipientPermission -Trustee $UPN -ResultSize Unlimited -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
                        Where-Object { $_.AccessRights -contains 'SendAs' } |
                        ForEach-Object {
                            "Send As: $($_.Identity)"
                        }
                    )

                    $heldAccess += $sendAsHeld
                }
                catch {
                    Add-Gap "Global Send As lookup failed: $($_.Exception.Message)"
                }

                try {
                    $allMailboxes = @(
                        Get-Mailbox -ResultSize Unlimited -ErrorAction Stop -WarningVariable +script:FKReportWarnings
                    )

                    $index = 0
                    foreach ($mbx in $allMailboxes) {
                        $index++

                        Write-Progress `
                            -Activity "Checking mailbox delegation" `
                            -Status "$index of $($allMailboxes.Count): $($mbx.DisplayName)" `
                            -PercentComplete (($index / [math]::Max($allMailboxes.Count,1)) * 100)

                        if ([string]$mbx.PrimarySmtpAddress -ieq [string]$mailbox.PrimarySmtpAddress) {
                            continue
                        }

                        try {
                            $fa = @(
                                Get-MailboxPermission -Identity $mbx.Identity -User $UPN -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
                                Where-Object {
                                    -not $_.IsInherited -and
                                    -not $_.Deny -and
                                    ($_.AccessRights -contains 'FullAccess')
                                }
                            )

                            if ($fa.Count -gt 0) {
                                $heldAccess += "Full Access: $($mbx.DisplayName) <$($mbx.PrimarySmtpAddress)>"
                            }
                        }
                        catch {
                            # No matching direct permission is normal for most mailboxes.
                        }

                        if (Test-ExoIdentityMatch -Value $mbx.GrantSendOnBehalfTo -Tokens $exoIdentityTokens) {
                            $heldAccess += "Send on Behalf: $($mbx.DisplayName) <$($mbx.PrimarySmtpAddress)>"
                        }
                    }

                    Write-Progress -Activity "Checking mailbox delegation" -Completed
                }
                catch {
                    Write-Progress -Activity "Checking mailbox delegation" -Completed
                    Add-Gap "Cross-mailbox delegation scan failed: $($_.Exception.Message)"
                }

                $heldAccess = @($heldAccess | Sort-Object -Unique)

                Write-List -Items $heldAccess -NoneText "No direct Full Access / Send As / Send on Behalf dependencies found"

                if ($heldAccess.Count -gt 0) {
                    Add-Finding "$($heldAccess.Count) direct permission(s) are held by this user on other Exchange recipients."
                }

                # Transport rule references
                Write-FKReportLine ""
                Write-FKReportLine "TRANSPORT RULE REFERENCES"

                try {
                    $needles = @(
                        @($UPN) +
                        @($smtpAliases) +
                        @([string]$mailbox.PrimarySmtpAddress)
                    ) |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                    Select-Object -Unique

                    $transportHits = @()

                    foreach ($rule in @(Get-TransportRule -ErrorAction Stop -WarningVariable +script:FKReportWarnings)) {
                        $ruleText = ($rule | Format-List * | Out-String)

                        foreach ($needle in $needles) {
                            if ($ruleText -match [regex]::Escape($needle)) {
                                $transportHits += $rule.Name
                                break
                            }
                        }
                    }

                    $transportHits = @($transportHits | Sort-Object -Unique)

                    Write-List -Items $transportHits -NoneText "No direct address references found"

                    if ($transportHits.Count -gt 0) {
                        Add-Finding "$($transportHits.Count) transport rule(s) reference this user's known email address."
                    }
                }
                catch {
                    Write-FKReportLine "- Lookup failed: $($_.Exception.Message)"
                    Add-Gap "Transport rule scan failed: $($_.Exception.Message)"
                }

                # Data / retention
                Write-FKReportLine ""
                Write-FKReportLine "MAILBOX DATA / RETENTION"

                try {
                    $stats = Get-MailboxStatistics -Identity $UPN -ErrorAction Stop -WarningVariable +script:FKReportWarnings

                    Write-FKReportLine "- Item count: $($stats.ItemCount)"
                    Write-FKReportLine "- Total size: $($stats.TotalItemSize)"
                    Write-FKReportLine "- Last logon: $($stats.LastLogonTime)"
                }
                catch {
                    Write-FKReportLine "- Mailbox statistics unavailable: $($_.Exception.Message)"
                    Add-Gap "Mailbox statistics lookup failed: $($_.Exception.Message)"
                }

                Write-FKReportLine "- Archive status: $($mailbox.ArchiveStatus)"
                Write-FKReportLine "- Litigation hold: $($mailbox.LitigationHoldEnabled)"
                Write-FKReportLine "- Retention hold: $($mailbox.RetentionHoldEnabled)"
                Write-FKReportLine "- Retention policy: $($mailbox.RetentionPolicy)"

                $inPlaceHolds = @($mailbox.InPlaceHolds | Where-Object { $_ })

                if ($inPlaceHolds.Count -gt 0) {
                    Write-FKReportLine "- In-place holds:"
                    foreach ($hold in $inPlaceHolds) {
                        Write-FKReportLine "  $hold"
                    }
                }
                else {
                    Write-FKReportLine "- In-place holds: None"
                }

                if ($mailbox.LitigationHoldEnabled -or
                    $mailbox.RetentionHoldEnabled -or
                    $inPlaceHolds.Count -gt 0) {

                    Add-Finding "Mailbox retention/hold configuration requires review before deletion."
                }
            }
        }
        catch {
            Write-FKReportLine "- Exchange Online check failed: $($_.Exception.Message)"
            Add-Gap "Exchange Online check failed: $($_.Exception.Message)"
        }
    }
    else {
        Write-FKReportLine "- ExchangeOnlineManagement module not installed"
        Add-Gap "ExchangeOnlineManagement module is unavailable."
    }

    # -------------------------------------------------------------------------
    # MICROSOFT GRAPH / ENTRA
    # -------------------------------------------------------------------------

    Write-Section "ENTRA / MICROSOFT 365"

    if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

            $requiredScopes = @(
                'User.Read.All',
                'Group.Read.All',
                'Directory.Read.All'
            )

            $existingGraph = Get-MgContext -ErrorAction SilentlyContinue
            $needGraphConnect = $false

            if (-not $existingGraph) {
                $needGraphConnect = $true
                $GraphConnectedHere = $true
            }
            else {
                foreach ($scope in $requiredScopes) {
                    if ($existingGraph.Scopes -notcontains $scope) {
                        $needGraphConnect = $true
                        break
                    }
                }
            }

            if ($needGraphConnect) {
                Connect-MgGraph -Scopes $requiredScopes -NoWelcome -ErrorAction Stop
            }

            $encodedUPN = [uri]::EscapeDataString($UPN)
            $userUri = "https://graph.microsoft.com/v1.0/users/${encodedUPN}?`$select=id,displayName,userPrincipalName,accountEnabled,onPremisesSyncEnabled,onPremisesImmutableId,mail"

            $graphUser = Invoke-MgGraphRequest -Method GET -Uri $userUri -ErrorAction Stop

            Write-FKReportLine "Found:   $($graphUser.displayName)"
            Write-FKReportLine "Enabled: $($graphUser.accountEnabled)"
            Write-FKReportLine "Synced:  $($graphUser.onPremisesSyncEnabled)"

            if ($graphUser.onPremisesSyncEnabled -eq $true) {
                Write-FKReportLine "- This is an on-premises-synchronized Entra object."
            }

            $graphId = [string]$graphUser.id

            # Direct cloud group membership
            Write-FKReportLine ""
            Write-FKReportLine "CLOUD GROUP MEMBERSHIPS"

            try {
                $memberUri = "https://graph.microsoft.com/v1.0/users/$graphId/memberOf/microsoft.graph.group?`$select=id,displayName,mail,groupTypes,mailEnabled,securityEnabled"
                $cloudMemberships = @(Get-GraphPaged -Uri $memberUri)

                $cloudMembershipText = @(
                    $cloudMemberships |
                    ForEach-Object {
                        $type = 'Entra Group'
                        if (@($_.groupTypes) -contains 'Unified') {
                            $type = 'Microsoft 365 Group'
                        }

                        if ($_.mail) {
                            "$($_.displayName) [$type] <$($_.mail)>"
                        }
                        else {
                            "$($_.displayName) [$type]"
                        }
                    } |
                    Sort-Object -Unique
                )

                Write-List -Items $cloudMembershipText -NoneText "No direct cloud group memberships"
            }
            catch {
                Write-FKReportLine "- Lookup failed: $($_.Exception.Message)"
                Add-Gap "Cloud group membership lookup failed: $($_.Exception.Message)"
            }

            # Owned M365 / Teams / Entra groups
            Write-FKReportLine ""
            Write-FKReportLine "GROUP / TEAM OWNERSHIP"

            try {
                $ownedGroupsUri = "https://graph.microsoft.com/v1.0/users/$graphId/ownedObjects/microsoft.graph.group?`$select=id,displayName,mail,groupTypes,resourceProvisioningOptions,mailEnabled,securityEnabled"
                $ownedGroups = @(Get-GraphPaged -Uri $ownedGroupsUri)

                $ownedGroupText = @()

                foreach ($group in $ownedGroups) {
                    $type = 'Entra Group'

                    if (@($group.resourceProvisioningOptions) -contains 'Team') {
                        $type = 'Team'
                    }
                    elseif (@($group.groupTypes) -contains 'Unified') {
                        $type = 'Microsoft 365 Group'
                    }
                    elseif ($group.mailEnabled -and $group.securityEnabled) {
                        $type = 'Mail-enabled Security Group'
                    }
                    elseif ($group.securityEnabled) {
                        $type = 'Security Group'
                    }

                    if ($group.mail) {
                        $ownedGroupText += "$($group.displayName) [$type] <$($group.mail)>"
                    }
                    else {
                        $ownedGroupText += "$($group.displayName) [$type]"
                    }
                }

                $ownedGroupText = @($ownedGroupText | Sort-Object -Unique)

                Write-List -Items $ownedGroupText -NoneText "No Graph-visible groups or Teams owned"

                if ($ownedGroupText.Count -gt 0) {
                    Add-Finding "$($ownedGroupText.Count) Graph-visible group/Team ownership assignment(s) exist."
                }
            }
            catch {
                Write-FKReportLine "- Lookup failed: $($_.Exception.Message)"
                Add-Gap "Graph group ownership lookup failed: $($_.Exception.Message)"
            }

            # Owned apps/service principals
            Write-FKReportLine ""
            Write-FKReportLine "APPLICATION OWNERSHIP"

            try {
                $ownedObjectsUri = "https://graph.microsoft.com/v1.0/users/$graphId/ownedObjects?`$select=id,displayName"
                $ownedObjects = @(Get-GraphPaged -Uri $ownedObjectsUri)

                $ownedApps = @(
                    $ownedObjects |
                    Where-Object {
                        $_.'@odata.type' -eq '#microsoft.graph.application' -or
                        $_.'@odata.type' -eq '#microsoft.graph.servicePrincipal'
                    } |
                    ForEach-Object {
                        $kind = if ($_.'@odata.type' -eq '#microsoft.graph.application') {
                            'App Registration'
                        }
                        else {
                            'Service Principal'
                        }

                        "$($_.displayName) [$kind]"
                    } |
                    Sort-Object -Unique
                )

                Write-List -Items $ownedApps -NoneText "No app registrations or service principals owned"

                if ($ownedApps.Count -gt 0) {
                    Add-Finding "$($ownedApps.Count) application/service-principal ownership assignment(s) exist."
                }
            }
            catch {
                Write-FKReportLine "- Lookup failed: $($_.Exception.Message)"
                Add-Gap "Application ownership lookup failed: $($_.Exception.Message)"
            }

            # Direct enterprise app assignments
            Write-FKReportLine ""
            Write-FKReportLine "DIRECT ENTERPRISE APP ASSIGNMENTS"

            try {
                $appRoleUri = "https://graph.microsoft.com/v1.0/users/$graphId/appRoleAssignments?`$select=principalId,resourceDisplayName,resourceId,appRoleId"
                $appAssignments = @(Get-GraphPaged -Uri $appRoleUri)

                $directAppAssignments = @(
                    $appAssignments |
                    Where-Object { [string]$_.principalId -eq $graphId } |
                    ForEach-Object {
                        "$($_.resourceDisplayName) | AppRoleId=$($_.appRoleId)"
                    } |
                    Sort-Object -Unique
                )

                Write-List -Items $directAppAssignments -NoneText "No direct enterprise app role assignments"

                if ($directAppAssignments.Count -gt 0) {
                    Add-Finding "$($directAppAssignments.Count) direct enterprise app assignment(s) exist."
                }
            }
            catch {
                Write-FKReportLine "- Lookup failed: $($_.Exception.Message)"
                Add-Gap "Enterprise app assignment lookup failed: $($_.Exception.Message)"
            }

            # Licenses
            Write-FKReportLine ""
            Write-FKReportLine "LICENSES"

            try {
                $licenseUri = "https://graph.microsoft.com/v1.0/users/$graphId/licenseDetails?`$select=skuPartNumber,skuId"
                $licenses = @(Get-GraphPaged -Uri $licenseUri)

                $licenseText = @(
                    $licenses |
                    ForEach-Object {
                        if ($_.skuPartNumber) {
                            [string]$_.skuPartNumber
                        }
                        else {
                            [string]$_.skuId
                        }
                    } |
                    Sort-Object -Unique
                )

                Write-List -Items $licenseText -NoneText "No licenses assigned"
            }
            catch {
                Write-FKReportLine "- Lookup failed: $($_.Exception.Message)"
                Add-Gap "License lookup failed: $($_.Exception.Message)"
            }
        }
        catch {
            Write-FKReportLine "- Microsoft Graph check failed: $($_.Exception.Message)"
            Add-Gap "Microsoft Graph check failed: $($_.Exception.Message)"
        }
    }
    else {
        Write-FKReportLine "- Microsoft.Graph.Authentication module not installed"
        Add-Gap "Microsoft.Graph.Authentication module is unavailable."
    }

    # -------------------------------------------------------------------------
    # LIMITATIONS / RESULT
    # -------------------------------------------------------------------------

    Write-Section "NOT CHECKED"
    Write-FKReportLine "- OneDrive / SharePoint site ownership or file sharing"
    Write-FKReportLine "- Local Windows services or scheduled tasks using this account"
    Write-FKReportLine "- Third-party applications, SaaS integrations, scripts, or stored credentials"
    Write-FKReportLine "- Indirect mailbox access inherited through security groups"

    Write-Section "RESULT"

    if ($script:Findings.Count -eq 0 -and $script:Gaps.Count -eq 0) {
        Write-FKReportLine "CLEAN IN CHECKED AREAS"
        Write-FKReportLine "No dependency requiring review was found by this script."
    }
    else {
        Write-FKReportLine "REVIEW BEFORE DELETE"

        if ($script:Findings.Count -gt 0) {
            Write-FKReportLine ""
            Write-FKReportLine "Dependencies found:"
            foreach ($finding in $script:Findings) {
                Write-FKReportLine "- $finding"
            }
        }

        if ($script:Gaps.Count -gt 0) {
            Write-FKReportLine ""
            Write-FKReportLine "Checks incomplete:"
            foreach ($gap in $script:Gaps) {
                Write-FKReportLine "- $gap"
            }
        }
    }
}
catch {
    Write-FKReportLine ""
    Write-FKReportLine "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Offer-FKDesktopReport -Title 'GET-USER-PREDELETE-CHECK'

    Write-Progress -Activity "Checking mailbox delegation" -Completed -ErrorAction SilentlyContinue

    # Pause before cleanup so the console cannot disappear immediately after
    # the RESULT section if a module cleanup call behaves unexpectedly.
    Pause-End

    if ($ExoConnectedHere) {
        try {
            Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch {}
    }

    if ($GraphConnectedHere) {
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        }
        catch {}
    }
}
