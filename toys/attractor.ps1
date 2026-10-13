$script:DisplayText = '<YOUR TEXT HERE>' # Edit this label.
# Standalone terminal fractal screensaver with floating/flickering custom text logo + clock. Ctrl+C exits.
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$esc=[char]27; $reset="$esc[0m"; $hide="$esc[?25l"; $show="$esc[?25h"; $clear="$esc[2J"; $homeCursor="$esc[H"; $altOn="$esc[?1049h"; $altOff="$esc[?1049l"; $erase=""; $wrapOff="$esc[?7l"; $wrapOn="$esc[?7h"; $black="$esc[38;2;0;0;0;48;2;0;0;0m"
$colors=@{Hot='38;2;255;0;195';Cyan='38;2;0;255;255';White='38;2;255;255;255';Bone='38;2;255;255;247';Dim='38;2;107;114;136';Ghost='38;2;31;42;49';DarkMag='38;2;88;16;88';DarkCyn='38;2;13;81;107';Green='38;2;46;228;110';DarkGrn='38;2;10;75;39';Red='38;2;234;26;46';Black='38;2;0;0;0'}
function A([string]$c){ "$script:esc[$c;48;2;0;0;0m" }
function M([int]$r,[int]$c){ "$script:esc[$([Math]::Max(1,$r+1));$([Math]::Max(1,$c+1))H" }
function Pick([object[]]$a){ $a[(Get-Random -Minimum 0 -Maximum $a.Count)] }
function Put($sb,[int]$r,[int]$c,[string]$t,[string]$col){ if($r -lt 0 -or $c -lt 0){return}; [void]$sb.Append((M $r $c)); [void]$sb.Append((A $col)); [void]$sb.Append($t); [void]$sb.Append($script:reset) }
function FullBlack($sb,[int]$w,[int]$h){ $blank=' '*[Math]::Max(1,$w); for($r=0;$r -lt $h;$r++){ [void]$sb.Append((M $r 0)); [void]$sb.Append($script:black); [void]$sb.Append($blank); [void]$sb.Append($script:reset) } }
function MaskPrompt($sb){ $w=96; $h=7; $c=[Math]::Max(0,[Console]::WindowWidth-$w); $blank=' '*$w; for($r=0;$r -lt $h;$r++){ Put $sb $r $c $blank $colors.Black } }
function Line($sb,[int]$x0,[int]$y0,[int]$x1,[int]$y1,[string]$col,[string]$ch='.'){ $dx=[Math]::Abs($x1-$x0); $dy=[Math]::Abs($y1-$y0); $sx=if($x0 -lt $x1){1}else{-1}; $sy=if($y0 -lt $y1){1}else{-1}; $err=$dx-$dy; while($true){ Put $sb $y0 $x0 $ch $col; if($x0 -eq $x1 -and $y0 -eq $y1){break}; $e2=2*$err; if($e2 -gt (-$dy)){ $err-=$dy; $x0+=$sx }; if($e2 -lt $dx){ $err+=$dx; $y0+=$sy } } }
function Ellipse($sb,[int]$cx,[int]$cy,[int]$rx,[int]$ry,[string]$col,[object[]]$chars=@('.', '·')){ for($a=0;$a -lt 360;$a+=7){ $rad=$a*[Math]::PI/180; $x=[int]($cx+[Math]::Cos($rad)*$rx); $y=[int]($cy+[Math]::Sin($rad)*$ry); if($x -gt 0 -and $x -lt ([Console]::WindowWidth-1) -and $y -gt 0 -and $y -lt ([Console]::WindowHeight-1)){ Put $sb $y $x (Pick $chars) $col } } }
# ---------- FLOATING BRAND / CLOCK ----------
# Independent slow drift, target changes, burst flicker, and ghost echoes.

$script:BrandFloat = @{
    Text=$script:DisplayText
    X=8.0
    Y=4.0
    TargetX=8.0
    TargetY=4.0
    Hold=0
    Flicker=0
    Visible=$true
    Speed=0.032
    LastW=0
    LastH=0
    DrawJitterX=0
    DrawJitterY=0
}

$script:ClockFloat = @{
    Text='00:00'
    X=64.0
    Y=4.0
    TargetX=64.0
    TargetY=4.0
    Hold=0
    Flicker=0
    Visible=$true
    Speed=0.050
    LastW=0
    LastH=0
    DrawJitterX=0
    DrawJitterY=0
}

function ClampInt([int]$v,[int]$lo,[int]$hi){
    if($v -lt $lo){ return $lo }
    if($v -gt $hi){ return $hi }
    return $v
}

