$script:DisplayText = '<YOUR TEXT HERE>' # Edit this label.
# rain.ps1
# PowerShell 7.6.6 / Windows Terminal
# Best overall blend:
# - strong custom text / FIELD // KIT branding
# - 24h clock
# - fast rain density
# - broken-signal random phrases
# - stable window-safe behavior

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

# --- TUNING ------------------------------------------------------------------
$FrameDelayMs       = 58
$DropDensity        = 70
$SpawnChance        = 7
$BackgroundNoise    = 5
$ScanlineChance     = 10
$SignatureChance    = 92
$IntroFrames        = 75

# --- ANSI --------------------------------------------------------------------
$esc   = [char]27
$reset = "$esc[0m"
$hide  = "$esc[?25l"
$show  = "$esc[?25h"
$clear = "$esc[2J"
$cursorHome  = "$esc[H"
$altOn = "$esc[?1049h"
$altOff = "$esc[?1049l"
$eraseScrollback = ""

$colors = @{
    Hot     = '38;2;255;0;214'
    Pink    = '38;2;255;84;255'
    Cyan    = '38;2;0;255;255'
    Blue    = '38;2;58;150;255'
    Green   = '38;2;46;228;110'
    Lime    = '38;2;136;255;143'
    White   = '38;2;255;255;255'
    Bone    = '38;2;255;255;247'
    Dim     = '38;2;107;114;136'
    Ghost   = '38;2;31;42;49'
    DarkMag = '38;2;88;16;88'
    DarkCyn = '38;2;13;81;107'
    DarkGrn = '38;2;10;75;39'
}

$glyphs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#$%&@<>/\+-=*[]{}░▒▓'.ToCharArray()
$staticGlyphs = '.·:¦|_-=░▒'.ToCharArray()
$scanChars = @('─','━','═','▔','▁','░','▒',' ')
$phraseBank = @(
    'SIGNAL LOSS',
    'DRIFT FEED',
    'FIELD KIT',
    'MIDNIGHT OPS',
    'RETRO WIRE',
    'DREAM RAIN',
    'BRIGHT NOISE',
    'CIRCUIT FEED',
    'LOW SIGNAL',
    'NEON HUSH',
    'DARK CHANNEL',
    'RADIANT NOISE'
)

function A {
    param([string]$Code)
    return ($esc + '[' + $Code + 'm')
}

function MoveTo {
    param([int]$Row,[int]$Col)
    return ($esc + '[' + $Row + ';' + $Col + 'H')
}

function PickGlyph {
    return $glyphs[(Get-Random -Minimum 0 -Maximum $glyphs.Count)]
}

function PickStatic {
    return $staticGlyphs[(Get-Random -Minimum 0 -Maximum $staticGlyphs.Count)]
}

function PickFrom {
    param([array]$Items)
    return $Items[(Get-Random -Minimum 0 -Maximum $Items.Count)]
}

function CenterX {
    param([string]$Text,[int]$Width)
    return [Math]::Max(1, [int](($Width - $Text.Length) / 2))
}

function Get-ClockText {
    return (Get-Date).ToString('HH:mm')
}

function WriteAt {
    param(
        [System.Text.StringBuilder]$Sb,
        [int]$Row,
        [int]$Col,
        [string]$Text,
        [string]$ColorCode
    )

    [void]$Sb.Append((MoveTo -Row $Row -Col $Col))
    [void]$Sb.Append((A $ColorCode))
    [void]$Sb.Append($Text)
    [void]$Sb.Append($reset)
}

function New-Trail {
    param([int]$Length)

    $trail = New-Object 'char[]' $Length

    for ($i = 0; $i -lt $Length; $i++) {
        $trail[$i] = PickGlyph
    }

    return $trail
}

