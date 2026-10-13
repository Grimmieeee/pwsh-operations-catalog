#Requires -Version 5.1
<#
Standalone versions of the FIELD KIT profile's Git check/send/grab commands.
Run in a terminal. Check is read-only and uses locally known remote state (no fetch).
Push previews work and requires typed approval before staging, committing or pushing.
Filename checks are not a secret scanner. Review the full diff before publishing.
Pull refuses local changes and uses --ff-only; it never force-resets or auto-stashes.
.EXAMPLE
.\git-repo.ps1 -Action Check -Details
.EXAMPLE
.\git-repo.ps1 -Action Push -Message 'Update tools'
.EXAMPLE
.\git-repo.ps1 -Action Pull -Path 'C:\path\repo'
#>
[CmdletBinding()]
param(
    [ValidateSet('Check','Push','Pull')][string]$Action = 'Check',
    [string]$Path = (Get-Location).Path,
    [switch]$Details,
    [string]$Message
)
$ErrorActionPreference = 'Stop'
function Get-FieldKitGitRepo {
    $repo = @(
        git.exe rev-parse --show-toplevel 2>$null
    ) | Select-Object -First 1

    if (
        $LASTEXITCODE -ne 0 -or
        [string]::IsNullOrWhiteSpace([string]$repo)
    ) {
        return $null
    }

    try {
        return [System.IO.Path]::GetFullPath(([string]$repo).Trim())
    }
    catch {
        return ([string]$repo).Trim()
    }
}

function Get-FieldKitGitPushState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repo
    )

    $branch = @(
        git.exe -C $Repo branch --show-current 2>$null
    ) | Select-Object -First 1

    $upstream = @(
        git.exe -C $Repo rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
    ) | Select-Object -First 1

    if (
        $LASTEXITCODE -eq 0 -and
        -not [string]::IsNullOrWhiteSpace([string]$upstream)
    ) {
        $counts = @(
            git.exe -C $Repo rev-list --left-right --count 'HEAD...@{u}' 2>$null
        ) | Select-Object -First 1

        $ahead = 0
        $behind = 0

        if ($LASTEXITCODE -ne 0) { throw 'Could not compare the upstream state.' }
        if ($counts -match '^\s*(\d+)\s+(\d+)\s*$') {
            $ahead = [int]$Matches[1]
            $behind = [int]$Matches[2]
        } else { throw 'Could not parse upstream counts.' }

        return [pscustomobject]@{
            Branch      = [string]$branch
            HasUpstream = $true
            Upstream    = [string]$upstream
            Ahead       = $ahead
            Behind      = $behind
            LogArgs     = @("$upstream..HEAD")
        }
    }

    $aheadRaw = @(
        git.exe -C $Repo rev-list --count HEAD --not --remotes 2>$null
    ) | Select-Object -First 1

    $ahead = 0
    [void][int]::TryParse([string]$aheadRaw, [ref]$ahead)

    return [pscustomobject]@{
        Branch      = [string]$branch
        HasUpstream = $false
        Upstream    = ''
        Ahead       = $ahead
        Behind      = 0
        LogArgs     = @('HEAD', '--not', '--remotes')
    }
}

function Get-FieldKitGitChanges {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repo
    )

    $result = @(git.exe -C $Repo -c core.quotepath=false status --porcelain=v1 -uall)
    if ($LASTEXITCODE -ne 0) { throw 'Git status failed; no changes were made.' }
    return $result
}

