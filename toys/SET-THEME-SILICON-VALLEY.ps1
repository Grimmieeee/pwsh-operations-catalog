<#
.VERSION 1.0.1
#>
# OBJECTIVE: Preview a green PowerShell theme and output helpers.

#Requires -Version 5.1
# =============================================================================
# MSSP FIELD KIT — SET-SILICONVALLEYTHEME
# =============================================================================
# Terminal color theme inspired by the Pied Piper aesthetic.
# Dot-source or run directly. Writes to profile for persistence.
#
# Scheme: Black background, Bright Cyan commands, Bright Amber strings,
#         Bright Green comments, Bright White defaults, Bright Red errors
# PS 7+: Full ANSI hex color support
# PS 5.1: ConsoleColor fallback
# =============================================================================

$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'White'
Clear-Host

Write-Host ''
Write-Host '. . . . . . . . . . . . . . . . . . . . .'  -ForegroundColor Cyan
Write-Host ' MSSP FIELD KIT  -  SET-SILICONVALLEYTHEME' -ForegroundColor Cyan
Write-Host '. . . . . . . . . . . . . . . . . . . . .'  -ForegroundColor Cyan
Write-Host '  Pied Piper colorway. Middle-out compression not included.' -ForegroundColor DarkCyan
Write-Host ''

# =============================================================================
# CONSOLE COLORS — CURRENT SESSION
# =============================================================================
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

Write-Host '  [OK]   Console colors applied.' -ForegroundColor Cyan

# =============================================================================
# PSREADLINE — SYNTAX HIGHLIGHTING
# =============================================================================
try {
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Set-PSReadLineOption -Colors @{
            Command            = "`e[96m"                  # Bright Cyan
            Keyword            = "`e[96m"                  # Bright Cyan
            Type               = "`e[96m"                  # Bright Cyan
            Member             = "`e[38;2;255;190;30m"     # Bright Amber
            String             = "`e[38;2;255;190;30m"     # Bright Amber
            Number             = "`e[38;2;255;210;80m"     # Bright Gold
            Comment            = "`e[92m"                  # Bright Green
            Parameter          = "`e[97m"                  # Bright White
            Operator           = "`e[97m"                  # Bright White
            Variable           = "`e[97m"                  # Bright White
            Default            = "`e[97m"                  # Bright White
            ContinuationPrompt = "`e[97m"                  # Bright White
            Error              = "`e[91m"                  # Bright Red
            Selection          = "`e[48;2;0;100;100m"      # Bright Teal highlight
        }
    } else {
        Set-PSReadLineOption -Colors @{
            Command   = [ConsoleColor]::Cyan
            Keyword   = [ConsoleColor]::Cyan
            Type      = [ConsoleColor]::Cyan
            Member    = [ConsoleColor]::Yellow
            String    = [ConsoleColor]::Yellow
            Number    = [ConsoleColor]::Yellow
            Comment   = [ConsoleColor]::Green
            Parameter = [ConsoleColor]::White
            Operator  = [ConsoleColor]::White
            Variable  = [ConsoleColor]::White
            Default   = [ConsoleColor]::White
            Error     = [ConsoleColor]::Red
        }
    }
    Write-Host '  [OK]   PSReadLine syntax colors applied.' -ForegroundColor Cyan
} catch {
    Write-Host '  [!!]   PSReadLine not available — skipping syntax colors.' -ForegroundColor Yellow
}

# =============================================================================
# WRITE TO PROFILE
# =============================================================================
$profileBlock = @"