function New-Drop {
    param([int]$X,[int]$Height)

    $len = Get-Random -Minimum 12 -Maximum ([Math]::Max(14,[Math]::Min(36,$Height)))
    $step = Get-Random -Minimum 1 -Maximum 5

    [pscustomobject]@{
        X         = $X
        Head      = Get-Random -Minimum (-$Height) -Maximum $Height
        Len       = $len
        Style     = @('cyan','cyan','pink','mixed','green')[(Get-Random -Minimum 0 -Maximum 5)]
        Active    = ((Get-Random -Minimum 0 -Maximum 100) -lt $DropDensity)
        Tick      = Get-Random -Minimum 0 -Maximum $step
        StepEvery = $step
        Cool      = Get-Random -Minimum 10 -Maximum 75
        Trail     = New-Trail -Length $len
    }
}

function Reset-Drop {
    param($Drop,[int]$Height)

    $len = Get-Random -Minimum 12 -Maximum ([Math]::Max(14,[Math]::Min(36,$Height)))
    $step = Get-Random -Minimum 1 -Maximum 5

    $Drop.Head      = Get-Random -Minimum (-$Height) -Maximum 0
    $Drop.Len       = $len
    $Drop.Style     = @('cyan','cyan','pink','mixed','green')[(Get-Random -Minimum 0 -Maximum 5)]
    $Drop.Active    = $true
    $Drop.Tick      = Get-Random -Minimum 0 -Maximum $step
    $Drop.StepEvery = $step
    $Drop.Cool      = Get-Random -Minimum 10 -Maximum 75
    $Drop.Trail     = New-Trail -Length $len
}

function New-Drops {
    param([int]$Width,[int]$Height)

    $drops = @()
    for ($x = 0; $x -lt $Width; $x++) {
        if ((Get-Random -Minimum 0 -Maximum 100) -lt $DropDensity) {
            $drops += (New-Drop -X $x -Height $Height)
        }
    }
    return $drops
}

function Get-DropColor {
    param([string]$Style,[int]$Dist)

    if ($Dist -eq 0) { return $colors.White }

    switch ($Style) {
        'pink' {
            if ($Dist -lt 3) { return $colors.Pink }
            if ($Dist -lt 9) { return $colors.Hot }
            return $colors.DarkMag
        }
        'cyan' {
            if ($Dist -lt 3) { return $colors.Cyan }
            if ($Dist -lt 9) { return $colors.Blue }
            return $colors.DarkCyn
        }
        'mixed' {
            if ($Dist -lt 3) { return @($colors.Pink,$colors.Cyan,$colors.Bone,$colors.Hot)[(Get-Random -Minimum 0 -Maximum 4)] }
            if ($Dist -lt 9) { return @($colors.Hot,$colors.Blue,$colors.Cyan,$colors.Green)[(Get-Random -Minimum 0 -Maximum 4)] }
            return @($colors.DarkMag,$colors.DarkCyn,$colors.DarkGrn)[(Get-Random -Minimum 0 -Maximum 3)]
        }
        default {
            if ($Dist -lt 3) { return $colors.Green }
            if ($Dist -lt 9) { return $colors.DarkGrn }
            return '38;2;8;47;23'
        }
    }
}

function Advance-Drops {
    param([array]$Drops,[int]$Height)

    foreach ($d in $Drops) {
        if (-not $d.Active) {
            if ($d.Cool -gt 0) {
                $d.Cool--
            }
            elseif ((Get-Random -Minimum 0 -Maximum 100) -lt $SpawnChance) {
                Reset-Drop -Drop $d -Height $Height
            }
            continue
        }

        $d.Tick++

        if (($d.Tick % $d.StepEvery) -eq 0) {
            $d.Head += 1

            if ((Get-Random -Minimum 0 -Maximum 100) -lt 22) {
                $idx = Get-Random -Minimum 0 -Maximum $d.Trail.Count
                $d.Trail[$idx] = PickGlyph
            }

            if ((Get-Random -Minimum 0 -Maximum 100) -lt 42) {
                $d.Trail[0] = PickGlyph
            }
        }

        if (($d.Head - $d.Len) -gt $Height) {
            $d.Active = $false
            $d.Cool = Get-Random -Minimum 18 -Maximum 100
            $d.Head = Get-Random -Minimum (-$Height) -Maximum 0
        }
    }
}

