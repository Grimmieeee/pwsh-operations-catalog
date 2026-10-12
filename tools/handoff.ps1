# HANDOFF
# Universal Git repository context-state snapshot
# Windows PowerShell 5.1+

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path = (Get-Location).Path,

    [string]$OutputDirectory = [Environment]::GetFolderPath('Desktop'),

    [switch]$Open
)

$ErrorActionPreference = 'Stop'

function Invoke-GitCapture {
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $output = @(& git.exe -C $Repo @Arguments 2>$null)

    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $output
    }
}

function Get-GitLine {
    param(
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $result = Invoke-GitCapture -Repo $Repo -Arguments $Arguments

    if ($result.ExitCode -ne 0 -or $result.Output.Count -eq 0) {
        return $null
    }

    ([string]$result.Output[0]).Trim()
}

function Add-MarkdownList {
    param(
        [Parameter(Mandatory = $true)][System.Text.StringBuilder]$Builder,
        [object[]]$Items,
        [string]$EmptyText = 'none'
    )

    if ($null -eq $Items -or @($Items).Count -eq 0) {
        [void]$Builder.AppendLine("- $EmptyText")
        return
    }

    foreach ($item in @($Items)) {
        [void]$Builder.AppendLine("- $item")
    }
}

if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    throw 'git.exe was not found in PATH.'
}

$item = Get-Item -LiteralPath $Path -ErrorAction Stop
$startPath = if ($item.PSIsContainer) { $item.FullName } else { $item.Directory.FullName }

$repo = Get-GitLine -Repo $startPath -Arguments @('rev-parse', '--show-toplevel')

if ([string]::IsNullOrWhiteSpace($repo)) {
    throw "No Git repository found for: $Path"
}

$repo = [System.IO.Path]::GetFullPath($repo)
$project = Split-Path -Leaf $repo

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

$safeProject = $project -replace '[^a-zA-Z0-9._-]', '-'
$snapshotPath = Join-Path $OutputDirectory ("HANDOFF-SNAPSHOT-{0}.md" -f $safeProject)

$previousHead = $null

if (Test-Path -LiteralPath $snapshotPath) {
    $previousMatch = Select-String -LiteralPath $snapshotPath -Pattern '^- HEAD: ([0-9a-fA-F]{40})$' |
        Select-Object -First 1

    if ($previousMatch) {
        $previousHead = $previousMatch.Matches[0].Groups[1].Value
    }
}

$branch = Get-GitLine -Repo $repo -Arguments @('branch', '--show-current')
if ([string]::IsNullOrWhiteSpace($branch)) {
    $branch = '(detached HEAD)'
}

$head = Get-GitLine -Repo $repo -Arguments @('rev-parse', 'HEAD')
$shortHead = Get-GitLine -Repo $repo -Arguments @('rev-parse', '--short=7', 'HEAD')
$upstream = Get-GitLine -Repo $repo -Arguments @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}')

$ahead = $null
$behind = $null

if (-not [string]::IsNullOrWhiteSpace($upstream)) {
    $counts = Get-GitLine -Repo $repo -Arguments @('rev-list', '--left-right', '--count', 'HEAD...@{u}')

    if ($counts -match '^\s*(\d+)\s+(\d+)\s*$') {
        $ahead = [int]$Matches[1]
        $behind = [int]$Matches[2]
    }
}

$status = @(Invoke-GitCapture -Repo $repo -Arguments @(
    '-c','core.quotepath=false','status','--porcelain=v1','--untracked-files=all'
)).Output

$workingTree = if ($status.Count -eq 0) { 'clean' } else { 'dirty' }

$stashes = @(Invoke-GitCapture -Repo $repo -Arguments @(
    'stash','list','--format=%gd%x09%h%x09%s'
)).Output

$recentCommits = @(Invoke-GitCapture -Repo $repo -Arguments @(
    'log','-n','10','--date=short','--pretty=format:%h%x09%ad%x09%s'
)).Output

$previousHeadValid = $false

if (-not [string]::IsNullOrWhiteSpace($previousHead)) {
    $checkPrevious = Invoke-GitCapture -Repo $repo -Arguments @('cat-file','-e',"$previousHead^{commit}")
    $previousHeadValid = ($checkPrevious.ExitCode -eq 0)
}

$commitsSince = @()
$filesSince = @()

if ($previousHeadValid -and $previousHead -ne $head) {
    $commitsSince = @(Invoke-GitCapture -Repo $repo -Arguments @(
        'log','--date=short','--pretty=format:%h%x09%ad%x09%s',"$previousHead..HEAD"
    )).Output

    $filesSince = @(Invoke-GitCapture -Repo $repo -Arguments @(
        '-c','core.quotepath=false','diff','--name-status',"$previousHead..HEAD"
    )).Output
}

$documentCandidates = @(
    'PROJECT-HANDOFF.md',
    'tools/PROJECT-HANDOFF.md',
    'OPERATING-STANDARDS.md',
    'AUDIT-LIMBO.md',
    'README.md',
    'CONTRIBUTING.md'
)

$documentFacts = @()

