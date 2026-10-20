<#
.VERSION 1.0.0
#>
#Requires -Version 5.1

# seaglass.ps1
# MSSP Field Kit -- Sea Glass terminal theme installer.
# Applies ANSI syntax highlighting and console colors for the current session.
# Writes theme block to $PROFILE.CurrentUserAllHosts for persistence.
# Removes any previously installed kit theme before writing.

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'White'
$Host.UI.RawUI.WindowTitle     = 'MSSP - Sea Glass Theme'
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$esc = [char]27
$cT1 = "${esc}[38;2;115;195;165m"
$cT2 = "${esc}[38;2;150;215;185m"
$cT3 = "${esc}[38;2;60;120;100m"
$cWh = "${esc}[97m"
$cWn = "${esc}[38;2;255;179;0m"
$cFl = "${esc}[38;2;215;100;90m"
$cR  = "${esc}[0m"

Write-Host ""
Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host "${cT1} MSSP FIELD KIT  ${cT3}--  ${cT2}SEA GLASS THEME${cR}"
Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host "${cT3}  Tidal. Unhurried. Correct.${cR}"
Write-Host ""

# -- Console colors -- current session -----------------------------------------
$Host.UI.RawUI.BackgroundColor            = 'Black'
$Host.UI.RawUI.ForegroundColor            = 'White'
$Host.PrivateData.ErrorForegroundColor    = 'Red'
$Host.PrivateData.ErrorBackgroundColor    = 'Black'
$Host.PrivateData.WarningForegroundColor  = 'Yellow'
$Host.PrivateData.WarningBackgroundColor  = 'Black'
$Host.PrivateData.DebugForegroundColor    = 'Green'
$Host.PrivateData.DebugBackgroundColor    = 'Black'
$Host.PrivateData.VerboseForegroundColor  = 'Cyan'
$Host.PrivateData.VerboseBackgroundColor  = 'Black'
$Host.PrivateData.ProgressForegroundColor = 'Cyan'
$Host.PrivateData.ProgressBackgroundColor = 'Black'

Write-Host "${cT1}[OK]  ${cWh}Console colors applied${cR}"

# -- PSReadLine syntax highlighting -- current session -------------------------
try {
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Set-PSReadLineOption -Colors @{
            Command            = "$esc[38;2;115;195;165m"   # sea glass
            Keyword            = "$esc[38;2;115;195;165m"   # sea glass
            Type               = "$esc[38;2;115;195;165m"   # sea glass
            Member             = "$esc[38;2;215;100;90m"    # coral
            String             = "$esc[38;2;215;100;90m"    # coral
            Number             = "$esc[38;2;150;215;185m"   # sea glass light
            Comment            = "$esc[38;2;60;120;100m"    # sea glass dim
            Parameter          = "$esc[97m"                 # bright white
            Operator           = "$esc[97m"                 # bright white
            Variable           = "$esc[97m"                 # bright white
            Default            = "$esc[97m"                 # bright white
            ContinuationPrompt = "$esc[97m"                 # bright white
            Error              = "$esc[38;2;225;85;75m"     # coral bright
            Selection          = "$esc[48;2;30;70;55m"      # sea glass dark bg
        }
    } else {
        Set-PSReadLineOption -Colors @{
            Command   = [ConsoleColor]::Cyan
            Keyword   = [ConsoleColor]::Cyan
            Type      = [ConsoleColor]::Cyan
            Member    = [ConsoleColor]::Yellow
            String    = [ConsoleColor]::Yellow
            Number    = [ConsoleColor]::Cyan
            Comment   = [ConsoleColor]::DarkCyan
            Parameter = [ConsoleColor]::White
            Operator  = [ConsoleColor]::White
            Variable  = [ConsoleColor]::White
            Default   = [ConsoleColor]::White
            Error     = [ConsoleColor]::Red
        }
    }
    Write-Host "${cT1}[OK]  ${cWh}PSReadLine syntax colors applied${cR}"
} catch {
    Write-Host "${cWn}[!!]  ${cWh}PSReadLine not available -- skipping syntax colors${cR}"
}

# -- Write to profile ----------------------------------------------------------
$profileBlock = @"

