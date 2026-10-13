# Git tools quick start

Download the standalone script you need. Run repository commands from an existing terminal inside your Git repository, or supply `-Path`. Your custom profile shortcuts are optional and are not installed by these downloads.

## Repository check, push and pull

```powershell
.\git-repo.ps1
.\git-repo.ps1 -Action Check -Details
.\git-repo.ps1 -Action Push -Message 'Update tools'
.\git-repo.ps1 -Action Pull
```

Check reads local state and locally known upstream counts; it does not fetch. Push shows the proposed work and requires typed approval before staging, committing and pushing. It may stage all changes, including deletions. Review the diff first; filename screening is not a credential scanner. If committed and uncommitted work coexist, choose PUSH ONLY or SEND ALL. Pull refuses local changes and uses `--ff-only`; it does not reset or stash your files. Git's branch protections still apply.

## Security review

```powershell
.\git-security.ps1 -Account 'your-github-handle'
```

Clear GitHub's security-log filters, choose Export > JSON, save in Downloads, then press Enter. JSON, JSON.GZ and ZIP containing one JSON file are supported. The newest matching account export is selected by file modification time. To specify a file or custom download folder, use `-Path` or `-DownloadFolder`.

Unreviewed actionable findings show a date, target when available, and next step. Full unfiltered reviews with no flags save a local checkpoint automatically. To acknowledge every record in an export after reviewing its findings:

```powershell
.\git-security.ps1 -Account 'your-github-handle' -SetBaseline -Path 'C:\path\reviewed-export.json.gz'
```

The checkpoint stores fingerprints under local application data in `FIELD-KIT/GitSecurity`. It does not learn trusted identities. New or changed records remain eligible. Isolated sign-ins, failed logins, device labels, routine refreshes and unmatched event types stay quiet. ALL CLEAR means no actionable rule matches in the supplied data, not a live account audit or proof of no compromise. No GitHub settings are modified. Keep exports and findings private and outside your repository.

## Handoff

```powershell
.\git-handoff.ps1 -Path 'C:\path\repo' -Open
```

Writes `.handoff/HANDOFF-SNAPSHOT.md` and adds a local Git exclusion. Uses the previous snapshot as its comparison point. Readable metadata is screened for recognizable sensitive values; review it before sharing. Does not fetch, stage, commit or push.

## Execution setup

Place `set-execution.ps1` beside scripts you have reviewed, then run it. It checks effective execution policy, may set CurrentUser RemoteSigned when needed, and unblocks adjacent `.ps1` files. It respects managed policy, installs no modules and does not digitally sign files. Press Enter to exit. This is an explicit setup tool, not a prerequisite to run automatically before every download.

## Toys

Attractor, Rain and Static run in PowerShell 7 inside an ANSI-capable interactive terminal such as Windows Terminal. Use at least 60 columns by 22 rows. Stop with Ctrl+C. They animate the console only; they are not Windows screen locks and do not protect an unattended session.

Public scripts are unsigned source. Apply your own code-signing process where required. Parser and Linux PowerShell 7 tests are not native Windows validation.
