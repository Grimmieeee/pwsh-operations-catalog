# Git Handoff Snapshot

Capture the current repository state before ending a work session or moving to a new chat.

## Run

Requires Git for Windows and Windows PowerShell 5.1+ or PowerShell 7+. Run from a terminal, not by double-clicking the file. The default target is the repository containing your current location, not the repository storing this script.

```powershell
& 'C:\path\to\catalog\tools\git-handoff.ps1' -Open
& 'C:\path\to\catalog\tools\git-handoff.ps1' -Path 'C:\path\to\another-repo' -Open
```

If your profile already routes `git handoff` to this script:

```powershell
git handoff
git handoff -Open
git handoff 'C:\path\to\another-repo' -Open
```

The profile shortcut belongs in the existing `git` dispatcher. Do not replace that function with a handoff-only wrapper; preserve its other commands and `git.exe` passthrough. Pulling this repository does not reload or modify a PowerShell profile.

## Output and local changes

One file: `<target-repo>\.handoff\HANDOFF-SNAPSHOT.md`.

The first successful run establishes a baseline. Later runs read its HEAD before replacing it and summarize subsequent committed changes. Unavailable or divergent history is explicitly marked as a new baseline. Uncommitted changes are listed as current state; their contents are not compared.

The script creates the snapshot directory and adds `/.handoff/` to the repository's local Git exclude file. It refuses a tracked snapshot directory because ignore rules do not protect tracked files. There is no config file or separate state file. It does not stage, commit, fetch, or push. Ahead/behind reflects locally known remote state, which may be stale.

`tools/handoff.ps1` is a compatibility entry point that calls the canonical `tools/git-handoff.ps1`; it must remain beside that file. Download `git-handoff.ps1` for standalone use.

## Readability and privacy

Keep project names, branch/upstream names, relative filenames, commit summaries, stash descriptions, and standard document references. Do not export the absolute repository root, author identities, remote URLs, patches, or file contents.

Metadata screening redacts recognizable secret assignments, common token formats, emails, GUIDs, IP addresses, URLs, and absolute local paths. This is best-effort screening, not proof that all sensitive information is absent. Private names, unusual credentials, and context-specific identifiers can escape pattern matching. Review the snapshot before uploading or sharing it. Commit IDs and dates remain for correlation.

Document presence does not establish that it is filled in. Git state does not establish runtime validation.

## Troubleshooting

Failures print a fixed stage code and a numeric source line, without raw filesystem or Git diagnostics. Share those two values when requesting help.

If the profile reports the wrong script folder, fix or reload the profile; the handoff script has not started yet.

## Validation

PowerShell 7.4.6 on Linux, using Git through a `git.exe` test shim: parser checks, first/repeat runs, empty repository, commit comparison, dirty files, rename, stash, metadata redaction, and local exclusion checks. Native Windows PowerShell 5.1 and Notepad opening remain to be validated on Windows.
