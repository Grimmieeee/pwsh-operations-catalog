# .VERSION 1.0.1
# OBJECTIVE: Check this computer and install missing Microsoft 365 PowerShell modules.
#Requires -Version 5.1
<#
.SYNOPSIS
Prepare the current Windows account and PowerShell edition for FIELD // KIT.
.DESCRIPTION
Checks first, offers a specific installation plan, then rechecks selected modules.
Uses CurrentUser scope and the official PowerShell Gallery. Existing compatible
modules are kept. No tenant sign-in, permission grants, policy changes or exports.
Optional local Active Directory tools are checked, not installed or configured.
.PARAMETER Profile
Graph, Exchange or Both. Interactive runs offer a choice when omitted.
.PARAMETER IncludeADTools
Also require local Active Directory tools and a domain-connected computer.
.PARAMETER CheckOnly
Report readiness without installation or repository/provider registration.
.PARAMETER InstallMissing
Explicit approval to install missing prerequisites.
.PARAMETER NoPause
Suppress prompts. A non-ready result throws after the summary.
.NOTES
Run under the Windows account and PowerShell edition used for subsequent jobs.
Use the ticket to record the operator; a shared Windows account alone does not identify them.
READY means local preparation passed; customer access is checked by each workflow.
#>
[CmdletBinding()]
param(
    [ValidateSet('Graph','Exchange','Both')][string]$Profile = 'Both',
    [switch]$IncludeADTools,
    [switch]$CheckOnly,
    [switch]$InstallMissing,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

function Get-FKRequirements {
    param([string]$Selection)
    if ($Selection -in @('Graph','Both')) {
        [pscustomobject]@{ Name='Microsoft.Graph'; Minimum=[version]'2.0.0'; Maximum=[version]'2.999.999'; InstallName='Microsoft.Graph' }
        [pscustomobject]@{ Name='Microsoft.Graph.Authentication'; Minimum=[version]'2.0.0'; Maximum=[version]'2.999.999'; InstallName='Microsoft.Graph' }
    }
    if ($Selection -in @('Exchange','Both')) {
        [pscustomobject]@{ Name='ExchangeOnlineManagement'; Minimum=[version]'3.2.0'; Maximum=$null; InstallName='ExchangeOnlineManagement' }
    }
}

function Get-FKModuleState {
    param($Requirement)
    $all = @(Get-Module -ListAvailable -Name $Requirement.Name -ErrorAction Stop | Sort-Object Version -Descending)
    $module = $all | Where-Object {
        $_.Version -ge $Requirement.Minimum -and (-not $Requirement.Maximum -or $_.Version -le $Requirement.Maximum)
    } | Select-Object -First 1
    $newer = $Requirement.Maximum -and @($all | Where-Object { $_.Version -gt $Requirement.Maximum }).Count -gt 0
    [pscustomobject]@{ Name=$Requirement.Name; Ready=([bool]$module -and -not $newer); Module=$module; Conflict=[bool]$newer; InstallName=$Requirement.InstallName }
}

function Test-FKHost {
    param([string]$Selection,[bool]$Hybrid,[version]$PowerShellVersion=$PSVersionTable.PSVersion,[string]$OperatingSystem=$env:OS)
    $problems = New-Object System.Collections.ArrayList
    if ($OperatingSystem -ne 'Windows_NT') { [void]$problems.Add('Use the approved Windows support computer.') }
    $version = $PowerShellVersion
    if (-not (($version.Major -eq 5 -and $version.Minor -eq 1) -or $version -ge [version]'7.4.0')) {
        [void]$problems.Add('Use Windows PowerShell 5.1 or supported PowerShell 7.4 or later.')
    }
    if ($OperatingSystem -eq 'Windows_NT' -and $version.Major -eq 5 -and $Selection -in @('Exchange','Both')) {
        try {
            $release = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction Stop).Release
            if ($release -lt 461808) { [void]$problems.Add('Exchange Online requires .NET Framework 4.7.2 or later in Windows PowerShell.') }
        } catch { [void]$problems.Add('.NET Framework readiness could not be verified. Ask the support-computer owner to check it.') }
    }
    if ($Hybrid) {
        try {
            if (-not (Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).PartOfDomain) { [void]$problems.Add('The selected AD checks require a domain-connected computer.') }
            if (-not (Get-Module -ListAvailable -Name ActiveDirectory -ErrorAction Stop)) { [void]$problems.Add('Local Active Directory tools are missing. Request approved RSAT installation from the computer owner.') }
        } catch { [void]$problems.Add('Local Active Directory readiness could not be verified.') }
    }
    return $problems.ToArray()
}