function New-FloatTarget([string]$kind,[int]$w,[int]$h,[int]$textLen){
    if($kind -eq 'clock'){
        $zones=@(
            @{X=.78;Y=.13}, @{X=.18;Y=.16}, @{X=.65;Y=.29}, @{X=.34;Y=.82},
            @{X=.82;Y=.56}, @{X=.12;Y=.67}, @{X=.48;Y=.10}
        )
    }
    else{
        $zones=@(
            @{X=.08;Y=.12}, @{X=.58;Y=.72}, @{X=.22;Y=.27}, @{X=.44;Y=.82},
            @{X=.62;Y=.18}, @{X=.12;Y=.58}, @{X=.70;Y=.44}
        )
    }

    $z=$zones[(Get-Random -Minimum 0 -Maximum $zones.Count)]
    $x=[int]($w * [double]$z.X)
    $y=[int]($h * [double]$z.Y)

    $x += Get-Random -Minimum -7 -Maximum 8
    $y += Get-Random -Minimum -3 -Maximum 4

    $maxX=[Math]::Max(2,$w-$textLen-3)
    $maxY=[Math]::Max(2,$h-3)

    return @{
        X=(ClampInt $x 2 $maxX)
        Y=(ClampInt $y 2 $maxY)
    }
}

function Update-FloatingLabel($state,[string]$kind,[int]$w,[int]$h,[int]$f){
    if($kind -eq 'clock'){
        $state.Text=(Get-Date).ToString('HH:mm')
        $minHold=45
        $maxHold=140
        $resetChance=5
        $state.Speed=0.050
        $flickerChance=24
    }
    else{
        $minHold=90
        $maxHold=260
        $resetChance=3
        $state.Speed=0.034
        $flickerChance=18
    }

    $resize = ([int]$state.LastW -ne $w -or [int]$state.LastH -ne $h)

    if($resize -or [int]$state.Hold -le 0 -or (Get-Random -Minimum 0 -Maximum 1000) -lt $resetChance){
        $t=New-FloatTarget $kind $w $h ([string]$state.Text).Length
        $state.TargetX=[double]$t.X
        $state.TargetY=[double]$t.Y
        $state.Hold=Get-Random -Minimum $minHold -Maximum $maxHold
        $state.LastW=$w
        $state.LastH=$h
    }
    else{
        $state.Hold=[int]$state.Hold-1
    }

    $state.X=[double]$state.X + (([double]$state.TargetX - [double]$state.X) * [double]$state.Speed)
    $state.Y=[double]$state.Y + (([double]$state.TargetY - [double]$state.Y) * [double]$state.Speed)

    $state.DrawJitterX=0
    $state.DrawJitterY=0
    if((Get-Random -Minimum 0 -Maximum 100) -lt 8){
        $state.DrawJitterX=Get-Random -Minimum -1 -Maximum 2
        $state.DrawJitterY=Get-Random -Minimum -1 -Maximum 2
    }

    if([int]$state.Flicker -gt 0){
        $state.Flicker=[int]$state.Flicker-1
        $state.Visible=((Get-Random -Minimum 0 -Maximum 100) -gt 28)
    }
    else{
        $state.Visible=$true
        if((Get-Random -Minimum 0 -Maximum 1000) -lt $flickerChance){
            $state.Flicker=Get-Random -Minimum 2 -Maximum 9
        }
    }

    $maxX=[Math]::Max(2,$w-([string]$state.Text).Length-3)
    $maxY=[Math]::Max(2,$h-3)
    $state.X=[double](ClampInt ([int][Math]::Round([double]$state.X)) 2 $maxX)
    $state.Y=[double](ClampInt ([int][Math]::Round([double]$state.Y)) 2 $maxY)
}

function Draw-FloatingLabel($sb,$state,[string]$kind,[int]$f){
    if(-not [bool]$state.Visible){ return }

    $txt=[string]$state.Text
    $x=[int][Math]::Round([double]$state.X)+[int]$state.DrawJitterX
    $y=[int][Math]::Round([double]$state.Y)+[int]$state.DrawJitterY

    if($kind -eq 'clock'){
        $main=@($colors.Cyan,$colors.White,$colors.Bone,$colors.Hot)
        $dim=@($colors.DarkCyn,$colors.Dim,$colors.Ghost)
    }
    else{
        $main=@($colors.DarkCyn,$colors.Dim,$colors.Bone,$colors.Cyan,$colors.Hot)
        $dim=@($colors.Ghost,$colors.DarkCyn,$colors.DarkMag,$colors.Dim)
    }

    # ghost echo first
    if((Get-Random -Minimum 0 -Maximum 100) -lt 14){
        $gx=$x+(Get-Random -Minimum -1 -Maximum 2)
        $gy=$y+(Get-Random -Minimum -1 -Maximum 2)
        Put $sb $gy $gx $txt (Pick $dim)
    }

    for($i=0;$i -lt $txt.Length;$i++){
        if([int]$state.Flicker -gt 0 -and (Get-Random -Minimum 0 -Maximum 100) -lt 22){ continue }

        $col=Pick $main
        if((Get-Random -Minimum 0 -Maximum 100) -lt 26){ $col=Pick $dim }
        if((($f+$i)%97) -eq 0){ $col=$colors.White }

        Put $sb $y ($x+$i) ([string]$txt[$i]) $col
    }
}