function Draw-Frame {
    param(
        [array]$Drops,
        [int]$Frame,
        [int]$Width,
        [int]$Height
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append($cursorHome)

    $dropByX = New-Object 'object[]' $Width
    foreach ($d in $Drops) {
        if ($d.Active -and $d.X -ge 0 -and $d.X -lt $Width) {
            $dropByX[$d.X] = $d
        }
    }

    for ($y = 0; $y -lt $Height; $y++) {
        for ($x = 0; $x -lt $Width; $x++) {
            $printed = $false
            $d = $dropByX[$x]

            if ($null -ne $d) {
                $dist = $d.Head - $y

                if ($dist -ge 0 -and $dist -lt $d.Len) {
                    $glyph = if ($dist -lt $d.Trail.Count) { $d.Trail[$dist] } else { PickGlyph }

                    [void]$sb.Append((A (Get-DropColor -Style $d.Style -Dist $dist)))
                    [void]$sb.Append($glyph)
                    [void]$sb.Append($reset)
                    $printed = $true
                }
            }

            if (-not $printed) {
                if ((Get-Random -Minimum 0 -Maximum 1000) -lt $BackgroundNoise) {
                    [void]$sb.Append((A (PickFrom @($colors.Ghost,$colors.Dim,$colors.DarkCyn,$colors.DarkMag,$colors.DarkGrn))))
                    [void]$sb.Append((PickStatic))
                    [void]$sb.Append($reset)
                }
                else {
                    [void]$sb.Append(' ')
                }
            }
        }

        if ($y -lt ($Height - 1)) {
            [void]$sb.Append("`n")
        }
    }

    if ($Frame -lt $IntroFrames) {
        $phase = [int]($Frame / 18)
        $pulse = @($colors.Hot,$colors.Cyan,$colors.Bone,$colors.DarkCyn)[$phase % 4]
        $mid = [int]($Height / 2) - 1

        $line1 = $script:DisplayText
        $line2 = 'F I E L D // K I T'
        $line3 = 'rain signal / retro terminal'
        $clock = Get-ClockText

        if (($Frame % 22) -notin @(0,1,2)) {
            WriteAt -Sb $sb -Row $mid -Col (CenterX $line1 $Width) -Text $line1 -ColorCode $pulse
        }

        if (($Frame % 28) -notin @(0,1,2,3,4)) {
            WriteAt -Sb $sb -Row ($mid + 2) -Col (CenterX $line2 $Width) -Text $line2 -ColorCode $colors.Cyan
        }

        if (($Frame % 32) -notin @(0,1,2,3,4,5)) {
            WriteAt -Sb $sb -Row ($mid + 4) -Col (CenterX $line3 $Width) -Text $line3 -ColorCode $colors.Dim
        }

        if (($Frame % 30) -notin @(0,1,2,3,4)) {
            WriteAt -Sb $sb -Row ($mid + 6) -Col (CenterX $clock $Width) -Text $clock -ColorCode @($colors.Cyan,$colors.Bone,$colors.Dim,$colors.DarkCyn)[$phase % 4]
        }
    }
    else {
        if ((Get-Random -Minimum 0 -Maximum 100) -lt $SignatureChance) {
            $phase = [int]($Frame / 20)

            $sig = $script:DisplayText
            if (($phase % 11) -eq 0) {
                $sig = $script:DisplayText
            }

            $tag = 'F I E L D // K I T'
            $clock = Get-ClockText

            $rowJitter = @(-1,0,0,0,1)[$phase % 5]
            $colJitter = @(0,0,1,-1,0)[$phase % 5]

            $row = [Math]::Max(2, $Height - 5 + $rowJitter)
            $col = [Math]::Max(2, [int]($Width * 0.08) + $colJitter)

            $logoPalette = @($colors.Cyan,$colors.Hot,$colors.Pink,$colors.Bone,$colors.Dim,$colors.DarkCyn,$colors.DarkMag)
            $c = $logoPalette[$phase % $logoPalette.Count]

            if (($Frame % 34) -notin @(0,1,2,3)) {
                WriteAt -Sb $sb -Row $row -Col $col -Text $sig -ColorCode $c
            }

            if (($Frame % 42) -notin @(0,1,2,3,4,5)) {
                $tagCol = $col + 2
                if ($tagCol + $tag.Length -lt $Width) {
                    WriteAt -Sb $sb -Row ($row + 2) -Col $tagCol -Text $tag -ColorCode @($colors.Cyan,$colors.Lime,$colors.Bone,$colors.Hot)[$phase % 4]
                }
            }

            if (($Frame % 48) -notin @(0,1,2,3,4,5,6)) {
                $clockCol = $col + $sig.Length + 5
                if ($clockCol -lt ($Width - $clock.Length - 2)) {
                    $clockPalette = @($colors.Cyan,$colors.Bone,$colors.Dim,$colors.DarkCyn,$colors.DarkMag)
                    WriteAt -Sb $sb -Row $row -Col $clockCol -Text $clock -ColorCode $clockPalette[$phase % $clockPalette.Count]
                }
            }
        }

        if ((Get-Random -Minimum 0 -Maximum 100) -lt 12) {
            $g = ' // ' + (PickFrom $phraseBank) + ' // '
            $row = Get-Random -Minimum 2 -Maximum ([Math]::Max(3,$Height - 2))
            $col = Get-Random -Minimum 1 -Maximum ([Math]::Max(2,$Width - $g.Length))
            WriteAt -Sb $sb -Row $row -Col $col -Text $g -ColorCode @($colors.Hot,$colors.Cyan,$colors.Lime)[(Get-Random -Minimum 0 -Maximum 3)]
        }

        if ((Get-Random -Minimum 0 -Maximum 100) -lt $ScanlineChance) {
            $scanY = Get-Random -Minimum 2 -Maximum ([Math]::Max(3,$Height - 2))
            $start = Get-Random -Minimum 0 -Maximum ([Math]::Max(1,[int]($Width * 0.45)))
            $len = Get-Random -Minimum ([Math]::Max(8,[int]($Width * 0.10))) -Maximum ([Math]::Max(9,[int]($Width * 0.54)))
            $scan = ''

            for ($i = 0; $i -lt $len; $i++) {
                $scan += (PickFrom $scanChars)
            }

            $c = PickFrom @($colors.DarkMag,$colors.DarkCyn,$colors.Dim,$colors.Cyan,$colors.Hot)
            WriteAt -Sb $sb -Row $scanY -Col $start -Text $scan -ColorCode $c
        }
    }

    [Console]::Write($sb.ToString())
}

try {
    $host.UI.RawUI.WindowTitle = 'Rain'
    try { [Console]::CursorVisible = $false } catch {}

    # Alt-screen buffer hides the prompt while the script runs
    [Console]::Write($altOn + $hide + $clear + $eraseScrollback + $cursorHome)

    $width = [Math]::Max(60, [Console]::WindowWidth)
    $height = [Math]::Max(22, [Console]::WindowHeight)
    $drops = New-Drops -Width $width -Height $height
    $frame = 0

    while ($true) {
        $newWidth = [Math]::Max(60, [Console]::WindowWidth)
        $newHeight = [Math]::Max(22, [Console]::WindowHeight)

        if ($newWidth -ne $width -or $newHeight -ne $height) {
            $width = $newWidth
            $height = $newHeight
            $drops = New-Drops -Width $width -Height $height
            [Console]::Write($clear + $eraseScrollback + $cursorHome)
        }

        Advance-Drops -Drops $drops -Height $height
        Draw-Frame -Drops $drops -Frame $frame -Width $width -Height $height

        $frame++
        Start-Sleep -Milliseconds $FrameDelayMs
    }
}
finally {
    # Best effort restore
    [Console]::Write($clear + $cursorHome + $reset + $show + $altOff)
    try { [Console]::CursorVisible = $true } catch {}
}
