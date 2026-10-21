<#
.VERSION 1.0.1
#>
# OBJECTIVE: Run animated terminal static with a floating label and clock.

$script:DisplayText = '<YOUR TEXT HERE>' # Edit this label.
# static.ps1
# Standalone custom text terminal screensaver. Press Ctrl+C to stop.
$ErrorActionPreference='Stop'
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)
$esc=[char]27; $reset="$esc[0m"; $hide="$esc[?25l"; $show="$esc[?25h"; $clear="$esc[2J"; $cursorHome="$esc[H"
$altOn="$esc[?1049h"; $altOff="$esc[?1049l"; $eraseScrollback=""; $wrapOff="$esc[?7l"; $wrapOn="$esc[?7h"
$blackCell="$esc[38;2;0;0;0;48;2;0;0;0m"
$colors=@{
Hot='38;2;255;0;195';Pink='38;2;255;84;255';Cyan='38;2;0;255;255';Blue='38;2;58;150;255';Green='38;2;46;228;110';
White='38;2;255;255;255';Bone='38;2;255;255;247';Dim='38;2;107;114;136';Ghost='38;2;31;42;49';
DarkMag='38;2;88;16;88';DarkCyn='38;2;13;81;107';DarkGrn='38;2;10;75;39';Red='38;2;234;26;46'}
function A{param([string]$Code) return ($script:esc+'['+$Code+';48;2;0;0;0m')}
function MoveTo{param([int]$Row,[int]$Col) $r=[Math]::Max(1,$Row+1);$c=[Math]::Max(1,$Col+1);return ($script:esc+'['+$r+';'+$c+'H')}
function PickFrom{param([object[]]$Items) return $Items[(Get-Random -Minimum 0 -Maximum $Items.Count)]}
function Get-ClockText{return (Get-Date).ToString('HH:mm')}
function WriteAt{param([System.Text.StringBuilder]$Sb,[int]$Row,[int]$Col,[string]$Text,[string]$ColorCode)
 if($Row -lt 0 -or $Col -lt 0){return};[void]$Sb.Append((MoveTo -Row $Row -Col $Col));[void]$Sb.Append((A -Code $ColorCode));[void]$Sb.Append($Text);[void]$Sb.Append($script:reset)}
function Paint-FullBlack{param([System.Text.StringBuilder]$Sb,[int]$Width,[int]$Height)
 $blank=' '*[Math]::Max(1,$Width);for($r=0;$r -lt $Height;$r++){[void]$Sb.Append((MoveTo -Row $r -Col 0));[void]$Sb.Append($script:blackCell);[void]$Sb.Append($blank);[void]$Sb.Append($script:reset)}}
function Paint-BlackBox{param([System.Text.StringBuilder]$Sb,[int]$Row,[int]$Col,[int]$BoxWidth,[int]$BoxHeight)
 $blank=' '*[Math]::Max(1,$BoxWidth);for($r=0;$r -lt $BoxHeight;$r++){[void]$Sb.Append((MoveTo -Row ($Row+$r) -Col $Col));[void]$Sb.Append($script:blackCell);[void]$Sb.Append($blank);[void]$Sb.Append($script:reset)}}
function HidePromptMask{param([System.Text.StringBuilder]$Sb) $maskCols=96;$maskRows=7;$maskCol=[Math]::Max(0,[Console]::WindowWidth-$maskCols);Paint-BlackBox -Sb $Sb -Row 0 -Col $maskCol -BoxWidth $maskCols -BoxHeight $maskRows}
function Test-RareDrop{param([int]$Frame,[int]$Offset,[int]$Period=1200,[int]$Length=4)
 $block=[int](($Frame+$Offset)/$Period);$inside=($Frame+$Offset)%$Period;$start=[Math]::Abs((($block*73)+($Offset*19)+41)%($Period-24))+8;return ($inside -ge $start -and $inside -lt ($start+$Length))}
function Get-FloatPosition{param([int]$Frame,[int]$Width,[int]$Height,[string]$Text,[int]$Offset=0)
 $phase=[int](($Frame+$Offset)/1000);$rows=@([int]($Height*.10),[int]($Height*.25),[int]($Height*.43),[int]($Height*.60),[int]($Height*.76),[int]($Height*.86))
 $cols=@([int]($Width*.08),[int]($Width*.62),[int]($Width*.24),[int]($Width*.72),[int]($Width*.13),[int]($Width*.48))
 $idx=$phase%$rows.Count;$row=[Math]::Max(1,[Math]::Min($Height-2,$rows[$idx]));$col=[Math]::Max(2,[Math]::Min($Width-$Text.Length-3,$cols[$idx]));return @{Row=$row;Col=$col}}
