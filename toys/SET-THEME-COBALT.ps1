#Requires -Version 5.1

# cobalt-plus-palette.ps1
# MSSP Field Kit -- Cobalt+ color palette reference and live preview.
# Paste the palette block into any kit script.
# Run this file to preview all colors and tags in terminal.

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$Host.UI.RawUI.BackgroundColor = 'Black'
$Host.UI.RawUI.ForegroundColor = 'White'
$Host.UI.RawUI.WindowTitle     = 'MSSP - Cobalt+ Palette Reference'
[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Kit colors -- Cobalt+
$esc = [char]27
$cT1 = "${esc}[96m"                       # bright cyan   -- [OK], headers
$cT2 = "${esc}[38;2;147;197;253m"         # sky blue      -- secondary, sub-items
$cT3 = "${esc}[38;2;30;100;160m"          # cobalt    -- dots, labels
$cWn = "${esc}[38;2;252;211;77m"          # yellow        -- [!!]
$cFl = "${esc}[91m"                       # bright red    -- [XX]
$cWh = "${esc}[97m"                       # bright white  -- body text
$cCo = "${esc}[38;2;192;132;252m"         # purple        -- Write-Coach header/border
$cCd = "${esc}[38;2;221;214;254m"         # light purple  -- Write-Coach body
$cR  = "${esc}[0m"                        # reset

# ---------------------------------------------------------------------------
# PALETTE BLOCK -- copy this into any kit script
# ---------------------------------------------------------------------------
#
# $esc = [char]27
# $cT1 = "${esc}[96m"                       # bright cyan   -- [OK], headers
# $cT2 = "${esc}[38;2;147;197;253m"         # sky blue      -- secondary, sub-items
# $cT3 = "${esc}[38;2;30;100;160m"          # cobalt dim    -- dots, labels
# $cWn = "${esc}[38;2;252;211;77m"          # yellow        -- [!!]
# $cFl = "${esc}[91m"                       # bright red    -- [XX]
# $cWh = "${esc}[97m"                       # bright white  -- body text
# $cCo = "${esc}[38;2;192;132;252m"         # purple        -- Write-Coach header/border
# $cCd = "${esc}[38;2;221;214;254m"         # light purple  -- Write-Coach body
# $cR  = "${esc}[0m"                        # reset
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host "${cT1}COBALT+ PALETTE REFERENCE${cR}"
Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host ""

Write-Host "${cT3}VAR    VALUE                        USE${cR}"
Write-Host "${cT3}----   --------------------------   ---------------------------${cR}"
Write-Host "  ${cT1}`$cT1${cR}   ${cT1}[96m  bright cyan${cR}              ${cT3}[OK], headers${cR}"
Write-Host "  ${cT2}`$cT2${cR}   ${cT2}[38;2;147;197;253m  sky blue${cR}         ${cT3}secondary, sub-items${cR}"
Write-Host "  ${cT3}`$cT3   [38;2;30;100;160m  cobalt dim        dots, labels, [--]${cR}"
Write-Host "  ${cWn}`$cWn${cR}   ${cWn}[38;2;252;211;77m  yellow${cR}           ${cT3}[!!] warnings${cR}"
Write-Host "  ${cFl}`$cFl${cR}   ${cFl}[91m  bright red${cR}               ${cT3}[XX] failures, CRITICAL/HIGH${cR}"
Write-Host "  ${cWh}`$cWh${cR}   ${cWh}[97m  bright white${cR}             ${cT3}body text${cR}"
Write-Host "  ${cCo}`$cCo${cR}   ${cCo}[38;2;192;132;252m  purple${cR}           ${cT3}Write-Coach header/border${cR}"
Write-Host "  ${cCd}`$cCd${cR}   ${cCd}[38;2;221;214;254m  light purple${cR}     ${cT3}Write-Coach body${cR}"
Write-Host "  `$cR    [0m  reset"
Write-Host ""

Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host "${cT1}STANDARD TAGS${cR}"
Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host ""
Write-Host "  ${cT1}[OK]  ${cWh}Operation succeeded / state confirmed${cR}"
Write-Host "  ${cT3}[--]  ${cWh}Informational / neutral status${cR}"
Write-Host "  ${cWn}[!!]  ${cWh}Warning / review recommended${cR}"
Write-Host "  ${cFl}[XX]  ${cWh}Failure / CRITICAL / HIGH risk${cR}"
Write-Host ""

Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host "${cT1}WRITE-FIELD EXAMPLE${cR}"
Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host ""
Write-Host "${cT3}$("{0,-18}" -f "User")      :${cR}  ${cWh}jsmith@contoso.com${cR}"
Write-Host "${cT3}$("{0,-18}" -f "Status")    :${cR}  ${cT1}Active${cR}"
Write-Host "${cT3}$("{0,-18}" -f "Risk")      :${cR}  ${cWn}Review recommended${cR}"
Write-Host "${cT3}$("{0,-18}" -f "Finding")   :${cR}  ${cFl}External forwarding detected${cR}"
Write-Host ""

Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host "${cT1}WRITE-COACH EXAMPLE${cR}"
Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host ""
Write-Host "${cCo}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host "${cCo}  COACHING NOTES${cR}"
Write-Host "${cCo}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host "  ${cCd}OBJECTIVE${cR}"
Write-Host "  ${cCd}  What this script does and what to look for.${cR}"
Write-Host "  ${cCd}ESCALATION TRIGGERS${cR}"
Write-Host "  ${cCd}  Notify Leads/InfoSec if X, Y, Z.${cR}"
Write-Host "  ${cCd}NEXT${cR}"
Write-Host "  ${cCd}  ir\ir-contain.ps1${cR}"
Write-Host "${cCo}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host ""

Write-Host "${cT3}. . . . . . . . . . . . . . . . . . . . .${cR}"
Write-Host "${cT1}MISSION ACCOMPLISHED. Goodbye.${cR}"
Write-Host ""
Read-Host "Press Enter to exit"