function Test-FKGallery {
    param([switch]$AllowRegistration)
    $repository = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
    if (-not $repository -and $AllowRegistration) {
        Register-PSRepository -Default -ErrorAction Stop
        $repository = Get-PSRepository -Name PSGallery -ErrorAction Stop
    }
    if (-not $repository) { throw 'PSGallery is not registered. Approved installation can register the default repository.' }
    if ($repository.SourceLocation -notmatch '^https://www\.powershellgallery\.com/api/v2/?$') {
        throw 'PSGallery does not point to the official HTTPS source. No package installation was attempted.'
    }
}

function Install-FKMissingModules {
    param([object[]]$Requirements,[object[]]$States)
    foreach ($command in @('Install-Module','Get-PSRepository','Register-PSRepository','Get-PackageProvider','Install-PackageProvider')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "$command is unavailable. Repair PowerShellGet using your approved support process, then rerun setup." }
    }
    Test-FKGallery -AllowRegistration
    if ($PSVersionTable.PSVersion.Major -eq 5) { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 }
    $provider = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
        Where-Object { $_.Version -ge [version]'2.8.5.201' } | Select-Object -First 1
    if (-not $provider) { Install-PackageProvider -Name NuGet -MinimumVersion '2.8.5.201' -Scope CurrentUser -Force -ErrorAction Stop | Out-Null }
    $names = @($States | Where-Object { -not $_.Ready } | Select-Object -ExpandProperty InstallName -Unique)
    foreach ($name in $names) {
        $requirement = $Requirements | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        $parameters = @{ Name=$name; MinimumVersion=[string]$requirement.Minimum; Scope='CurrentUser'; Repository='PSGallery'; Force=$true; AllowClobber=$true; ErrorAction='Stop' }
        if ($requirement.Maximum) { $parameters.MaximumVersion=[string]$requirement.Maximum }
        Write-Host "[INFO] Installing missing prerequisite: $name"
        Install-Module @parameters
    }
}

function Test-FKModuleImports {
    param([object[]]$States,[bool]$Hybrid)
    foreach ($state in $States | Where-Object { $_.Name -ne 'Microsoft.Graph' }) {
        if (-not $state.Ready) { throw "$($state.Name) is not ready after checking installation." }
        Import-Module -Name $state.Name -RequiredVersion $state.Module.Version -ErrorAction Stop
        $command = if ($state.Name -eq 'Microsoft.Graph.Authentication') { 'Connect-MgGraph' } else { 'Connect-ExchangeOnline' }
        if (-not (Get-Command $command -ErrorAction Stop)) { throw "$command could not load." }
    }
    if ($Hybrid) {
        Import-Module ActiveDirectory -ErrorAction Stop
        foreach ($command in @('Get-ADUser','Get-ADGroup')) { if (-not (Get-Command $command -ErrorAction Stop)) { throw "$command could not load." } }
    }
}