function Write-DisplayText{param([System.Text.StringBuilder]$Sb,[int]$Frame,[int]$Width,[int]$Height,[int]$Offset=0)
 $text=$script:DisplayText;if(([int](($Frame+$Offset)/620)%19)-eq0){$text=$script:DisplayText};if(Test-RareDrop -Frame $Frame -Offset $Offset -Period 1450 -Length 3){return}
 $p=Get-FloatPosition -Frame $Frame -Width $Width -Height $Height -Text $text -Offset $Offset;$pal=@($colors.Cyan,$colors.Hot,$colors.Pink,$colors.Bone,$colors.Dim,$colors.DarkCyn,$colors.Red)
 $c=$pal[([int](($Frame+$Offset)/420)%$pal.Count)];WriteAt -Sb $Sb -Row $p.Row -Col $p.Col -Text $text -ColorCode $c
 if(Test-RareDrop -Frame $Frame -Offset ($Offset+117) -Period 1900 -Length 2){WriteAt -Sb $Sb -Row ($p.Row+1) -Col ($p.Col+1) -Text $text -ColorCode $colors.Ghost}}
function Write-Clock{param([System.Text.StringBuilder]$Sb,[int]$Frame,[int]$Width,[int]$Height,[int]$Offset=0)
 $clock=Get-ClockText;if(Test-RareDrop -Frame $Frame -Offset ($Offset+99) -Period 1700 -Length 3){return}
 $phase=[int](($Frame+$Offset)/860);$rows=@([int]($Height*.14),[int]($Height*.32),[int]($Height*.58),[int]($Height*.82));$cols=@([int]($Width*.78),[int]($Width*.18),[int]($Width*.63),[int]($Width*.36))
 $i=$phase%$rows.Count;$row=[Math]::Max(1,[Math]::Min($Height-2,$rows[$i]));$col=[Math]::Max(2,[Math]::Min($Width-$clock.Length-3,$cols[$i]));$pal=@($colors.Cyan,$colors.Bone,$colors.Dim,$colors.DarkCyn,$colors.Hot,$colors.Red);WriteAt -Sb $Sb -Row $row -Col $col -Text $clock -ColorCode $pal[$phase%$pal.Count]}
function New-Code{param([int]$Min=5,[int]$Max=18) $digits='0123456789';$s='';for($i=0;$i -lt (Get-Random -Minimum $Min -Maximum $Max);$i++){if((Get-Random -Minimum 0 -Maximum 100)-lt68){$s+=$digits[(Get-Random -Minimum 0 -Maximum $digits.Length)]}else{$s+=(PickFrom @('-','/',' ',':','.'))}};return $s}
function Write-CleanDust{param([System.Text.StringBuilder]$Sb,[int]$Width,[int]$Height,[int]$Count=6)
 $chars=@('.','·',':',"'",' ');for($i=0;$i -lt $Count;$i++){WriteAt -Sb $Sb -Row (Get-Random -Minimum 1 -Maximum ($Height-2)) -Col (Get-Random -Minimum 1 -Maximum ($Width-2)) -Text (PickFrom $chars) -ColorCode (PickFrom @($colors.Ghost,$colors.Dim,$colors.DarkCyn,$colors.DarkMag))}}
function Write-CleanTear{param([System.Text.StringBuilder]$Sb,[int]$Width,[int]$Height,[int]$MinWidth=10,[int]$MaxPct=60)
 $row=Get-Random -Minimum 2 -Maximum ($Height-3);$len=Get-Random -Minimum $MinWidth -Maximum ([Math]::Max($MinWidth+1,[int]($Width*($MaxPct/100.0))));$col=Get-Random -Minimum 0 -Maximum ([Math]::Max(1,$Width-$len))
 $line='';for($i=0;$i -lt $len;$i++){$line+=(PickFrom @('_','-','─','━','~',' '))};WriteAt -Sb $Sb -Row $row -Col $col -Text $line -ColorCode (PickFrom @($colors.DarkCyn,$colors.DarkMag,$colors.Dim,$colors.Cyan,$colors.Hot))}
