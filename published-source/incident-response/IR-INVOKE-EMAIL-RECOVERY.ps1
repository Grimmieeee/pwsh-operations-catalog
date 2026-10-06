#Requires -Version 5.1

<#
IR RECOVERY - RESTORE EMAILS

OBJECTIVE
Move messages from an attacker-used mailbox folder to a recovery folder.

CHANGE-MAKING
- Can create one target folder at the mailbox root
- Can move selected messages
- Preview and confirmation occur before changes
- Post-change validation is performed

GRAPH ACCESS MODEL
Uses delegated Mail.ReadWrite.Shared.
The signed-in operator must already have access to the target mailbox/folders.
Admin role alone does not grant Graph delegated mailbox access.
#>

param(
    [string]$UPN,
    [string]$SourceFolder = "RSS Subscriptions",
    [string]$TargetFolder = "Restored Messages",
    [ValidateRange(1,8760)]
    [int]$LookbackHours = 24
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

function Ensure-GraphModule {
    if (-not (Get-Module -ListAvailable -Name "Microsoft.Graph.Authentication")) {
        INFO "Installing Microsoft.Graph.Authentication..."

        Install-Module `
            -Name "Microsoft.Graph.Authentication" `
            -Scope CurrentUser `
            -Force `
            -AllowClobber `
            -ErrorAction Stop
    }

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
}

function Test-GraphScopes {
    param(
        $Context,
        [string[]]$RequiredScopes
    )

    if (-not $Context) {
        return $false
    }

    foreach ($scope in $RequiredScopes) {
        if (@($Context.Scopes) -notcontains $scope) {
            return $false
        }
    }

    return $true
}

function Connect-GraphAuto {
    param([string[]]$Scopes)

    Ensure-GraphModule

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        $context -and
        (Test-GraphScopes -Context $context -RequiredScopes $Scopes)
    ) {
        OK "Graph session reused"
        return
    }

    if ($context) {
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
        }
    }

    Write-Host "Graph: Connecting..."

    $command = Get-Command Connect-MgGraph -ErrorAction Stop
    $parameters = @{
        Scopes      = $Scopes
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("ContextScope")) {
        $parameters["ContextScope"] = "CurrentUser"
    }

    if ($command.Parameters.ContainsKey("NoWelcome")) {
        $parameters["NoWelcome"] = $true
    }

    Connect-MgGraph @parameters | Out-Null

    $context = Get-MgContext -ErrorAction Stop

    if (
        -not (Test-GraphScopes -Context $context -RequiredScopes $Scopes)
    ) {
        throw "Graph connected without all required delegated scopes."
    }

    OK "Graph connected"
}

function Invoke-GraphGet {
    param([string]$Uri)

    return Invoke-MgGraphRequest `
        -Method GET `
        -Uri $Uri `
        -ErrorAction Stop
}

function Invoke-GraphPost {
    param(
        [string]$Uri,
        [hashtable]$Body
    )

    return Invoke-MgGraphRequest `
        -Method POST `
        -Uri $Uri `
        -Body ($Body | ConvertTo-Json -Depth 10) `
        -ContentType "application/json" `
        -ErrorAction Stop
}

function Get-GraphPaged {
    param([string]$Uri)

    $items = New-Object System.Collections.Generic.List[object]
    $next = $Uri

    while ($next) {
        $page = Invoke-GraphGet -Uri $next

        if ($null -eq $page -or $null -eq $page.value) {
            throw "Graph returned an incomplete paged response."
        }

        foreach ($item in @($page.value)) {
            $items.Add($item) | Out-Null
        }

        $next = [string]$page.'@odata.nextLink'
    }

    return @($items)
}

function Encode-UrlValue {
    param([string]$Value)

    return [System.Uri]::EscapeDataString($Value)
}

function Escape-OData {
    param([string]$Value)

    return ($Value -replace "'", "''")
}

function Get-MailboxFolders {
    param([string]$MailboxUPN)

    $encodedUPN = Encode-UrlValue $MailboxUPN
    $folders = New-Object System.Collections.Generic.List[object]
    $visited = New-Object 'System.Collections.Generic.HashSet[string]'

    function Add-ChildFolders {
        param(
            [string]$ParentId,
            [string]$ParentPath
        )

        $encodedParent = Encode-UrlValue $ParentId
        $uri = "https://graph.microsoft.com/v1.0/users/$encodedUPN/mailFolders/$encodedParent/childFolders?includeHiddenFolders=true&`$top=200&`$select=id,displayName,parentFolderId,totalItemCount"
        $children = @(Get-GraphPaged -Uri $uri)

        foreach ($child in $children) {
            if (-not $visited.Add([string]$child.id)) {
                continue
            }

            $path = "$ParentPath\$($child.displayName)"

            $folders.Add([PSCustomObject]@{
                Id             = [string]$child.id
                DisplayName    = [string]$child.displayName
                Path           = $path
                TotalItemCount = $child.totalItemCount
            })

            Add-ChildFolders `
                -ParentId ([string]$child.id) `
                -ParentPath $path
        }
    }

    $rootUri = "https://graph.microsoft.com/v1.0/users/$encodedUPN/mailFolders?includeHiddenFolders=true&`$top=200&`$select=id,displayName,parentFolderId,totalItemCount"
    $roots = @(Get-GraphPaged -Uri $rootUri)

    foreach ($root in $roots) {
        if (-not $visited.Add([string]$root.id)) {
            continue
        }

        $path = [string]$root.displayName

        $folders.Add([PSCustomObject]@{
            Id             = [string]$root.id
            DisplayName    = [string]$root.displayName
            Path           = $path
            TotalItemCount = $root.totalItemCount
        })

        Add-ChildFolders `
            -ParentId ([string]$root.id) `
            -ParentPath $path
    }

    return @($folders)
}

function Resolve-Folder {
    param(
        [array]$Folders,
        [string]$Name,
        [string]$Label
    )

    $matches = @(
        $Folders |
        Where-Object {
            $_.DisplayName -eq $Name -or
            $_.Path -eq $Name
        }
    )

    if ($matches.Count -eq 0) {
        return $null
    }

    if ($matches.Count -eq 1) {
        return $matches[0]
    }

    WARN "Multiple $Label folders match '$Name'."

    for ($i = 0; $i -lt $matches.Count; $i++) {
        Write-Host "[$($i + 1)] $($matches[$i].Path)"
    }

    $choice = Read-Host "Choose $Label folder number"
    $index = 0

    if (
        [int]::TryParse($choice, [ref]$index) -and
        $index -ge 1 -and
        $index -le $matches.Count
    ) {
        return $matches[$index - 1]
    }

    throw "A unique $Label folder was not selected."
}

function New-RootMailFolder {
    param(
        [string]$MailboxUPN,
        [string]$FolderName
    )

    if ($FolderName -match '[\\/]') {
        throw "Target path was not found. Automatic creation supports a single root-level folder name only."
    }

    $encodedUPN = Encode-UrlValue $MailboxUPN

    return Invoke-GraphPost `
        -Uri "https://graph.microsoft.com/v1.0/users/$encodedUPN/mailFolders" `
        -Body @{ displayName = $FolderName }
}

function Get-FolderMessages {
    param(
        [string]$MailboxUPN,
        [string]$FolderId,
        [datetime]$SinceUtc
    )

    $encodedUPN = Encode-UrlValue $MailboxUPN
    $encodedFolder = Encode-UrlValue $FolderId
    $filter = "receivedDateTime ge $($SinceUtc.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
    $uri = "https://graph.microsoft.com/v1.0/users/$encodedUPN/mailFolders/$encodedFolder/messages?`$filter=$(Encode-UrlValue $filter)&`$top=100&`$select=id,subject,receivedDateTime,from,internetMessageId"

    return @(Get-GraphPaged -Uri $uri)
}

function Move-MailMessage {
    param(
        [string]$MailboxUPN,
        [string]$MessageId,
        [string]$DestinationId
    )

    $encodedUPN = Encode-UrlValue $MailboxUPN
    $encodedMessage = Encode-UrlValue $MessageId

    return Invoke-GraphPost `
        -Uri "https://graph.microsoft.com/v1.0/users/$encodedUPN/messages/$encodedMessage/move" `
        -Body @{ destinationId = $DestinationId }
}

try {
    Write-Host "IR RECOVERY - RESTORE EMAILS"
    Write-Host "CHANGE-MAKING"
    Write-Host ""

    if (-not $UPN) {
        $UPN = (Read-Host "Mailbox UPN").Trim()
    }

    if (-not $UPN) {
        throw "Mailbox UPN is required."
    }

    $sourceInput = Read-Host "Source folder/path [default: $SourceFolder]"

    if ($sourceInput) {
        $SourceFolder = $sourceInput.Trim()
    }

    $targetInput = Read-Host "Target folder/path [default: $TargetFolder]"

    if ($targetInput) {
        $TargetFolder = $targetInput.Trim()
    }

    $hoursInput = Read-Host "Lookback hours by message received time [default: $LookbackHours]"

    if ($hoursInput) {
        $parsedHours = 0

        if ([int]::TryParse($hoursInput, [ref]$parsedHours)) {
            if ($parsedHours -lt 1) { $parsedHours = 1 }
            if ($parsedHours -gt 8760) { $parsedHours = 8760 }
            $LookbackHours = $parsedHours
        }
    }

    Section "CONNECT"

    Connect-GraphAuto -Scopes @(
        "Mail.ReadWrite.Shared"
    )

    Section "MAILBOX ACCESS"

    INFO "Graph delegated access requires the signed-in operator to already have access to the target mailbox."

    try {
        $folders = @(Get-MailboxFolders -MailboxUPN $UPN)
        OK "Mailbox folder inventory returned: $($folders.Count)"
    }
    catch {
        throw "Mailbox access failed for $UPN. Confirm delegated mailbox access and Mail.ReadWrite.Shared. $(Get-ShortError $_)"
    }

    $source = Resolve-Folder `
        -Folders $folders `
        -Name $SourceFolder `
        -Label "source"

    if (-not $source) {
        throw "Source folder not found: $SourceFolder"
    }

    $target = Resolve-Folder `
        -Folders $folders `
        -Name $TargetFolder `
        -Label "target"

    if (-not $target) {
        WARN "Target folder not found: $TargetFolder"

        if (-not (Confirm-Yes "Create target folder at mailbox root")) {
            throw "Target folder is unavailable."
        }

        $created = New-RootMailFolder `
            -MailboxUPN $UPN `
            -FolderName $TargetFolder

        if (-not $created -or -not $created.id) {
            throw "Target folder creation did not return a folder."
        }

        $target = [PSCustomObject]@{
            Id             = [string]$created.id
            DisplayName    = [string]$created.displayName
            Path           = [string]$created.displayName
            TotalItemCount = $created.totalItemCount
        }

        OK "Target folder created: $($target.Path)"
    }

    if ($source.Id -eq $target.Id) {
        throw "Source and target resolve to the same folder."
    }

    $sinceUtc = (Get-Date).ToUniversalTime().AddHours(-1 * $LookbackHours)

    Section "PLAN"

    Write-Host "Mailbox      : $UPN"
    Write-Host "Source       : $($source.Path)"
    Write-Host "Target       : $($target.Path)"
    Write-Host "Lookback     : $LookbackHours hours"
    Write-Host "Since UTC    : $($sinceUtc.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host ""
    INFO "Lookback filters message received time. Graph does not expose a generic folder-move timestamp for this recovery workflow."

    Section "PREVIEW"

    $messages = @(
        Get-FolderMessages `
            -MailboxUPN $UPN `
            -FolderId $source.Id `
            -SinceUtc $sinceUtc
    )

    if ($messages.Count -eq 0) {
        INFO "No messages found in the source folder for the selected received-time window."
        return
    }

    OK "Messages found: $($messages.Count)"
    Write-Host ""

    foreach ($message in ($messages | Sort-Object receivedDateTime -Descending | Select-Object -First 25)) {
        $from = ""

        try {
            $from = [string]$message.from.emailAddress.address
        }
        catch {
        }

        Write-Host "$($message.receivedDateTime) | $from | $($message.subject)"
    }

    if ($messages.Count -gt 25) {
        INFO "Only the 25 newest messages are shown."
    }

    Section "MOVE OPTIONS"

    Write-Host "[A] Move all previewed messages"
    Write-Host "[I] Review individually"
    Write-Host "[N] No changes"

    $mode = (Read-Host "Choose").Trim().ToUpperInvariant()

    $moved = New-Object System.Collections.Generic.List[object]
    $failed = New-Object System.Collections.Generic.List[object]
    $skipped = New-Object System.Collections.Generic.List[object]

    if ($mode -eq "A") {
        if (-not (Confirm-Type `
            -Prompt "This will move $($messages.Count) message(s) from '$($source.Path)' to '$($target.Path)'." `
            -Required "MOVE")) {
            WARN "Move cancelled."
            return
        }

        foreach ($message in $messages) {
            try {
                $newMessage = Move-MailMessage `
                    -MailboxUPN $UPN `
                    -MessageId ([string]$message.id) `
                    -DestinationId $target.Id

                if (-not $newMessage -or -not $newMessage.id) {
                    throw "Move API returned no destination message."
                }

                $moved.Add([PSCustomObject]@{
                    OriginalId        = [string]$message.id
                    NewId             = [string]$newMessage.id
                    InternetMessageId = [string]$message.internetMessageId
                    Subject           = [string]$message.subject
                })
            }
            catch {
                $failed.Add([PSCustomObject]@{
                    Subject = [string]$message.subject
                    Error   = Get-ShortError $_
                })
            }
        }
    }
    elseif ($mode -eq "I") {
        foreach ($message in $messages) {
            Write-Host ""
            Write-Host "Received: $($message.receivedDateTime)"
            Write-Host "Subject : $($message.subject)"

            if (-not (Confirm-Yes "Move this message")) {
                $skipped.Add($message)
                continue
            }

            try {
                $newMessage = Move-MailMessage `
                    -MailboxUPN $UPN `
                    -MessageId ([string]$message.id) `
                    -DestinationId $target.Id

                if (-not $newMessage -or -not $newMessage.id) {
                    throw "Move API returned no destination message."
                }

                $moved.Add([PSCustomObject]@{
                    OriginalId        = [string]$message.id
                    NewId             = [string]$newMessage.id
                    InternetMessageId = [string]$message.internetMessageId
                    Subject           = [string]$message.subject
                })

                OK "Moved"
            }
            catch {
                $failed.Add([PSCustomObject]@{
                    Subject = [string]$message.subject
                    Error   = Get-ShortError $_
                })

                WARN "Move failed"
            }
        }
    }
    else {
        WARN "No changes made."
        return
    }

    Section "POST-VALIDATION"

    $sourceAfter = @(
        Get-FolderMessages `
            -MailboxUPN $UPN `
            -FolderId $source.Id `
            -SinceUtc $sinceUtc
    )

    $targetAfter = @(
        Get-FolderMessages `
            -MailboxUPN $UPN `
            -FolderId $target.Id `
            -SinceUtc $sinceUtc
    )

    $sourceIds = @($sourceAfter | Select-Object -ExpandProperty id)
    $targetInternetIds = @(
        $targetAfter |
        Where-Object { $_.internetMessageId } |
        Select-Object -ExpandProperty internetMessageId
    )

    $stillInSource = 0
    $validatedInTarget = 0
    $validationUnknown = 0

    foreach ($item in $moved) {
        if ($sourceIds -contains $item.OriginalId) {
            $stillInSource++
        }

        if ($item.InternetMessageId) {
            if ($targetInternetIds -contains $item.InternetMessageId) {
                $validatedInTarget++
            }
        }
        else {
            $validationUnknown++
        }
    }

    if ($stillInSource -eq 0) {
        OK "Moved original message IDs are no longer present in the source selection."
    }
    else {
        WARN "$stillInSource moved original message ID(s) still appear in the source selection."
    }

    INFO "Moved messages confirmed in target by InternetMessageId: $validatedInTarget"
    INFO "Moved messages without InternetMessageId for target validation: $validationUnknown"

    Section "SUMMARY"

    $verdict = "RESTORE COMPLETED"

    if ($failed.Count -gt 0 -or $stillInSource -gt 0) {
        $verdict = "RESTORE COMPLETED WITH REVIEW ITEMS"
    }

    Write-Host "EMAIL RESTORE SUMMARY"
    Write-Host "--------------------------------------"
    Write-Host "Mailbox                : $UPN"
    Write-Host "Source                 : $($source.Path)"
    Write-Host "Target                 : $($target.Path)"
    Write-Host "Timestamp              : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "Found                  : $($messages.Count)"
    Write-Host "Moved                  : $($moved.Count)"
    Write-Host "Skipped                : $($skipped.Count)"
    Write-Host "Failed                 : $($failed.Count)"
    Write-Host "Still in source        : $stillInSource"
    Write-Host "Validated in target    : $validatedInTarget"
    Write-Host "Validation unavailable : $validationUnknown"
    Write-Host "Verdict                : $verdict"

    if ($failed.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed moves:"

        foreach ($item in $failed) {
            Write-Host "- $($item.Subject) | $($item.Error)"
        }
    }
}
catch {
    Write-Host ""
    FAIL (Get-ShortError $_)
}
finally {
    Pause-End
}