foreach ($relativePath in $documentCandidates) {
    if (Test-Path -LiteralPath (Join-Path $repo $relativePath) -PathType Leaf) {
        $lastCommit = Get-GitLine -Repo $repo -Arguments @('log','-1','--format=%h','--',$relativePath)
        if ([string]::IsNullOrWhiteSpace($lastCommit)) {
            $lastCommit = 'untracked or uncommitted'
        }
        $documentFacts += "$relativePath - present - last commit $lastCommit"
    }
}

$timestamp = (Get-Date).ToString('o')
$md = New-Object System.Text.StringBuilder

[void]$md.AppendLine('# Repository Handoff Snapshot')
[void]$md.AppendLine()
[void]$md.AppendLine('Factual repository state for project handoff. This artifact records state; it does not interpret project intent.')
[void]$md.AppendLine()
[void]$md.AppendLine('## Snapshot')
[void]$md.AppendLine()
[void]$md.AppendLine("- Generated: $timestamp")
[void]$md.AppendLine("- Project: $project")
[void]$md.AppendLine("- Repository root: $repo")
[void]$md.AppendLine("- HEAD: $head")
[void]$md.AppendLine("- Short HEAD: $shortHead")
[void]$md.AppendLine("- Branch: $branch")
[void]$md.AppendLine("- Working tree: $workingTree")

if (-not [string]::IsNullOrWhiteSpace($upstream)) {
    [void]$md.AppendLine("- Upstream: $upstream")
    [void]$md.AppendLine("- Ahead: $ahead")
    [void]$md.AppendLine("- Behind: $behind")
}
else {
    [void]$md.AppendLine('- Upstream: not configured or not known locally')
}

[void]$md.AppendLine()
[void]$md.AppendLine('## Working tree detail')
[void]$md.AppendLine()
Add-MarkdownList -Builder $md -Items $status -EmptyText 'clean'

[void]$md.AppendLine()
[void]$md.AppendLine('## Stashes')
[void]$md.AppendLine()
Add-MarkdownList -Builder $md -Items $stashes -EmptyText 'no stashes'

[void]$md.AppendLine()
[void]$md.AppendLine('## Previous handoff boundary')
[void]$md.AppendLine()

if ($previousHeadValid) {
    [void]$md.AppendLine("- Previous snapshot HEAD: $previousHead")
}
elseif (-not [string]::IsNullOrWhiteSpace($previousHead)) {
    [void]$md.AppendLine("- Previous snapshot HEAD: $previousHead - not available in current history")
}
else {
    [void]$md.AppendLine('- Previous snapshot: none - this is the first baseline')
}

[void]$md.AppendLine()
[void]$md.AppendLine('## Commits since previous handoff')
[void]$md.AppendLine()

if (-not $previousHeadValid) {
    [void]$md.AppendLine('- No comparable previous snapshot. See recent commits below.')
}
elseif ($previousHead -eq $head) {
    [void]$md.AppendLine('- No committed changes since the previous handoff.')
}
else {
    Add-MarkdownList -Builder $md -Items $commitsSince
}

[void]$md.AppendLine()
[void]$md.AppendLine('## Files changed since previous handoff')
[void]$md.AppendLine()

if (-not $previousHeadValid) {
    [void]$md.AppendLine('- No comparable previous snapshot.')
}
elseif ($previousHead -eq $head) {
    [void]$md.AppendLine('- No committed file changes since the previous handoff.')
}
else {
    Add-MarkdownList -Builder $md -Items $filesSince
}

[void]$md.AppendLine()
[void]$md.AppendLine('## Recent commits')
[void]$md.AppendLine()
Add-MarkdownList -Builder $md -Items $recentCommits -EmptyText 'no commits returned'

[void]$md.AppendLine()
[void]$md.AppendLine('## Project documents')
[void]$md.AppendLine()
Add-MarkdownList -Builder $md -Items $documentFacts -EmptyText 'no common project documents found'

[void]$md.AppendLine()
[void]$md.AppendLine('## Handoff instruction')
[void]$md.AppendLine()
[void]$md.AppendLine('Give this artifact to ChatGPT with the current project context and ask it to wrap the project, update the canonical handoff when appropriate, and produce the next-conversation prompt.')
[void]$md.AppendLine()
[void]$md.AppendLine('Git state is evidence of what changed, not why it changed. Use conversation context and canonical project documentation for interpretation.')
[void]$md.AppendLine()
[void]$md.AppendLine('Do not infer runtime validation from commits, file presence, or static review.')

Set-Content -LiteralPath $snapshotPath -Value $md.ToString() -Encoding UTF8

Write-Host ''
Write-Host "HANDOFF // $project" -ForegroundColor Cyan
Write-Host '. . . . . . . . . . . . . . . . . . . . .' -ForegroundColor DarkCyan
Write-Host '[OK] Context-state artifact created.' -ForegroundColor Green
Write-Host ("BRANCH // {0}" -f $branch)
Write-Host ("HEAD   // {0}" -f $shortHead)
Write-Host ("STATE  // {0}" -f $workingTree.ToUpperInvariant())
Write-Host ("FILE   // {0}" -f $snapshotPath)
Write-Host ''
Write-Host 'Next: give the snapshot to ChatGPT and ask it to wrap the project.' -ForegroundColor DarkGray
Write-Host ''

if ($Open) {
    Start-Process -FilePath 'notepad.exe' -ArgumentList @($snapshotPath)
}