function Draw-Line{param([System.Text.StringBuilder]$Sb,[int]$X0,[int]$Y0,[int]$X1,[int]$Y1,[string]$Color,[string]$Ch='·')
 $dx=[Math]::Abs($X1-$X0);$dy=[Math]::Abs($Y1-$Y0);$sx=if($X0 -lt $X1){1}else{-1};$sy=if($Y0 -lt $Y1){1}else{-1};$err=$dx-$dy
 while($true){WriteAt -Sb $Sb -Row $Y0 -Col $X0 -Text $Ch -ColorCode $Color;if($X0 -eq $X1 -and $Y0 -eq $Y1){break};$e2=2*$err;if($e2 -gt (-$dy)){$err-=$dy;$X0+=$sx};if($e2 -lt $dx){$err+=$dx;$Y0+=$sy}}}
function Start-Saver{param([scriptblock]$Draw,[string]$Title='Static',[int]$Delay=190)
 try{$host.UI.RawUI.WindowTitle=$Title}catch{};try{[Console]::CursorVisible=$false}catch{};try{[Console]::BackgroundColor=[ConsoleColor]::Black}catch{};try{[Console]::ForegroundColor=[ConsoleColor]::Black}catch{}
 [Console]::Write($script:wrapOff+$script:altOn+$script:hide+$script:clear+$script:eraseScrollback+$script:cursorHome);$paint=[System.Text.StringBuilder]::new();Paint-FullBlack -Sb $paint -Width ([Console]::WindowWidth) -Height ([Console]::WindowHeight);[Console]::Write($paint.ToString()+$script:cursorHome)
 $frame=0;try{while($true){$width=[Math]::Max(60,[Console]::WindowWidth-1);$height=[Math]::Max(22,[Console]::WindowHeight);& $Draw $frame $width $height;$frame++;Start-Sleep -Milliseconds $Delay}}finally{[Console]::Write($script:reset+$script:wrapOn+$script:show+$script:altOff);try{[Console]::CursorVisible=$true}catch{}}}


# STATIC — slow pulse, empty space.
$Draw={
 param([int]$Frame,[int]$Width,[int]$Height)
 $sb=[System.Text.StringBuilder]::new();[void]$sb.Append($cursorHome);Paint-FullBlack -Sb $sb -Width $Width -Height $Height
 $centerRow=[int]($Height/2);$centerCol=[int]($Width/2);$pulse=[Math]::Abs([Math]::Sin($Frame/160.0));$ringW=[int](($Width*.06)+($pulse*$Width*.20));$ringH=[int](($Height*.03)+($pulse*$Height*.10))
 for($a=0;$a -lt 360;$a+=18){$rad=$a*[Math]::PI/180;$x=[int]($centerCol+[Math]::Cos($rad)*$ringW);$y=[int]($centerRow+[Math]::Sin($rad)*$ringH);if($x -gt 0 -and $x -lt $Width -and $y -gt 0 -and $y -lt $Height){WriteAt -Sb $sb -Row $y -Col $x -Text (PickFrom @('·','.',' ')) -ColorCode (PickFrom @($colors.DarkCyn,$colors.DarkMag,$colors.Ghost,$colors.Dim))}}
 Write-CleanDust -Sb $sb -Width $Width -Height $Height -Count 6
 if((Get-Random -Minimum 0 -Maximum 100)-lt12){$txt=PickFrom @('BLACKOUT','STATIC HOLD','FIELD KIT','NO PICTURE','SIGNAL BELOW');WriteAt -Sb $sb -Row (Get-Random -Minimum 2 -Maximum ($Height-3)) -Col (Get-Random -Minimum 2 -Maximum ([Math]::Max(3,$Width-$txt.Length-3))) -Text $txt -ColorCode (PickFrom @($colors.Cyan,$colors.Hot,$colors.Bone,$colors.Red))}
 Write-DisplayText -Sb $sb -Frame $Frame -Width $Width -Height $Height -Offset 0;Write-Clock -Sb $sb -Frame $Frame -Width $Width -Height $Height -Offset 700;HidePromptMask -Sb $sb;[Console]::Write($sb.ToString())
}
Start-Saver -Draw $Draw -Title 'Static' -Delay 175