function Invoke-FKPreparation {
    param([string]$Selection,[bool]$Hybrid,[bool]$ReadOnly,[bool]$ApprovedInstall,[bool]$Unattended)
    $requirements = @(Get-FKRequirements $Selection)
    $problems = @(Test-FKHost -Selection $Selection -Hybrid $Hybrid)
    foreach ($problem in $problems) { Write-Host "[FAIL] $problem" }
    if ($problems.Count) { return 'NOT READY' }
    $states = @($requirements | ForEach-Object { Get-FKModuleState $_ })
    foreach ($state in $states) {
        if ($state.Conflict) { Write-Host "[FAIL] $($state.Name): a newer unsupported major version is installed. Use an approved compatible module configuration; setup will not remove it." }
        elseif ($state.Ready) { Write-Host "[OK] $($state.Name) $($state.Module.Version)" }
        else { Write-Host "[MISSING] $($state.Name)" }
    }
    if (@($states | Where-Object Conflict).Count) { return 'NOT READY' }
    $missing = @($states | Where-Object { -not $_.Ready })
    if ($missing.Count) {
        if ($ReadOnly -or ($Unattended -and -not $ApprovedInstall)) { Write-Host '[INFO] Check only. No prerequisites installed.'; return 'NOT READY' }
        Write-Host ''
        Write-Host 'PLAN: install missing selected modules for this Windows account from PSGallery.'
        Write-Host 'If needed, register the default PSGallery repository and install the NuGet package provider.'
        Write-Host 'Existing compatible modules remain in place. No customer sign-in or permission grants are made.'
        if (-not $ApprovedInstall -and (Read-Host 'Type INSTALL to approve this plan').Trim() -cne 'INSTALL') { return 'CANCELLED' }
        Install-FKMissingModules -Requirements $requirements -States $states
        $states = @($requirements | ForEach-Object { Get-FKModuleState $_ })
        if (@($states | Where-Object { -not $_.Ready }).Count) { throw 'A required module is still missing or incompatible after installation.' }
    }
    Test-FKModuleImports -States $states -Hybrid $Hybrid
    Write-Host '[OK] Selected module imports passed.'
    return 'READY'
}

$started = [datetime]::UtcNow
$result = 'NOT READY'
try {
    Write-Host 'Prepare FIELD KIT'
    Write-Host 'Check this computer and install missing Microsoft 365 PowerShell modules.'
    Write-Host "[INFO] Computer: $env:COMPUTERNAME | Windows account: $env:USERDOMAIN\$env:USERNAME"
    Write-Host "[INFO] Started UTC: $($started.ToString('o')) | Process: $PID"
    Write-Host '[INFO] Local setup only. No customer sign-in.'
    if ($CheckOnly -and $InstallMissing) { throw 'Choose CheckOnly or InstallMissing, not both.' }
    if (-not $NoPause -and -not $PSBoundParameters.ContainsKey('Profile')) {
        Write-Host '[1] Microsoft Graph - user, group and security jobs'
        Write-Host '[2] Exchange Online - mailbox jobs'
        Write-Host '[3] Both - full Microsoft 365 toolkit'
        switch ((Read-Host 'Choose [3]').Trim()) { '1' { $Profile='Graph' }; '2' { $Profile='Exchange' }; { $_ -in @('','3') } { $Profile='Both' }; default { throw 'Choose 1, 2 or 3.' } }
    }
    $result = Invoke-FKPreparation -Selection $Profile -Hybrid ([bool]$IncludeADTools) -ReadOnly ([bool]$CheckOnly) -ApprovedInstall ([bool]$InstallMissing) -Unattended ([bool]$NoPause)
} catch {
    Write-Host "[FAIL] $($_.Exception.Message)"
    $result = 'NOT READY'
} finally {
    Write-Host ''
    Write-Host "RESULT: $result"
    Write-Host 'READY covers this Windows account, PowerShell edition and selected local modules only.'
    Write-Host 'Customer access and sign-in are checked when you run the selected job.'
    if ($result -eq 'READY') { Write-Host 'Next: close this setup window, choose one tool, and start it in a fresh window.' }
    else { Write-Host 'Next: resolve the reported setup issue and rerun setup before starting a job.' }
    Write-Host "[INFO] Finished UTC: $([datetime]::UtcNow.ToString('o'))"
    Write-Host 'SESSION COMPLETE'
    if (-not $NoPause) { Read-Host 'Press Enter to close session when complete.' | Out-Null }
}
if ($NoPause) {
    [pscustomobject]@{ Status=$result; Profile=$Profile; IncludeADTools=[bool]$IncludeADTools; Computer=$env:COMPUTERNAME; WindowsAccount="$env:USERDOMAIN\$env:USERNAME"; StartedUtc=$started; FinishedUtc=[datetime]::UtcNow }
    if ($result -ne 'READY') { throw "FIELD KIT preparation: $result" }
}