# - - - MSSP FIELD KIT - SILICON VALLEY THEME - - -
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
function global:Get-DailyPassword {
    `$seed = [int](Get-Date -Format 'yyyyMMdd'); `$rng = [System.Random]::new(`$seed)
    `$triplets = @(
        @('Blaze','Craze','Gaze'),    @('Slick','Brick','Trick'),
        @('Flash','Crash','Stash'),   @('Stone','Bone','Zone'),
        @('Steep','Sleep','Deep'),    @('Bright','Night','Light'),
        @('Spike','Hike','Strike'),   @('Frost','Cost','Lost'),
        @('Crunch','Bunch','Munch'),  @('Blade','Fade','Shade'),
        @('Cloak','Smoke','Spoke'),   @('Drift','Shift','Swift'),
        @('Grind','Find','Mind'),     @('Plank','Rank','Tank'),
        @('Scout','Doubt','Shout'),   @('Charm','Farm','Harm'),
        @('Clash','Rash','Stash'),    @('Drape','Grape','Shape'),
        @('Flint','Mint','Print'),    @('Glow','Flow','Show'),
        @('Hound','Found','Round'),   @('Knack','Black','Stack'),
        @('Lance','Dance','Chance'),  @('Mirth','Birth','Worth'),
        @('Notch','Watch','Botch')
    )
    `$symbols = @('!','@','#',"`$",'%','&')
    `$t = `$triplets[`$rng.Next(`$triplets.Count)]
    `$i0 = `$rng.Next(3); `$rem = @(0,1,2) | Where-Object { `$_ -ne `$i0 }
    `$i1 = `$rem[`$rng.Next(2)]
    `$i2 = @(0,1,2) | Where-Object { `$_ -ne `$i0 -and `$_ -ne `$i1 } | Select-Object -First 1
    return "`$(`$t[`$i0])`$(`$t[`$i1])`$(`$t[`$i2])`$((Get-Date).Year)`$(`$symbols[`$rng.Next(`$symbols.Count)])"
}
try {
    if (`$PSVersionTable.PSVersion.Major -ge 7) {
        Set-PSReadLineOption -Colors @{
            Command            = "`e[96m"
            Keyword            = "`e[96m"
            Type               = "`e[96m"
            Member             = "`e[38;2;255;190;30m"
            String             = "`e[38;2;255;190;30m"
            Number             = "`e[38;2;255;210;80m"
            Comment            = "`e[92m"
            Parameter          = "`e[97m"
            Operator           = "`e[97m"
            Variable           = "`e[97m"
            Default            = "`e[97m"
            ContinuationPrompt = "`e[97m"
            Error              = "`e[91m"
            Selection          = "`e[48;2;0;100;100m"
        }
    } else {
        Set-PSReadLineOption -Colors @{
            Command   = [ConsoleColor]::Cyan;   Keyword   = [ConsoleColor]::Cyan
            Type      = [ConsoleColor]::Cyan;   Member    = [ConsoleColor]::Yellow
            String    = [ConsoleColor]::Yellow; Number    = [ConsoleColor]::Yellow
            Comment   = [ConsoleColor]::Green;  Parameter = [ConsoleColor]::White
            Operator  = [ConsoleColor]::White;  Variable  = [ConsoleColor]::White
            Default   = [ConsoleColor]::White;  Error     = [ConsoleColor]::Red
        }
    }
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineKeyHandler -Key Tab             -Function AcceptSuggestion
    Set-PSReadLineKeyHandler -Key UpArrow         -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function AcceptNextSuggestionWord
} catch {}
Write-Host '. . . . . . . . . . . . . . . . . . . . .' -ForegroundColor Cyan
Write-Host "MSSP FIELD KIT  -  `$env:USERDOMAIN\`$env:USERNAME" -ForegroundColor Cyan
Write-Host '. . . . . . . . . . . . . . . . . . . . .' -ForegroundColor Cyan
Write-Host (Get-DailyPassword) -ForegroundColor Yellow
Write-Host ''
# - - - END SILICON VALLEY THEME - - -
"@

$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir  = Split-Path $profilePath

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$existing = ''
if (Test-Path $profilePath) {
    $existing = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
}

# Strip any existing theme block (Silicon Valley, Cobalt, or other MSSP themes)
$existing = $existing -replace '(?s)# - - - MSSP FIELD KIT - .+? THEME - - -.*?# - - - END .+? THEME - - -\s*', ''

try {
    Set-Content -Path $profilePath -Value ($existing + $profileBlock) -Encoding UTF8 -ErrorAction Stop
    Write-Host "  [OK]   Written to profile: $profilePath" -ForegroundColor Cyan
} catch {
    Write-Host "  [XX]   Could not write profile: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ''
Write-Host '. . . . . . . . . . . . . . . . . . . . .'  -ForegroundColor Cyan
Write-Host "  Suck it, Jin Yang. Loads on every new session." -ForegroundColor Cyan
Write-Host "  To revert: remove the SILICON VALLEY THEME block from $profilePath" -ForegroundColor DarkCyan
Write-Host '. . . . . . . . . . . . . . . . . . . . .'  -ForegroundColor Cyan
Write-Host ''
Read-Host '  Press Enter to exit'
