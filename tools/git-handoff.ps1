<#
.VERSION 1.0.1
#>
# OBJECTIVE: Save a screened snapshot of the current Git project for handoff.

#requires -Version 5.1
<#
Readable Git context snapshot with targeted metadata redaction. No network calls, staging, commits or pushes.
Names and summaries are retained after best-effort screening; review before sharing.
Writes .handoff/HANDOFF-SNAPSHOT.md and adds a local Git exclude rule.
Run from a terminal inside the target repo, or supply -Path. Requires Git for Windows.
#>
[CmdletBinding()]
param(
    [Parameter(Position=0)][string]$Path = (Get-Location).Path,
    [switch]$Open
)
$ErrorActionPreference = 'Stop'
$script:HandoffStage = 'START'

function Invoke-Capture {
    param([string[]]$GitArgs, [switch]$AllowFailure)
    # Capture stdout/stderr without letting Git diagnostics leak repository data.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $script:GitExecutable
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $allArgs = @('-C', $script:Repo) + $GitArgs
    $quoted = foreach ($arg in $allArgs) {
        '"' + ([regex]::Replace([regex]::Replace($arg, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1')) + '"'
    }
    $psi.Arguments = $quoted -join ' '
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    try {
        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $result = [pscustomobject]@{ Code=$process.ExitCode; Text=$stdout.GetAwaiter().GetResult() }
        [void]$stderr.GetAwaiter().GetResult()
        if ($result.Code -ne 0 -and -not $AllowFailure) { throw 'Git query failed.' }
        return $result
    } finally { $process.Dispose() }
}
function Get-Hash {
    param([string]$Value)
    $value = $Value.Trim()
    if ($value -notmatch '^(?:[a-f0-9]{40}|[a-f0-9]{64})$') { throw 'Invalid object ID.' }
    return $value
}
function Add-Line { param([string]$Text=''); [void]$script:Report.AppendLine($Text) }
function Protect-Text {
    param([AllowEmptyString()][string]$Value)
    $text = $Value
    # Work only on metadata; never read file contents or patches.
    $patterns = @(
        '(?i)-----BEGIN [^-]*PRIVATE KEY-----.*',
        '(?i)\b(?:password|passwd|pwd|client[_ -]?secret|api[_ -]?key|access[_ -]?token|refresh[_ -]?token|authorization|connection[_ -]?string)\b\s*(?:[:=]|\bis\b)\s*.+',
        '(?i)\bBearer\s+\S+',
        '(?i)\b(?:gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+|AKIA[A-Z0-9]{16}|ASIA[A-Z0-9]{16}|xox[baprs]-[A-Za-z0-9-]+)\b',
        '\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
        '(?i)\b[a-z][a-z0-9+.-]*://[^\s<>"'']+',
        '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
        '(?i)\b[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\b',
        '\b(?:\d{1,3}\.){3}\d{1,3}\b',
        '(?i)(?<![a-z0-9])(?:[0-9a-f]{0,4}:){2,}[0-9a-f:]{0,39}(?:%[a-z0-9]+)?',
        '(?i)\b[A-Z]:[\\/].*',
        '\\\\[^\s]+.*',
        '(?i)(?<!\S)/(?:home|Users|root|mnt|tmp|var|opt|workspace)/.*',
        '(?<![A-Za-z0-9])(?=[A-Za-z0-9_+/=-]{32,}(?![A-Za-z0-9]))(?=[A-Za-z0-9_+/=-]*[A-Za-z])(?=[A-Za-z0-9_+/=-]*[0-9])[A-Za-z0-9_+/=-]{32,}'
    )
    foreach ($pattern in $patterns) { $text = [regex]::Replace($text, $pattern, '[REDACTED]') }
    # Neutralize terminal controls and Markdown/HTML formatting in metadata.
    $text = [regex]::Replace($text, '[\x00-\x1f\x7f-\x9f\u202a-\u202e\u2066-\u2069]', ' ')
    $text = $text.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;')
    $text = [regex]::Replace($text, '([\\`*_{}\[\]()!|])', '\$1')
    return $text
}
function Add-Commits {
    param([string]$Text)
    $lines = @($Text -split '\r?\n' | Where-Object { $_ })
    if (-not $lines.Count) { Add-Line '- none'; return }
    foreach ($line in $lines) {
        $parts = $line -split "`t", 3
        if ($parts.Count -ne 3) { throw 'Invalid commit data.' }
        $hash = Get-Hash $parts[0]
        if ($parts[1] -notmatch '^[0-9]{4}-[0-9]{2}-[0-9]{2}$') { throw 'Invalid commit date.' }
        Add-Line ('- {0} | {1} | {2}' -f $hash.Substring(0,7), $parts[1], (Protect-Text $parts[2]))
    }
}

try {
    $script:HandoffStage = 'FIND_GIT'
    $script:GitExecutable = (Get-Command git.exe -CommandType Application -ErrorAction Stop).Source
    $script:HandoffStage = 'RESOLVE_INPUT'
    $item = Get-Item -LiteralPath $Path
    $script:Repo = if ($item.PSIsContainer) { $item.FullName } else { $item.Directory.FullName }
    $script:HandoffStage = 'FIND_REPOSITORY'
    $script:Repo = (Invoke-Capture @('rev-parse','--show-toplevel')).Text.Trim()
    $script:HandoffStage = 'READ_HEAD'
    $headResult = Invoke-Capture @('rev-parse','--verify','HEAD') -AllowFailure
    $head = if ($headResult.Code -eq 0) { Get-Hash $headResult.Text } else { $null }
    $folder = Join-Path $script:Repo '.handoff'
    $snapshot = Join-Path $folder 'HANDOFF-SNAPSHOT.md'
    $script:HandoffStage = 'CHECK_OUTPUT'
    # Refuse tracked output: ignore rules cannot protect files already tracked.
    if ((Invoke-Capture @('ls-files','--','.handoff')).Text.Length) { throw 'Snapshot directory is tracked.' }
    if ((Test-Path -LiteralPath $folder) -and ((Get-Item -Force -LiteralPath $folder).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Linked snapshot directory refused.' }
    if ((Test-Path -LiteralPath $snapshot) -and ((Get-Item -Force -LiteralPath $snapshot).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Linked snapshot file refused.' }
    $script:HandoffStage = 'READ_BASELINE'
    $previous = $null
    if (Test-Path -LiteralPath $snapshot) {
        $m = [regex]::Match([IO.File]::ReadAllText($snapshot), '(?m)^- HEAD: ((?:[a-f0-9]{40}|[a-f0-9]{64}))\r?$')
        if ($m.Success) { $previous = $m.Groups[1].Value }
    }
    $script:HandoffStage = 'SET_LOCAL_EXCLUDE'
    # --git-path supports normal repositories and linked worktrees.
    $exclude = (Invoke-Capture @('rev-parse','--git-path','info/exclude')).Text.Trim()
    if (-not [IO.Path]::IsPathRooted($exclude)) { $exclude = Join-Path $script:Repo $exclude }
    [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($exclude))
    $existing = if (Test-Path -LiteralPath $exclude) { [IO.File]::ReadAllText($exclude) } else { '' }
    if (($existing -split '\r?\n') -notcontains '/.handoff/') {
        [IO.File]::AppendAllText($exclude, "`n# Local Git handoff snapshots`n/.handoff/`n", (New-Object Text.UTF8Encoding($false)))
    }
    [void][IO.Directory]::CreateDirectory($folder)
    $ignored = Invoke-Capture @('check-ignore','-q','--','.handoff/HANDOFF-SNAPSHOT.md') -AllowFailure
    if ($ignored.Code -ne 0) { throw 'Snapshot exclusion could not be verified.' }

    $script:HandoffStage = 'READ_STATUS'
    $status = (Invoke-Capture @('status','--porcelain=v1','-z','--untracked-files=all')).Text
    $branch = Invoke-Capture @('symbolic-ref','-q','--short','HEAD') -AllowFailure
    if ($branch.Code -notin @(0,1)) { throw 'Branch query failed.' }
    $upstream = Invoke-Capture @('rev-parse','--abbrev-ref','--symbolic-full-name','@{u}') -AllowFailure
    $script:HandoffStage = 'BUILD_REPORT'
    $project = Protect-Text (Split-Path -Leaf $script:Repo)
    $script:Report = New-Object Text.StringBuilder
    Add-Line '# Repository Handoff Snapshot'
    Add-Line
    Add-Line ('- Generated UTC: ' + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
    Add-Line "- Project: $project"
    if ($head) { Add-Line "- HEAD: $head"; Add-Line ("- Short HEAD: " + $head.Substring(0,7)) } else { Add-Line '- HEAD: unborn (no commits)' }
    if ($branch.Code -eq 0) { Add-Line ('- Branch: ' + (Protect-Text $branch.Text.Trim())) } else { Add-Line '- Branch: detached HEAD' }
    if ($status.Length) { Add-Line '- Working tree: dirty' } else { Add-Line '- Working tree: clean' }
    if ($upstream.Code -eq 0 -and $head) {
        $counts = (Invoke-Capture @('rev-list','--left-right','--count','HEAD...@{u}')).Text.Trim()
        if ($counts -notmatch '^(\d+)\s+(\d+)$') { throw 'Invalid counts.' }
        Add-Line ('- Upstream: ' + (Protect-Text $upstream.Text.Trim()))
        Add-Line "- Ahead: $($Matches[1])"
        Add-Line "- Behind: $($Matches[2])"
    } else { Add-Line '- Upstream: unavailable locally or not configured' }
    Add-Line '- Remote freshness: not checked; no fetch performed'
    Add-Line
    Add-Line '## Working tree detail'
    Add-Line 'Git XY status codes; ?? means untracked.'
    $entries = $status.Split([char]0)
    for ($i=0; $i -lt $entries.Length; $i++) {
        $entry = $entries[$i]
        if (-not $entry) { continue }
        if ($entry.Length -lt 4 -or $entry.Substring(0,3) -notmatch '^[ MADRCU?!T]{2} $') { throw 'Invalid status.' }
        $code = $entry.Substring(0,2)
        $fileName = Protect-Text $entry.Substring(3)
        if ($code -match '[RC]') {
            $i++
            if ($i -ge $entries.Length -or -not $entries[$i]) { throw 'Invalid rename.' }
            $source = Protect-Text $entries[$i]
            Add-Line ('- `{0}` {1} -> {2}' -f $code, $source, $fileName)
        } else { Add-Line ('- `{0}` {1}' -f $code, $fileName) }
    }
    if (-not $status.Length) { Add-Line '- clean' }
    Add-Line
    Add-Line '## Stashes'
    $script:HandoffStage = 'READ_STASHES'
    $stashText = (Invoke-Capture @('stash','list','--format=%H%x09%gs')).Text
    $stashIndex = 0
    foreach ($line in ($stashText -split '\r?\n' | Where-Object { $_ })) {
        $parts = $line -split "`t", 2
        if ($parts.Count -ne 2) { throw 'Invalid stash data.' }
        $hash = Get-Hash $parts[0]
        Add-Line ('- stash@{{{0}}} | {1} | {2}' -f $stashIndex, $hash.Substring(0,7), (Protect-Text $parts[1]))
        $stashIndex++
    }
    if (-not $stashIndex) { Add-Line '- none' }
    Add-Line
    Add-Line '## Previous handoff boundary'
    $script:HandoffStage = 'COMPARE_HISTORY'
    $comparable = $false
    if ($previous -and $head) {
        $available = Invoke-Capture @('cat-file','-e',"$previous^{commit}") -AllowFailure
        if ($available.Code -eq 0) {
            $ancestor = Invoke-Capture @('merge-base','--is-ancestor',$previous,$head) -AllowFailure
            if ($ancestor.Code -notin @(0,1)) { throw 'History query failed.' }
            $comparable = $ancestor.Code -eq 0
        }
    }
    if ($comparable) { Add-Line "- Previous snapshot HEAD: $previous" }
    else { Add-Line '- No comparable baseline: first run, unavailable history, or history diverged. New baseline recorded.' }
    Add-Line
    Add-Line '## Commits since previous handoff'
    if ($comparable) { Add-Commits (Invoke-Capture @('log','--format=%H%x09%cs%x09%s',"$previous..$head")).Text }
    else { Add-Line '- unavailable' }
    Add-Line
    Add-Line '## Files changed since previous handoff'
    if ($comparable) {
        $changed = (Invoke-Capture @('diff','--name-only','-z',"$previous..$head",'--')).Text
        foreach ($name in ($changed.Split([char]0) | Where-Object { $_ })) { Add-Line ('- ' + (Protect-Text $name)) }
        if (-not $changed.Length) { Add-Line '- none' }
    } else { Add-Line '- unavailable' }
    Add-Line
    $script:HandoffStage = 'READ_COMMITS'
    Add-Line '## Recent commits'
    if ($head) { Add-Commits (Invoke-Capture @('log','-n','10','--format=%H%x09%cs%x09%s')).Text }
    else { Add-Line '- none' }
    Add-Line
    Add-Line '## Project documents'
    $script:HandoffStage = 'CHECK_DOCUMENTS'
    $documents = @('PROJECT-HANDOFF.md','tools/PROJECT-HANDOFF.md','OPERATING-STANDARDS.md','AUDIT-LIMBO.md','README.md','CONTRIBUTING.md')
    $found = 0
    foreach ($doc in $documents) {
        if (Test-Path -LiteralPath (Join-Path $script:Repo $doc) -PathType Leaf) {
            $last = if ($head) { (Invoke-Capture @('log','-1','--format=%H','--',$doc)).Text.Trim() } else { '' }
            $lastLabel = if ($last) { (Get-Hash $last).Substring(0,7) } else { 'untracked or uncommitted' }
            Add-Line "- $doc - present - last commit $lastLabel"
            $found++
        }
    }
    if (-not $found) { Add-Line '- none of the standard documents found' }
    Add-Line
    Add-Line '## Handoff instruction'
    Add-Line 'Give this artifact to ChatGPT with the current project context and ask it to wrap the project, update the canonical handoff when appropriate, and produce the next-conversation prompt.'
    Add-Line
    Add-Line 'Git state is evidence of what changed, not why. Document presence does not prove a completed handoff. Do not infer runtime validation from commits, file presence, or static review.'
    Add-Line
    Add-Line '## Privacy and limits'
    Add-Line '- No file contents, patches, author identities, remote URLs, or absolute repository root are exported.'
    Add-Line '- Recognizable sensitive values in names and messages are redacted. This is best-effort screening, not a guarantee; review free-text names and summaries before sharing.'
    Add-Line '- Commit IDs and dates remain for correlation. Snapshots compare committed history; they do not compare uncommitted file contents.'
    # Replace only after every Git query and output validation succeeds.
    $script:HandoffStage = 'WRITE_SNAPSHOT'
    $temp = Join-Path $folder ([IO.Path]::GetRandomFileName())
    try {
        [IO.File]::WriteAllText($temp, $script:Report.ToString(), (New-Object Text.UTF8Encoding($false)))
        if (Test-Path -LiteralPath $snapshot) { [IO.File]::Replace($temp, $snapshot, [NullString]::Value) }
        else { [IO.File]::Move($temp, $snapshot) }
    } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
    if ([IO.File]::ReadAllText($snapshot) -cne $script:Report.ToString()) { throw 'Snapshot verification failed.' }
    if ($status.Length) {
        Write-Host '[OK] Screened snapshot saved (uncommitted changes recorded): <repo>\.handoff\HANDOFF-SNAPSHOT.md' -ForegroundColor Magenta
    } else {
        Write-Host '[OK] Screened snapshot saved (clean working tree): <repo>\.handoff\HANDOFF-SNAPSHOT.md' -ForegroundColor Green
    }
    $script:HandoffStage = 'OPEN_SNAPSHOT'
    if ($Open) { Start-Process notepad.exe -ArgumentList ('"' + $snapshot + '"') }
} catch {
    # Never echo exception text: native and filesystem errors can contain private names.
    $failureLine = [int]$_.InvocationInfo.ScriptLineNumber
    Write-Host ("[XX] Handoff failed. Stage: {0}; line: {1}. No raw diagnostic data was printed." -f $script:HandoffStage, $failureLine) -ForegroundColor Red
    Write-Host 'Share the stage and line above for troubleshooting.' -ForegroundColor DarkGray
}