function Clock($sb,[int]$f,[int]$w,[int]$h,[int]$o=0){
    Update-FloatingLabel $script:ClockFloat 'clock' $w $h ($f+$o)
    Draw-FloatingLabel $sb $script:ClockFloat 'clock' ($f+$o)
}

function Brand($sb,[int]$f,[int]$w,[int]$h,[int]$o=0){
    Update-FloatingLabel $script:BrandFloat 'brand' $w $h ($f+$o)
    Draw-FloatingLabel $sb $script:BrandFloat 'brand' ($f+$o)
}

function Dust($sb,[int]$w,[int]$h,[int]$n=6){ for($i=0;$i -lt $n;$i++){ Put $sb (Get-Random -Minimum 1 -Maximum ($h-2)) (Get-Random -Minimum 1 -Maximum ($w-2)) (Pick @('.', '·', ':', "'", ' ')) (Pick @($colors.Ghost,$colors.Dim,$colors.DarkCyn,$colors.DarkMag)) } }
function Tear($sb,[int]$w,[int]$h,[int]$min=10,[int]$pct=45){ $row=Get-Random -Minimum 2 -Maximum ($h-3); $len=Get-Random -Minimum $min -Maximum ([Math]::Max($min+1,[int]($w*($pct/100.0)))); $col=Get-Random -Minimum 0 -Maximum ([Math]::Max(1,$w-$len)); $line=''; for($i=0;$i -lt $len;$i++){ $line += (Pick @('_','-','─','━','~',' ')) }; Put $sb $row $col $line (Pick @($colors.DarkCyn,$colors.DarkMag,$colors.Dim,$colors.Cyan,$colors.Hot)) }
function Start-Fractal($title,$delay,$draw){ try{$host.UI.RawUI.WindowTitle=$title}catch{}; try{[Console]::CursorVisible=$false}catch{}; [Console]::Write($wrapOff+$altOn+$hide+$clear+$erase+$homeCursor); $sb=[System.Text.StringBuilder]::new(); FullBlack $sb ([Console]::WindowWidth) ([Console]::WindowHeight); [Console]::Write($sb.ToString()+$homeCursor); $frame=0; try{ while($true){ $w=[Math]::Max(60,[Console]::WindowWidth-1); $h=[Math]::Max(22,[Console]::WindowHeight); & $draw $frame $w $h; $frame++; Start-Sleep -Milliseconds $delay } } finally { [Console]::Write($reset+$wrapOn+$show+$altOff); try{[Console]::CursorVisible=$true}catch{} } }

# Real Clifford attractor: x1 = sin(a*y)+c*cos(a*x), y1 = sin(b*x)+d*cos(b*y)
Start-Fractal 'Attractor' 85 {
    param($f,$w,$h)
    $sb=[System.Text.StringBuilder]::new(); [void]$sb.Append($homeCursor); FullBlack $sb $w $h
    $t=$f/160.0; $a=-1.4+([Math]::Sin($t*.31)*.16); $b=1.6+([Math]::Cos($t*.27)*.12); $c=1.0+([Math]::Sin($t*.19)*.18); $d=.7+([Math]::Cos($t*.23)*.14)
    $x=.1; $y=.1; $cx=[int]($w/2); $cy=[int]($h/2); $sx=$w*.17; $sy=$h*.16
    for($i=0;$i -lt 1650;$i++){ $nx=[Math]::Sin($a*$y)+($c*[Math]::Cos($a*$x)); $ny=[Math]::Sin($b*$x)+($d*[Math]::Cos($b*$y)); $x=$nx; $y=$ny; if($i -gt 20 -and (($i+$f)%2) -eq 0){ $px=[int]($cx+($x*$sx)); $py=[int]($cy+($y*$sy)); if($px -gt 0 -and $px -lt $w -and $py -gt 0 -and $py -lt $h){ $col=if($i%97 -eq 0){Pick @($colors.White,$colors.Bone,$colors.Hot)}elseif($i%17 -eq 0){Pick @($colors.Cyan,$colors.Hot)}else{Pick @($colors.DarkCyn,$colors.DarkMag,$colors.Dim,$colors.Ghost)}; Put $sb $py $px (Pick @('.', '·', ':')) $col } } }
    if((Get-Random -Minimum 0 -Maximum 100) -lt 8){ Tear $sb $w $h 10 40 }
    if(($f%1200) -in 200..202){ Put $sb ([int]($h*.76)) ([int]($w*.12)) 'STRANGE ATTRACTOR' (Pick @($colors.Cyan,$colors.Hot,$colors.Bone)) }
    MaskPrompt $sb; Brand $sb $f $w $h 320; Clock $sb $f $w $h 0; [Console]::Write($sb.ToString())
}