function Get-FieldKitGitSafetyHits {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repo
    )

    $changes = @(Get-FieldKitGitChanges -Repo $Repo)
    $hits = @()

    $blockedExtensions = @(
        '.pfx',
        '.p12',
        '.key',
        '.pem'
    )

    $reviewExtensions = @(
        '.cer',
        '.crt',
        '.csv',
        '.xlsx',
        '.xls',
        '.zip',
        '.7z',
        '.pdf',
        '.docx',
        '.doc'
    )

    foreach ($line in $changes) {
        if (
            [string]::IsNullOrWhiteSpace([string]$line) -or
            $line.Length -lt 4
        ) {
            continue
        }

        $status = $line.Substring(0,2)

        # Deleted files cannot accidentally publish new local data.
        if ($status -match '^ D|^D ') {
            continue
        }

        $file = $line.Substring(3).Trim().Trim('"')

        if ($file -match ' -> ') {
            $file = ($file -split ' -> ')[-1].Trim().Trim('"')
        }

        $leaf = [System.IO.Path]::GetFileName($file)
        $ext  = [System.IO.Path]::GetExtension($file).ToLowerInvariant()

        $level = ''
        $reason = ''

        $relativePath = $file -replace '/', [System.IO.Path]::DirectorySeparatorChar
        $fullPath = Join-Path $Repo $relativePath

        if (
            (Test-Path -LiteralPath $fullPath -PathType Container) -and
            (Test-Path -LiteralPath (Join-Path $fullPath '.git'))
        ) {
            $level = 'BLOCK'
            $reason = 'Nested Git repository'
        }
        elseif ($blockedExtensions -contains $ext) {
            $level = 'BLOCK'
            $reason = 'Private key / certificate material'
        }
        elseif (
            $leaf -match '^\.env(?:\..+)?$' -or
            $leaf -match '(?i)credentials?' -or
            $leaf -match '(?i)secrets?' -or
            $leaf -match '(?i)passwords?' -or
            $leaf -match '(?i)private[-_ ]?key'
        ) {
            $level = 'BLOCK'
            $reason = 'Credential / secret-style filename'
        }
        elseif ($reviewExtensions -contains $ext) {
            $level = 'REVIEW'
            $reason = 'Generated / export / reference file type'
        }

        if ($level) {
            $hits += [pscustomobject]@{
                Level  = $level
                File   = $file
                Reason = $reason
            }
        }
    }

    return @(
        $hits |
        Sort-Object `
            @{ Expression = { if ($_.Level -eq 'BLOCK') { 0 } else { 1 } } },
            File -Unique
    )
}

function Write-FieldKitGitChanges {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repo,

        [switch]$Details
    )

    $changes = @(Get-FieldKitGitChanges -Repo $Repo)

    $newCount      = 0
    $modifiedCount = 0
    $deletedCount  = 0
    $renamedCount  = 0
    $otherCount    = 0

    foreach ($line in $changes) {
        if (
            [string]::IsNullOrWhiteSpace([string]$line) -or
            $line.Length -lt 3
        ) {
            continue
        }

        $status = $line.Substring(0,2)

        switch -Regex ($status) {
            '^\?\?'      { $newCount++;      continue }
            '^ A|^A '    { $newCount++;      continue }
            '^ M|^M |MM' { $modifiedCount++; continue }
            '^ D|^D '    { $deletedCount++;  continue }
            '^R |^ R'    { $renamedCount++;  continue }
            default      { $otherCount++ }
        }
    }

    if (-not $Details) {
        if ($newCount -gt 0) {
            Write-Host ("NEW      // {0}" -f $newCount) -ForegroundColor Green
        }

        if ($modifiedCount -gt 0) {
            Write-Host ("MODIFIED // {0}" -f $modifiedCount) -ForegroundColor Magenta
        }

        if ($deletedCount -gt 0) {
            Write-Host ("DELETED  // {0}" -f $deletedCount) -ForegroundColor Red
        }

        if ($renamedCount -gt 0) {
            Write-Host ("RENAMED  // {0}" -f $renamedCount) -ForegroundColor Cyan
        }

        if ($otherCount -gt 0) {
            Write-Host ("OTHER    // {0}" -f $otherCount) -ForegroundColor Yellow
        }

        return
    }

    foreach ($line in $changes) {
        if (
            [string]::IsNullOrWhiteSpace([string]$line) -or
            $line.Length -lt 3
        ) {
            continue
        }

        $status = $line.Substring(0,2)
        $file   = $line.Substring(3)

        switch -Regex ($status) {
            '^\?\?'      { Write-Host "NEW      $file" -ForegroundColor Green;   continue }
            '^ A|^A '    { Write-Host "ADDED    $file" -ForegroundColor Green;   continue }
            '^ M|^M |MM' { Write-Host "MODIFIED $file" -ForegroundColor Magenta; continue }
            '^ D|^D '    { Write-Host "DELETED  $file" -ForegroundColor Red;     continue }
            '^R |^ R'    { Write-Host "RENAMED  $file" -ForegroundColor Cyan;    continue }
            default      { Write-Host "$status      $file" -ForegroundColor Yellow }
        }
    }
}

function Invoke-FieldKitGitCheck {
    param(
        [switch]$Details
    )

    $repo = Get-FieldKitGitRepo

    if (-not $repo) {
        Write-Host "[XX] Current location is not inside a Git repository." -ForegroundColor Red
        return
    }

    $changes = @(Get-FieldKitGitChanges -Repo $repo)
    $pushState = Get-FieldKitGitPushState -Repo $repo

    Write-Host ""
    Write-Host "REPO // $repo" -ForegroundColor Magenta
    Write-Host ". . . . . . . . . . . . . . . . . . . . ." -ForegroundColor DarkMagenta

    if ($pushState.Branch) {
        Write-Host ("BRANCH   // {0}" -f $pushState.Branch) -ForegroundColor DarkGray
    }

    Write-FieldKitGitChanges -Repo $repo -Details:$Details

    if ($pushState.Ahead -gt 0) {
        Write-Host ("PUSH     // {0} commit(s)" -f $pushState.Ahead) -ForegroundColor Cyan
    }

    if ($pushState.Behind -gt 0) {
        Write-Host ("PULL     // {0} commit(s)" -f $pushState.Behind) -ForegroundColor Yellow
    }

    if (-not $pushState.HasUpstream) {
        Write-Host "[!!] No upstream branch configured." -ForegroundColor Yellow
    }

    if ($Details -and $pushState.Ahead -gt 0) {
        if ($changes.Count -gt 0) {
            Write-Host ""
        }

        Write-Host ("COMMITS TO PUSH // {0}" -f $pushState.Ahead) -ForegroundColor Cyan

        $logArgs = @('log', '--oneline') + @($pushState.LogArgs)
        $commits = @(git.exe -C $repo @logArgs)

        foreach ($commit in $commits) {
            Write-Host "PENDING  $commit" -ForegroundColor Cyan
        }
    }

    if (
        $changes.Count -eq 0 -and
        $pushState.HasUpstream -and
        $pushState.Ahead -eq 0 -and
        $pushState.Behind -eq 0
    ) {
        Write-Host "[OK] Clean and synced with the currently known upstream state." -ForegroundColor Green
    }

    Write-Host ""

    if (-not $Details -and $changes.Count -gt 0) {
        Write-Host "Run this script with -Action Check -Details for the full file list." -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Invoke-FieldKitGitSend {
    param(
        [string]$Message
    )

    $repo = Get-FieldKitGitRepo

    if (-not $repo) {
        Write-Host "[XX] Current location is not inside a Git repository." -ForegroundColor Red
        return
    }

    $changes = @(Get-FieldKitGitChanges -Repo $repo)
    $pushState = Get-FieldKitGitPushState -Repo $repo

    $dirty = ($changes.Count -gt 0)
    $ahead = ($pushState.Ahead -gt 0)

    if (-not $dirty -and -not $ahead) {
        Write-Host "[OK] Nothing to send." -ForegroundColor Green
        return
    }

    Invoke-FieldKitGitCheck -Details

    # Important safety case:
    # committed work is already waiting to push, while unrelated local work also exists.
    if ($dirty -and $ahead) {
        Write-Host "[!!] This repo has BOTH uncommitted changes and committed work waiting to push." -ForegroundColor Yellow
        Write-Host "[!!] PUSH ONLY leaves the working tree untouched." -ForegroundColor Yellow
        Write-Host "[!!] SEND ALL stages/commits the current working tree, then pushes everything." -ForegroundColor Yellow
        Write-Host ""

        $choice = Read-Host "Type PUSH ONLY, SEND ALL, or anything else to cancel"

        if ($choice -eq 'PUSH ONLY') {
            Write-Host ""
            Write-Host "PUSHING // $repo" -ForegroundColor Magenta
            Write-Host ". . . . . . . . . . . . . . . . . . . . ." -ForegroundColor DarkMagenta

            git.exe -C $repo push

            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Existing commit(s) pushed. Working tree was not staged or committed." -ForegroundColor Green
            }
            else {
                Write-Host "[XX] Push failed." -ForegroundColor Red
            }

            return
        }

        if ($choice -ne 'SEND ALL') {
            Write-Host "[!!] Cancelled. Nothing staged, committed, or pushed." -ForegroundColor Yellow
            return
        }
    }

    if ($dirty) {
        $safetyHits = @(Get-FieldKitGitSafetyHits -Repo $repo)
        $blocked = @($safetyHits | Where-Object { $_.Level -eq 'BLOCK' })
        $review  = @($safetyHits | Where-Object { $_.Level -eq 'REVIEW' })

        if ($blocked.Count -gt 0) {
            Write-Host ""
            Write-Host "[XX] SEND BLOCKED" -ForegroundColor Red
            $blocked | Format-Table Level, File, Reason -AutoSize
            Write-Host "[XX] Remove, move, or ignore the blocked item(s), then run 'git send it' again." -ForegroundColor Red
            return
        }

        if ($review.Count -gt 0) {
            Write-Host ""
            Write-Host "[!!] PRE-COMMIT REVIEW" -ForegroundColor Yellow
            $review | Format-Table Level, File, Reason -AutoSize
            Write-Host "[!!] These may be intentional, but confirm before publishing them." -ForegroundColor Yellow
            $confirm = Read-Host "Type SEND IT ANYWAY to include them"

            if ($confirm -ne 'SEND IT ANYWAY') {
                Write-Host "[!!] Cancelled. Nothing staged, committed, or pushed." -ForegroundColor Yellow
                return
            }
        }
        elseif (-not ($dirty -and $ahead)) {
            $confirm = Read-Host "Type SEND IT to stage, commit, and push"

            if ($confirm -ne 'SEND IT') {
                Write-Host "[!!] Cancelled. Nothing staged, committed, or pushed." -ForegroundColor Yellow
                return
            }
        }

        if ([string]::IsNullOrWhiteSpace($Message)) {
            $repoName = Split-Path $repo -Leaf
            $defaultMessage = "Update $repoName files"
            $enteredMessage = Read-Host "Commit message [${defaultMessage}]"

            if ([string]::IsNullOrWhiteSpace($enteredMessage)) {
                $Message = $defaultMessage
            }
            else {
                $Message = $enteredMessage.Trim()
            }
        }

        git.exe -C $repo add -A

        if ($LASTEXITCODE -ne 0) {
            Write-Host "[XX] Stage failed. Nothing pushed." -ForegroundColor Red
            return
        }

        git.exe -C $repo commit -m $Message

        if ($LASTEXITCODE -ne 0) {
            Write-Host "[XX] Commit failed. Nothing pushed." -ForegroundColor Red
            return
        }
    }
    else {
        $confirm = Read-Host "Type SEND IT to push the committed work shown above"

        if ($confirm -ne 'SEND IT') {
            Write-Host "[!!] Cancelled. Nothing pushed." -ForegroundColor Yellow
            return
        }
    }

    Write-Host ""
    Write-Host "PUSHING // $repo" -ForegroundColor Magenta
    Write-Host ". . . . . . . . . . . . . . . . . . . . ." -ForegroundColor DarkMagenta

    git.exe -C $repo push

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Sent." -ForegroundColor Green
        git.exe -C $repo status -sb
    }
    else {
        Write-Host "[XX] Push failed." -ForegroundColor Red
    }
}

function Invoke-FieldKitGitGrab {
    $repo = Get-FieldKitGitRepo

    if (-not $repo) {
        Write-Host "[XX] Current location is not inside a Git repository." -ForegroundColor Red
        return
    }

    $changes = @(Get-FieldKitGitChanges -Repo $repo)

    if ($changes.Count -gt 0) {
        Write-Host "[!!] Local changes found. Grab cancelled so your working tree is not touched." -ForegroundColor Yellow
        Write-Host ""
        Invoke-FieldKitGitCheck -Details
        return
    }

    Write-Host ""
    Write-Host "GRABBING // $repo" -ForegroundColor Magenta
    Write-Host ". . . . . . . . . . . . . . . . . . . . ." -ForegroundColor DarkMagenta

    git.exe -C $repo pull --ff-only

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Grab complete." -ForegroundColor Green
        git.exe -C $repo status -sb
    }
    else {
        Write-Host "[XX] Grab failed. No merge commit was created." -ForegroundColor Red
    }

    Write-Host ""
}


$locationChanged = $false
try {
    [void](Get-Command git.exe -CommandType Application -ErrorAction Stop)
    Push-Location -LiteralPath $Path -ErrorAction Stop
    $locationChanged = $true
    switch ($Action) {
        'Check' { Invoke-FieldKitGitCheck -Details:$Details }
        'Push' { Invoke-FieldKitGitSend -Message $Message }
        'Pull' { Invoke-FieldKitGitGrab }
    }
} catch {
    Write-Host ("[XX] Git operation failed: " + $_.Exception.Message) -ForegroundColor Red
} finally {
    if ($locationChanged) { Pop-Location }
}
