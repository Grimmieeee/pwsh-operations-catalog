<#
.VERSION 1.0.1
#>
# OBJECTIVE: Prepare selected scripts to run under local execution settings.

#Requires -Version 5.1
# FIELD KIT setup: current-user execution policy and local script unblock.
# Re-sign this file after editing if your environment requires signed scripts.
# Unblocks only .ps1 files beside this script, matching the original scope.

$failures = New-Object 'System.Collections.Generic.List[string]'
$notices = New-Object 'System.Collections.Generic.List[string]'
$oldProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

try {
    # Do not rewrite policy when the effective setting already allows this workflow.
    # Never try to override an organizational policy with a process-level bypass.
    try {
        $effective = [string](Get-ExecutionPolicy -ErrorAction Stop)
        if ($effective -notin @('RemoteSigned', 'Unrestricted', 'Bypass')) {
            $managed = @(Get-ExecutionPolicy -List -ErrorAction Stop | Where-Object {
                $_.Scope -in @('MachinePolicy', 'UserPolicy') -and
                [string]$_.ExecutionPolicy -ne 'Undefined'
            })
            if ($managed.Count -gt 0) {
                $notices.Add("Execution policy is managed ($effective); keep scripts signed or contact your administrator")
            } else {
                try {
                    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop -WarningAction SilentlyContinue
                } catch { } # Check effective policy below before reporting success.
                $effective = [string](Get-ExecutionPolicy -ErrorAction Stop)
                if ($effective -notin @('RemoteSigned', 'Unrestricted', 'Bypass')) {
                    if ($effective -eq 'AllSigned') {
                        $notices.Add('AllSigned remains effective; scripts must be signed')
                    } else {
                        $failures.Add("Execution policy remains $effective; check Get-ExecutionPolicy -List")
                    }
                }
                # A policy-override error is harmless only when the effective state
                # above confirms that the intended scripts can run under that policy.
            }
        }
    } catch {
        $failures.Add('Could not check execution policy; run Get-ExecutionPolicy -List')
    }

    try {
        $scripts = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1' -File -ErrorAction Stop)
        foreach ($scriptFile in $scripts) {
            try { Unblock-File -LiteralPath $scriptFile.FullName -ErrorAction Stop }
            catch { $failures.Add("Could not unblock $($scriptFile.Name); check file access") }
        }
    } catch {
        $failures.Add('Could not read the script folder; check folder access')
    }

    if ($failures.Count -gt 0) {
        $message = (@($failures) + @($notices)) -join '; '
        Write-Host "[XX] SETUP INCOMPLETE // $message" -ForegroundColor Red
    } elseif ($notices.Count -gt 0) {
        Write-Host ("[!!] FOLLOW UP // " + ($notices -join '; ')) -ForegroundColor Yellow
    } else {
        Write-Host '[MISSION COMPLETE] // Send it.' -ForegroundColor Green
		Write-Host ""
    }
} finally {
    $ProgressPreference = $oldProgressPreference
    [void](Read-Host 'Press Enter to exit')
}