# - - - MSSP FIELD KIT - SEA GLASS THEME - - -
`$Host.UI.RawUI.BackgroundColor            = 'Black'
`$Host.UI.RawUI.ForegroundColor            = 'White'
`$Host.PrivateData.ErrorForegroundColor    = 'Red'
`$Host.PrivateData.ErrorBackgroundColor    = 'Black'
`$Host.PrivateData.WarningForegroundColor  = 'Yellow'
`$Host.PrivateData.WarningBackgroundColor  = 'Black'
`$Host.PrivateData.DebugForegroundColor    = 'Green'
`$Host.PrivateData.DebugBackgroundColor    = 'Black'
`$Host.PrivateData.VerboseForegroundColor  = 'Cyan'
`$Host.PrivateData.VerboseBackgroundColor  = 'Black'
`$Host.PrivateData.ProgressForegroundColor = 'Cyan'
`$Host.PrivateData.ProgressBackgroundColor = 'Black'
try {
    if (`$PSVersionTable.PSVersion.Major -ge 7) {
        `$e = [char]27
        Set-PSReadLineOption -Colors @{
            Command            = "`$e[38;2;115;195;165m"
            Keyword            = "`$e[38;2;115;195;165m"
            Type               = "`$e[38;2;115;195;165m"
            Member             = "`$e[38;2;215;100;90m"
            String             = "`$e[38;2;215;100;90m"
            Number             = "`$e[38;2;150;215;185m"
            Comment            = "`$e[38;2;60;120;100m"
            Parameter          = "`$e[97m"
            Operator           = "`$e[97m"
            Variable           = "`$e[97m"
            Default            = "`$e[97m"
            ContinuationPrompt = "`$e[97m"
            Error              = "`$e[38;2;225;85;75m"
            Selection          = "`$e[48;2;30;70;55m"
        }
    } else {
        Set-PSReadLineOption -Colors @{
            Command   = [ConsoleColor]::Cyan
            Keyword   = [ConsoleColor]::Cyan
            Type      = [ConsoleColor]::Cyan
            Member    = [ConsoleColor]::Yellow
            String    = [ConsoleColor]::Yellow
            Number    = [ConsoleColor]::Cyan
            Comment   = [ConsoleColor]::DarkCyan
            Parameter = [ConsoleColor]::White
            Operator  = [ConsoleColor]::White
            Variable  = [ConsoleColor]::White
            Default   = [ConsoleColor]::White
            Error     = [ConsoleColor]::Red
        }
    }
} catch {}
# - - - END SEA GLASS THEME - - -
"@

$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir  = Split-Path $profilePath

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

if (Test-Path $profilePath) {
    $existing = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($existing -match 'SEA GLASS THEME') {
        Write-Host "${cT1}[OK]  ${cWh}Profile already contains Sea Glass theme -- no changes made${cR}"
        Write-Host ""
        Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
        Write-Host "${cT3}  Loads on every new session.${cR}"
        Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
        Write-Host ""
        Read-Host "  Press Enter to exit"
        exit
    }
    foreach ($theme in @('SILICON VALLEY THEME', 'COBALT THEME', 'MINT CORAL THEME')) {
        if ($existing -match $theme) {
            $tag = ($theme -replace ' THEME','').Trim()
            Write-Host "${cWn}[!!]  ${cWh}$tag theme found in profile -- replacing with Sea Glass${cR}"
            $existing = $existing -replace "(?s)# - - - MSSP FIELD KIT - $theme - - -.*?# - - - END $theme - - -\s*", ''
            Set-Content -Path $profilePath -Value $existing -Encoding UTF8 -ErrorAction SilentlyContinue
        }
    }
}

try {
    Add-Content -Path $profilePath -Value $profileBlock -Encoding UTF8 -ErrorAction Stop
    Write-Host "${cT1}[OK]  ${cWh}Written to profile: ${cT2}$profilePath${cR}"
} catch {
    Write-Host "${cFl}[XX]  ${cWh}Could not write profile: $($_.Exception.Message)${cR}"
    Write-Host "${cT3}      Add the block manually to: $profilePath${cR}"
}

Write-Host ""
Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host "${cT3}  Tidal. Unhurried. Correct.${cR}"
Write-Host "${cT3}  Restart your terminal to confirm persistence.${cR}"
Write-Host "${cT3}  To revert: remove the SEA GLASS THEME block from your profile.${cR}"
Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host ""
Read-Host "  Press Enter to exit"
