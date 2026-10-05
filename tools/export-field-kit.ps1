param(
    [string]$DestinationRoot,
    [string]$ExpectedBranch = 'v1-repo-ui',
    [switch]$SkipPull
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Arguments
    )

    $output = & git @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw (($output | Out-String).Trim())
    }

    return @($output)
}

function Write-Step {
    param([string]$Message)
    Write-Host ('[FIELD // KIT] {0}' -f $Message)
}

try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git is not available in PATH.'
    }

    $repoRoot = Split-Path -Parent $PSScriptRoot

    if ([string]::IsNullOrWhiteSpace($DestinationRoot)) {
        $projectRoot = Split-Path -Parent $repoRoot
        $DestinationRoot = Join-Path $projectRoot 'Backups'
    }

    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot '.git'))) {
        throw ('Repository root could not be resolved from: {0}' -f $repoRoot)
    }

    $branch = ((Invoke-Git -Arguments @('-C',$repoRoot,'branch','--show-current')) -join '').Trim()
    if ([string]::IsNullOrWhiteSpace($branch)) {
        throw 'The repository is not currently on a named branch.'
    }

    if (-not [string]::IsNullOrWhiteSpace($ExpectedBranch) -and $branch -ne $ExpectedBranch) {
        throw ('Expected branch "{0}" but current branch is "{1}".' -f $ExpectedBranch,$branch)
    }

    $dirty = @(Invoke-Git -Arguments @('-C',$repoRoot,'status','--porcelain'))
    if ($dirty.Count -gt 0) {
        throw 'Working tree has uncommitted changes. Commit or stash them before creating a locked backup.'
    }

    if (-not $SkipPull) {
        Write-Step ('Updating {0} with fast-forward-only pull...' -f $branch)
        Invoke-Git -Arguments @('-C',$repoRoot,'fetch','origin',$branch) | Out-Null
        Invoke-Git -Arguments @('-C',$repoRoot,'pull','--ff-only','origin',$branch) | Out-Null
    }

    $dirty = @(Invoke-Git -Arguments @('-C',$repoRoot,'status','--porcelain'))
    if ($dirty.Count -gt 0) {
        throw 'Working tree changed during update. Backup stopped.'
    }

    $commit = ((Invoke-Git -Arguments @('-C',$repoRoot,'rev-parse','HEAD')) -join '').Trim()
    $shortCommit = $commit.Substring(0,8)
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

    New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null

    $archiveName = 'FIELD-KIT-{0}-{1}.zip' -f $timestamp,$shortCommit
    $archivePath = Join-Path $DestinationRoot $archiveName
    $latestPath = Join-Path $DestinationRoot 'FIELD-KIT-LATEST.zip'

    Write-Step 'Creating tracked-source archive...'
    Invoke-Git -Arguments @(
        '-C',$repoRoot,
        'archive',
        '--format=zip',
        ('--output={0}' -f $archivePath),
        'HEAD'
    ) | Out-Null

    if (-not (Test-Path -LiteralPath $archivePath)) {
        throw 'Git archive completed without creating the expected ZIP.'
    }

    Copy-Item -LiteralPath $archivePath -Destination $latestPath -Force

    $hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    $trackedFiles = @(Invoke-Git -Arguments @('-C',$repoRoot,'ls-files')).Count

    $manifest = @(
        'FIELD // KIT BACKUP'
        ''
        ('Created:       {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
        ('Repository:    {0}' -f $repoRoot)
        ('Branch:        {0}' -f $branch)
        ('Commit:        {0}' -f $commit)
        ('Tracked files: {0}' -f $trackedFiles)
        ('Archive:       {0}' -f $archiveName)
        ('SHA256:        {0}' -f $hash)
        ''
        'Notes:'
        '- Archive contains the exact tracked contents of HEAD.'
        '- .git history and untracked/local-only files are intentionally excluded.'
        '- FIELD-KIT-LATEST.zip is replaced on every successful run.'
        '- Timestamped archives are preserved.'
    )

    $manifestPath = [System.IO.Path]::ChangeExtension($archivePath,'.manifest.txt')
    $latestManifestPath = Join-Path $DestinationRoot 'FIELD-KIT-LATEST.manifest.txt'

    $manifest | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    $manifest | Set-Content -LiteralPath $latestManifestPath -Encoding UTF8

    Write-Host ''
    Write-Host 'FIELD // KIT BACKUP COMPLETE'
    Write-Host ('Branch:  {0}' -f $branch)
    Write-Host ('Commit:  {0}' -f $shortCommit)
    Write-Host ('Files:   {0}' -f $trackedFiles)
    Write-Host ('Archive: {0}' -f $archivePath)
    Write-Host ('Latest:  {0}' -f $latestPath)
    Write-Host ('SHA256:  {0}' -f $hash)
}
catch {
    Write-Host ''
    Write-Host ('FIELD // KIT BACKUP FAILED: {0}' -f $_.Exception.Message) -ForegroundColor Red
    throw
}
